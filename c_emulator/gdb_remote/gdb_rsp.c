#include <assert.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "elf.h"
#include "sail.h"
#include "rts.h"
#include "riscv_platform.h"
#include "riscv_platform_impl.h"
#include "riscv_sail.h"

// to develop and debug the protocol, set the debug flag on gdb:
//
// (gdb) set debug remote 1
// (gdb) target remote localhost:<port>

struct proto_state {
  int send_acks;
};

typedef enum {
  M_RUN_START,
  M_RUN_RUNNING,
  M_RUN_BREAKPOINT,
  M_RUN_HALT
} model_run_state_t;

struct sw_breakpoint {
  int active;     // 0 -> inactive
  int kind;       // either 2 (c.ebreak) or 4 (ebreak)
  uint64_t addr;  // pc
  uint64_t mem_bytes[4]; // saved copy of #type original bytes
};

#define MAX_BREAKPOINTS 64

struct model_state {
  model_run_state_t run_state;
  mach_int step_no;
  struct sw_breakpoint breakpoints[MAX_BREAKPOINTS];
};

struct rsp_conn {
  int listen_fd;
  int conn_fd;
  int log_fd;
  struct proto_state proto;
  struct model_state model;
};

static struct rsp_conn conn;

void static init_gdb_model(struct model_state *model) {
  memset(model, 0, sizeof(*model));
  model->run_state = M_RUN_START;
  model->step_no = 0;
}

int gdb_server_init(int port, int log_fd) {
  int sock = socket(AF_INET, SOCK_STREAM, 0);
  int opt = 1;
  if (sock < 0) {
    dprintf(log_fd, "Unable to open socket for port %d: %s\n", port, strerror(errno));
    return -1;
  }
  if (setsockopt(sock, SOL_SOCKET, (SO_REUSEPORT | SO_REUSEADDR), (char *)&opt, sizeof(opt)) < 0) {
    dprintf(log_fd, "Cannot set reuse option on socket: %s\n", strerror(errno));
    return -1;
  }

  struct sockaddr_in saddr;
  memset(&saddr, 0, sizeof(saddr));
  saddr.sin_family = AF_INET;
  saddr.sin_addr.s_addr = htonl(INADDR_ANY);
  saddr.sin_port = htons(port);
  if (bind(sock, (struct sockaddr*)&saddr, sizeof(saddr)) < 0) {
    dprintf(log_fd, "Unable to bind to port %d: %s\n", port, strerror(errno));
    return -1;
  }
  if (listen(sock, 2) < 0) {
    dprintf(log_fd, "Unable to listen on socket: %s\n", strerror(errno));
    return -1;
  }
  dprintf(log_fd, "listening on port %d\n", port);
  conn.listen_fd = sock;
  conn.log_fd = log_fd;
  conn.proto.send_acks = 1;  // start out sending acks
  init_gdb_model(&conn.model);
  return 0;
}

void conn_exit(struct rsp_conn *conn, int code) {
  close(conn->conn_fd);
  close(conn->listen_fd);
  close(conn->log_fd);
  exit(code);
}

#define BUFSZ 2048
struct rsp_buf {
  char *cmd_buf;
  int bufofs;
  int bufsz;
};

// hex utils

int int_of_hex(char c) {
  if      ('0' <= c && c <= '9') { return c - '0'; }
  else if ('a' <= c && c <= 'f') { return c - 'a' + 10; }
  else if ('A' <= c && c <= 'F') { return c - 'A' + 10; }
  else                           { return 0; }
}

char hex_of_int(unsigned val) {
  assert(val < 16);
  if (val < 10) { return val + '0'; }
  else          { return val - 10 + 'a'; }
}

void push_hex_byte(char *buf, uint8_t byte) {
  buf[0] = hex_of_int(byte >> 4);
  buf[1] = hex_of_int(byte & 0xf);
}

// big-endian hex
static int extract_hex_integer_be(struct rsp_conn *conn, struct rsp_buf *req, int *start_ofs, char terminator, uint64_t *val) {
  *val = 0;
  int i = *start_ofs;
  while (true) {
    if (i >= req->bufsz) return -1;
    if (req->cmd_buf[i] == terminator) break;
    *val <<= 4;
    *val |= int_of_hex(req->cmd_buf[i]) & 0xf;
    i++;
  }
  *start_ofs = i;
  return 0;
}

// little-endian hex
static int extract_hex_integer_le(struct rsp_conn *conn, struct rsp_buf *req, int *start_ofs, char terminator, uint64_t *val) {
  *val = 0;
  int i = *start_ofs;
  int shft = 0;
  while (true) {
    uint8_t byte;
    if (i >= req->bufsz) return -1;
    if (req->cmd_buf[i] == terminator) break;

    byte = int_of_hex(req->cmd_buf[i++]);
    byte <<= 4;

    if (i >= req->bufsz) return -1;
    if (req->cmd_buf[i] == terminator) return -1; // unexpected terminator in middle of byte

    byte |= int_of_hex(req->cmd_buf[i++]) & 0xf;

    *val |= byte << shft;
    shft +=8;
  }
  *start_ofs = i;
  return 0;
}

// breakpoint utils
static int insert_breakpoint(struct rsp_conn *conn, uint64_t addr, uint64_t kind) {
  assert(kind == 2 || kind == 4);
  for (int i = 0; i < MAX_BREAKPOINTS; i++) {
    struct sw_breakpoint *bpt = &conn->model.breakpoints[i];
    if (!bpt->active) {
      bpt->addr = addr;
      bpt->kind = (int)kind;
      bpt->active = 1;
      for (int j = 0; j < kind; j++) {
        bpt->mem_bytes[j] = read_mem(addr + j);
      }
      if (kind == 2) {
        // store C.EBREAK: 0x90.02
        write_mem(addr,   (uint64_t) 0x02);
        write_mem(addr+1, (uint64_t) 0x90);
      } else {
        // store EBREAK: 0x00.10.00.73
        write_mem(addr,   (uint64_t) 0x73);
        write_mem(addr+1, (uint64_t) 0x00);
        write_mem(addr+2, (uint64_t) 0x10);
        write_mem(addr+3, (uint64_t) 0x00);
      }
      bpt->active = 1;
      return 0;
    }
  }
  return -1;
}

static int remove_breakpoint(struct rsp_conn *conn, uint64_t addr, uint64_t kind) {
  for (int i = 0; i < MAX_BREAKPOINTS; i++) {
    struct sw_breakpoint *bpt = &conn->model.breakpoints[i];
    if (!bpt->active || bpt->addr != addr) continue;
    if (bpt->kind != kind) {
      dprintf(conn->log_fd, "mismatched breakpoint kind: have %d, was given %ld!\n",
              bpt->kind, kind);
      return -1;
    }
    for (int j = 0; j < bpt->kind; j++) {
      write_mem(addr + j, bpt->mem_bytes[j]);
    }
    bpt->active = 0;
    return 0;
  }
  return -1;
}

static int match_breakpoint(struct rsp_conn *conn, uint64_t addr) {
  for (int i = 0; i < MAX_BREAKPOINTS; i++) {
    struct sw_breakpoint *bpt = &conn->model.breakpoints[i];
    if (bpt->active && bpt->addr == addr) return 1;
  }
  return 0;
}

// buffer utils

static void grow_rsp_buf(struct rsp_conn *conn, struct rsp_buf *b) {
  if (b->cmd_buf == NULL) {
    if ((b->cmd_buf = (char *)malloc(BUFSZ*sizeof(char) + 1)) == NULL) {
      dprintf(conn->log_fd, "[dbg] unable to init cmd_buf\n");
      conn_exit(conn, 1);
    }
    b->bufofs = 0;
    b->bufsz = BUFSZ;
    return;
  }

  b->cmd_buf = (char *)realloc(b->cmd_buf, 2*b->bufsz + 1);
  if (b->cmd_buf == NULL) {
    dprintf(conn->log_fd, "[dbg] cannot realloc to %d bytes, quitting!\n", 2*b->bufsz + 1);
    conn_exit(conn, 1);
  }
  b->bufsz *= 2;
}

static void append_rsp_buf_bytes(struct rsp_conn *conn, struct rsp_buf *b, const char *msg, int mlen) {
  while (b->bufofs + mlen >= b->bufsz) {
    grow_rsp_buf(conn, b);
  }
  memcpy(b->cmd_buf + b->bufofs, msg, mlen);
  b->bufofs += mlen;
  b->cmd_buf[b->bufofs] = 0;
}

static void append_rsp_buf_msg(struct rsp_conn *conn, struct rsp_buf *b, const char *msg) {
  append_rsp_buf_bytes(conn, b, msg, strlen(msg));
}

static void append_rsp_buf_hex_byte(struct rsp_conn *conn, struct rsp_buf *b, unsigned char byte) {
  while (b->bufofs + 2 >= b->bufsz) {
    grow_rsp_buf(conn, b);
  }
  push_hex_byte(b->cmd_buf + b->bufofs, byte);
  b->bufofs += 2;
}

static struct rsp_buf req  = { NULL, 0, 0 };
static struct rsp_buf resp = { NULL, 0, 0 };

static int expect_interrupt_req = 0;
static int interrupt_reqs = 0; // interrupts are supposed to be queued

static int read_req(struct rsp_conn *conn, struct rsp_buf *req) {
  static char buf[BUFSZ+1];

  int done = 0;
  int saw_start = 0;
  int chksum_bytes = 0;
  int out_ofs = 0;
  int nbytes;

  while (1) {
  do_read:
    nbytes = read(conn->conn_fd, buf, BUFSZ);
    if (nbytes < 0) {
      if (!saw_start && errno == EAGAIN) return 0;
      dprintf(conn->log_fd, "[dbg] Error reading socket: %s\n", strerror(errno));
      conn_exit(conn, 1);
    }
    dprintf(conn->log_fd, "[dbg] <- ");
    for (int i = 0; i < nbytes; i++) {
      dprintf(conn->log_fd, "%c", buf[i]);
    }
    dprintf(conn->log_fd, "\n");

    if (!saw_start && nbytes == 0) return 0;

    int ofs = 0;
    if (!saw_start) {
      /* wait for the '$' */
      while (buf[ofs] != '$') {
        if (expect_interrupt_req && (buf[ofs] == 0x3)) { // 0x3 == ^c
          interrupt_reqs++;
          return 1;
        }
        ofs++;
        if (ofs == nbytes) {
          goto do_read;
        }
      }
      saw_start = 1;
      ofs++;
    }

    /* start copying to cmd-buf until the 3-byte checksum field (including #)*/
    while (chksum_bytes < 3 && ofs < nbytes) {
      if (out_ofs == req->bufsz) grow_rsp_buf(conn, req);
      req->cmd_buf[out_ofs++] = buf[ofs];

      if (buf[ofs] == '#') chksum_bytes = 1; // checksum started
      else if (chksum_bytes > 0) chksum_bytes++;
      ofs++;
    }
    if (chksum_bytes == 3) {
      // todo: checksum check.  is it really needed?
      req->cmd_buf[out_ofs] = 0;
      break;
    }
  }
  return 1;
}

static int match_req_cmd(struct rsp_buf *req, const char *cmd) {
  return !strncmp(req->cmd_buf, cmd, strlen(cmd));
}

static void prepare_resp(struct rsp_conn *conn, struct rsp_buf *r) {
  if (conn->proto.send_acks) {
    append_rsp_buf_msg(conn, r, "+$");
  } else {
    append_rsp_buf_msg(conn, r, "$");
  }
}
static void make_empty_resp(struct rsp_conn *conn, struct rsp_buf *r) {
}
static void make_ok_resp(struct rsp_conn *conn, struct rsp_buf *r) {
  append_rsp_buf_msg(conn, r, "OK");
}
static void make_error_resp(struct rsp_conn *conn, struct rsp_buf *r, unsigned char err) {
  while (r->bufofs + 3 > r->bufsz) {
    grow_rsp_buf(conn, r);
  }
  r->cmd_buf[r->bufofs++] = 'E';
  append_rsp_buf_hex_byte(conn, r, err);
}

static void handle_query(struct rsp_conn *conn, struct rsp_buf *req, struct rsp_buf *resp) {
  if (match_req_cmd(req, "qSupported:")) {
    append_rsp_buf_msg(conn, resp, "multiprocess-;swbreak-;hwbreak-;qRelocInsn-");
    append_rsp_buf_msg(conn, resp, ";fork-events-;vfork-events-;exec-events-");
    append_rsp_buf_msg(conn, resp, ";vContSupported-;QThreadEvents-;no-resumed-");
    append_rsp_buf_msg(conn, resp, ";PacketSize=1024");

    // offer no-ack mode
    append_rsp_buf_msg(conn, resp, ";QStartNoAckMode+");
    return;
  }
  if (match_req_cmd(req, "QStartNoAckMode")) {
    make_ok_resp(conn, resp);
    conn->proto.send_acks = 0;
    return;
  }
  if (match_req_cmd(req, "qOffsets")) {
    append_rsp_buf_msg(conn, resp, "Text=0;Data=0;Bss=0"); // shouldn't this come from the memory map?
    return;
  }
  if (match_req_cmd(req, "qC")) {
    append_rsp_buf_msg(conn, resp, "QC0");
    return;
  }
  if (match_req_cmd(req, "qAttached")) {
    // make sure there is no unexpected pid
    if (match_req_cmd(req, "qAttached") || match_req_cmd(req, "qAttached:1")) {
      append_rsp_buf_msg(conn, resp, "1");
      return;
    } else {
      make_error_resp(conn, resp, 2); // no processes
    }
  }
  if (match_req_cmd(req, "qfThreadInfo")) {
    append_rsp_buf_msg(conn, resp, "m0");  // no threads
    return;
  }
  if (match_req_cmd(req, "qsThreadInfo")) {
    append_rsp_buf_msg(conn, resp, "l");
    return;
  }
  if (match_req_cmd(req, "qSymbol::")) {
    make_ok_resp(conn, resp);
    return;
  }
  make_empty_resp(conn, resp);
}

static void handle_vmsgs(struct rsp_conn *conn, struct rsp_buf *req, struct rsp_buf *resp) {
  // The only one that makes sense to handle is 'vCtrlC', perhaps
  // later.  For now, treat all like we treat 'vMustReplyEmpty'.
  make_empty_resp(conn, resp);
  return;
}

static void handle_set_context(struct rsp_conn *conn, struct rsp_buf *req, struct rsp_buf *resp) {
  if (match_req_cmd(req, "H")) {
    // we do not support thread-specific operations
    if (req->cmd_buf[2] == '0' || (req->cmd_buf[2] == '-' && req->cmd_buf[3] == '1')) {
      make_ok_resp(conn, resp);
      return;
    }
  }
  make_error_resp(conn, resp, 1);
}

static void handle_stop_reply(struct rsp_conn *conn, struct rsp_buf *req, struct rsp_buf *resp) {
  switch (conn->model.run_state) {
  case M_RUN_START:
    {
      /* this is equivalent to the interrupted signal code: SIGINT -> 2 */
      append_rsp_buf_msg(conn, resp, "S");
      append_rsp_buf_hex_byte(conn, resp, 2);
    }
    break;
  case M_RUN_BREAKPOINT:
    {
      /* this is equivalent to the interrupted signal code: SIGTRAP -> 5 */
      append_rsp_buf_msg(conn, resp, "S");
      append_rsp_buf_hex_byte(conn, resp, 5);
    }
    break;
  default:
    dprintf(conn->log_fd, "Unhandled stop reply for state %d\n", conn->model.run_state);
    conn_exit(conn, 1);
    break;
  }
}

static void send_reg_val(struct rsp_conn *conn, struct rsp_buf *r, mach_bits reg) {
  int nbytes = (zxlen_val == 32) ? 4 : 8;  // only RV32 or RV64 for now
  for (int i = 0; i < nbytes; i++) {
    unsigned char c = (unsigned char) (reg & 0xff);
    append_rsp_buf_hex_byte(conn, r, c);
    reg >>= 8;
  }
}

static void handle_regs_read(struct rsp_conn *conn, struct rsp_buf *req, struct rsp_buf *resp) {
  send_reg_val(conn, resp, zx1);
  send_reg_val(conn, resp, zx2);
  send_reg_val(conn, resp, zx3);
  send_reg_val(conn, resp, zx4);
  send_reg_val(conn, resp, zx5);
  send_reg_val(conn, resp, zx6);
  send_reg_val(conn, resp, zx7);
  send_reg_val(conn, resp, zx8);
  send_reg_val(conn, resp, zx9);
  send_reg_val(conn, resp, zx10);
  send_reg_val(conn, resp, zx11);
  send_reg_val(conn, resp, zx12);
  send_reg_val(conn, resp, zx13);
  send_reg_val(conn, resp, zx14);
  send_reg_val(conn, resp, zx15);
  send_reg_val(conn, resp, zx16);
  send_reg_val(conn, resp, zx17);
  send_reg_val(conn, resp, zx18);
  send_reg_val(conn, resp, zx19);
  send_reg_val(conn, resp, zx20);
  send_reg_val(conn, resp, zx21);
  send_reg_val(conn, resp, zx22);
  send_reg_val(conn, resp, zx23);
  send_reg_val(conn, resp, zx24);
  send_reg_val(conn, resp, zx25);
  send_reg_val(conn, resp, zx26);
  send_reg_val(conn, resp, zx27);
  send_reg_val(conn, resp, zx28);
  send_reg_val(conn, resp, zx29);
  send_reg_val(conn, resp, zx30);
  send_reg_val(conn, resp, zx31);
  send_reg_val(conn, resp, zPC);
}

static void handle_reg_read(struct rsp_conn *conn, struct rsp_buf *req, struct rsp_buf *resp) {
  // extract regno,regval
  int ofs = 1; // past 'p'
  uint64_t regno = 0, regval = 0;
  if (extract_hex_integer_be(conn, req, &ofs, '#', &regno) < 0) {
    dprintf(conn->log_fd, "internal error: no 'p' packet terminator '#' found\n");
    exit(1);
  }

  switch (regno) {

  case 0:
    regval = 0;
    break;

#define case_reg(reg)                           \
    case reg:                                   \
      regval = zx ## reg;                       \
      break

  case_reg(1);
  case_reg(2);
  case_reg(3);
  case_reg(4);
  case_reg(5);
  case_reg(6);
  case_reg(7);
  case_reg(8);
  case_reg(9);
  case_reg(10);
  case_reg(11);
  case_reg(12);
  case_reg(13);
  case_reg(14);
  case_reg(15);
  case_reg(16);
  case_reg(17);
  case_reg(18);
  case_reg(19);
  case_reg(20);
  case_reg(21);
  case_reg(22);
  case_reg(23);
  case_reg(24);
  case_reg(25);
  case_reg(26);
  case_reg(27);
  case_reg(28);
  case_reg(29);
  case_reg(30);
  case_reg(31);

#undef case_reg

  case 32:
    regval = zPC;
    break;
  default:
    dprintf(conn->log_fd, "unrecognized register number %ld\n", regno);
    exit(1);
  }
  dprintf(conn->log_fd, "read reg %ld as 0x%016" PRIx64 "\n", regno, regval);
  send_reg_val(conn, resp, regval);
}

static void handle_reg_write(struct rsp_conn *conn, struct rsp_buf *req, struct rsp_buf *resp) {
  // extract regno,regval
  int ofs = 1; // past 'P'
  uint64_t regno = 0, regval = 0;
  if (extract_hex_integer_be(conn, req, &ofs, '=', &regno) < 0) {
    dprintf(conn->log_fd, "internal error: no 'P' packet terminator '=' found\n");
    exit(1);
  }
  ofs++;
  if (extract_hex_integer_le(conn, req, &ofs, '#', &regval) < 0) {
    dprintf(conn->log_fd, "internal error: no 'P' packet terminator '#' found\n");
    exit(1);
  }
  dprintf(conn->log_fd, "setting reg %ld to 0x%016" PRIx64 "\n", regno, regval);

  switch (regno) {
  case 0:
    dprintf(conn->log_fd, "ignoring attempt to write $zero\n");
    break;

#define case_reg(reg)                           \
    case reg:                                   \
      zx ## reg = regval;                       \
      break

  case_reg(1);
  case_reg(2);
  case_reg(3);
  case_reg(4);
  case_reg(5);
  case_reg(6);
  case_reg(7);
  case_reg(8);
  case_reg(9);
  case_reg(10);
  case_reg(11);
  case_reg(12);
  case_reg(13);
  case_reg(14);
  case_reg(15);
  case_reg(16);
  case_reg(17);
  case_reg(18);
  case_reg(19);
  case_reg(20);
  case_reg(21);
  case_reg(22);
  case_reg(23);
  case_reg(24);
  case_reg(25);
  case_reg(26);
  case_reg(27);
  case_reg(28);
  case_reg(29);
  case_reg(30);
  case_reg(31);

#undef case_reg

  case 32:
    zPC = regval;
    break;
  default:
    dprintf(conn->log_fd, "unrecognized register number %ld\n", regno);
    exit(1);
  }
  make_ok_resp(conn, resp);
}

static void handle_step(struct rsp_conn *conn, struct rsp_buf *req, struct rsp_buf *resp) {
  if (match_req_cmd(req, "s#")) {
    // step at current address
    sail_int sail_step;
    bool stepped;
    CREATE(sail_int)(&sail_step);
    CONVERT_OF(sail_int, mach_int)(&sail_step, conn->model.step_no);
    stepped = zstep(sail_step);
    KILL(sail_int)(&sail_step);
    if (have_exception) {
      dprintf(conn->log_fd, "internal Sail exception, exiting!\n");
      conn_exit(conn, 1);
    }
    if (stepped) conn->model.step_no++;
    /* stopping after a single step is equivalent to the interrupted signal code: SIGTRAP -> 5 */
    append_rsp_buf_msg(conn, resp, "S");
    append_rsp_buf_hex_byte(conn, resp, 5);
    return;
  }
  make_error_resp(conn, resp, 1);
}

static void handle_read_mem(struct rsp_conn *conn, struct rsp_buf *req, struct rsp_buf *resp) {
  // extract addr,length
  int ofs = 1; // past 'm'
  uint64_t addr = 0, len = 0;
  if (extract_hex_integer_be(conn, req, &ofs, ',', &addr) < 0) {
    dprintf(conn->log_fd, "internal error: no 'm' packet terminator ',' found\n");
    exit(1);
  }
  ofs++;
  if (extract_hex_integer_be(conn, req, &ofs, '#', &len) < 0) {
    dprintf(conn->log_fd, "internal error: no 'm' packet terminator '#' found\n");
    exit(1);
  }
  ofs++;
  // trust gdb for legal addr/len?
  for (uint64_t i = 0; i < len; i++) {
    unsigned char byte = (unsigned char) read_mem(addr+i);
    append_rsp_buf_hex_byte(conn, resp, byte);
  }
}

static void handle_write_mem(struct rsp_conn *conn, struct rsp_buf *req, struct rsp_buf *resp) {
  // extract addr,length
  int ofs = 1; // past 'M'
  uint64_t addr = 0, len = 0;
  if (extract_hex_integer_be(conn, req, &ofs, ',', &addr) < 0) {
    dprintf(conn->log_fd, "internal error: no 'M' packet terminator ',' found\n");
    exit(1);
  }
  ofs++;
  if (extract_hex_integer_be(conn, req, &ofs, ':', &len) < 0) {
    dprintf(conn->log_fd, "internal error: no 'M' packet terminator ':' found\n");
    exit(1);
  }
  ofs++;
  // trust gdb for legal addr/len?
  for (uint64_t i = 0; i < len; i++) {
    if (ofs >= req->bufsz) {
      dprintf(conn->log_fd, "not enough payload in 'M' packet!\n");
      exit(1);
    }
    uint64_t byte = int_of_hex(req->cmd_buf[ofs++]);
    byte <<= 4;
    byte += int_of_hex(req->cmd_buf[ofs++]);
    write_mem(addr++, byte);
  }
  make_ok_resp(conn, resp);
}

static void handle_cont(struct rsp_conn *conn, struct rsp_buf *req, struct rsp_buf *resp) {
  if (match_req_cmd(req, "c#")) { // todo: handle pc argument
    // allow interrupt requests
    expect_interrupt_req = 1;
    int step_cnt = 0;
    // continue at current address
    while (!zhtif_done) { // fixme: we may not have a legal zhtif!
      sail_int sail_step;
      bool stepped;
      CREATE(sail_int)(&sail_step);
      CONVERT_OF(sail_int, mach_int)(&sail_step, conn->model.step_no);
      stepped = zstep(sail_step);
      KILL(sail_int)(&sail_step);
      if (have_exception) {
        dprintf(conn->log_fd, "internal Sail exception, exiting!\n");
        conn_exit(conn, 1);
      }
      if (stepped) conn->model.step_no++;

      if (match_breakpoint(conn, zPC)) {
        // should we use model.run_state / handle_stop_reply?
        /* this is equivalent to the interrupted signal code: SIGTRAP -> 5 */
        append_rsp_buf_msg(conn, resp, "S");
        append_rsp_buf_hex_byte(conn, resp, 5);
        break;
      }
      step_cnt++;
      if (step_cnt == 50) {
        step_cnt = 0;
        if (read_req(conn, req)) {
          if (interrupt_reqs > 0) {
            --interrupt_reqs;
            dprintf(conn->log_fd, "interrupted, breaking\n");
          } else {
            dprintf(conn->log_fd, "got another request during cont, breaking\n");
          }
          // send a stop-reply as above
          append_rsp_buf_msg(conn, resp, "S");
          append_rsp_buf_hex_byte(conn, resp, 5);
          break;
        }
      }
    }
    // disable interrupt requests
    expect_interrupt_req = 0;
    return;
  }
  make_error_resp(conn, resp, 1);
}

static void handle_sw_breakpoint(struct rsp_conn *conn, struct rsp_buf *req, struct rsp_buf *resp) {
  if (match_req_cmd(req, "Z0,") || match_req_cmd(req, "z0,")) { // software breakpoint
    // extract address and kind
    uint64_t addr = 0, kind = 0;
    int ofs = 3; // past Z0,
    if (extract_hex_integer_be(conn, req, &ofs, ',', &addr) < 0) {
      dprintf(conn->log_fd, "internal error: no '{Zz}0' packet terminator ',' found\n");
      exit(1);
    }

    ofs++;
    switch (req->cmd_buf[ofs]) {
    case '2':
      kind = 2;
      break;
    case '4':
      kind = 4;
      break;
    default:
      dprintf(conn->log_fd, "error: unexpected '{Zz}0' kind found\n");
      make_error_resp(conn, resp, 1);
      return;
    }

    ofs++;
    switch (req->cmd_buf[ofs]) {
    case '#':
      // expected case, no byte-coded condition triggers
      break;
    case ';':
    default:
      dprintf(conn->log_fd, "conditional triggers for breakpoints not supported\n");
      make_empty_resp(conn, resp);
      return;
    }

    if (req->cmd_buf[0] == 'Z') {
      dprintf(conn->log_fd, "setting breakpoint at addr=0x%016" PRIx64 " of kind %ld\n",
              addr, kind);
      if (insert_breakpoint(conn, addr, kind) < 0) {
        dprintf(conn->log_fd, "out of breakpoint slots!\n");
        make_error_resp(conn, resp, 1);
        return;
      }
    } else {
      dprintf(conn->log_fd, "removing breakpoint at addr=0x%016" PRIx64 " of kind %ld\n",
              addr, kind);
      if (remove_breakpoint(conn, addr, kind) < 0) {
        make_error_resp(conn, resp, 1);
        return;
      }
    }

    make_ok_resp(conn, resp);
    return;
  }
  make_empty_resp(conn, resp);
}

static void dispatch_req(struct rsp_conn *conn, struct rsp_buf *req, struct rsp_buf *resp) {
  prepare_resp(conn, resp);
  switch (req->cmd_buf[0]) {
  case 'q':
  case 'Q':
    handle_query(conn, req, resp);
    break;
  case 'v':
    handle_vmsgs(conn, req, resp);
    break;
  case 'g':
    handle_regs_read(conn, req, resp);
    break;
  case 'p':
    handle_reg_read(conn, req, resp);
    break;
  case 'P':
    handle_reg_write(conn, req, resp);
    break;
  case 'H':
    handle_set_context(conn, req, resp);
    break;
  case '?':
    handle_stop_reply(conn, req, resp);
    break;
  case 'D':
    dprintf(conn->log_fd, "GDB disconnecting, exiting.\n");
    /* wait for another connection? */
    conn_exit(conn, 0);
    break;
  case 's':
    handle_step(conn, req, resp);
    break;
  case 'm':
    handle_read_mem(conn, req, resp);
    break;
  case 'M':
    handle_write_mem(conn, req, resp);
    break;
  case 'c':
    handle_cont(conn, req, resp);
    break;
  case 'Z':
  case 'z':
    handle_sw_breakpoint(conn, req, resp);
    break;
  case 'X':
    // force use of 'M': send an empty response
    make_empty_resp(conn, resp);
    break;
  default:
    dprintf(conn->log_fd, "Unsupported cmd %c\n", req->cmd_buf[0]);
    conn_exit(conn, 1);
  }
}

static void resp_set_checksum(struct rsp_conn *conn, struct rsp_buf *r) {
  unsigned char chksum = 0;
  int i = 0;
  while (r->cmd_buf[i] != '$') { i++; assert(i < r->bufofs); }
  for (i++; i < r->bufofs; i++) {
    chksum += r->cmd_buf[i];
  }
  while (r->bufofs + 3 > r->bufsz) {
    grow_rsp_buf(conn, r);
  }
  r->cmd_buf[r->bufofs++] = '#';
  push_hex_byte(r->cmd_buf + r->bufofs, chksum);
  r->bufofs += 2;
}

static void send_resp(struct rsp_conn *conn, struct rsp_buf *r) {
  int nbytes = 0;
  while (nbytes < r->bufofs) {
    int n = write(conn->conn_fd, r->cmd_buf + nbytes, r->bufofs - nbytes);
    if (n < 0) {
      dprintf(conn->log_fd, "[dbg] error sending response: %s\n", strerror(errno));
      conn_exit(conn, 1);
    }

    dprintf(conn->log_fd, "[dbg] -> ");
    for (int i = 0; i < n; i++) {
      dprintf(conn->log_fd, "%c", r->cmd_buf[nbytes + i]);
    }
    dprintf(conn->log_fd, "\n");

    nbytes += n;
  }
}

static void gdb_server_dispatch(struct rsp_conn *conn, struct rsp_buf *req, struct rsp_buf *resp) {
  while (1) {
    while (!read_req(conn, req))  // should move to a select loop :p
      ;

    dispatch_req(conn, req, resp);

    resp_set_checksum(conn, resp);
    send_resp(conn, resp);

    req->bufofs = 0;
    resp->bufofs = 0;
  }
}

void gdb_server_run(void) {
  if ((conn.conn_fd = accept(conn.listen_fd, (struct sockaddr *)NULL, NULL)) < 0) {
    dprintf(conn.log_fd, "[dbg] error accepting connection: %s\n", strerror(errno));
    exit(1);
  }
  if (fcntl(conn.conn_fd, F_SETFL, O_NONBLOCK) < 0) {
    dprintf(conn.log_fd, "[dbg] error making connection non-blocking: %s\n", strerror(errno));
    exit(1);
  }

  grow_rsp_buf(&conn, &req);
  grow_rsp_buf(&conn, &resp);
  gdb_server_dispatch(&conn, &req, &resp);
}
