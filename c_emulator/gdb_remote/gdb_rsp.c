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
#include "gdb_utils.h"
#include "gdb_arch.h"

// to develop and debug the protocol, set the debug flag on gdb:
//
// (gdb) set debug remote 1
// (gdb) target remote localhost:<port>

struct rsp_conn *gdb_server_init(int port, int log_fd) {
  int sock = socket(AF_INET, SOCK_STREAM, 0);
  int opt = 1;
  if (sock < 0) {
    dprintf(log_fd, "Unable to open socket for port %d: %s\n", port, strerror(errno));
    return NULL;
  }
  if (setsockopt(sock, SOL_SOCKET, (SO_REUSEPORT | SO_REUSEADDR), (char *)&opt, sizeof(opt)) < 0) {
    dprintf(log_fd, "Cannot set reuse option on socket: %s\n", strerror(errno));
    close(sock);
    return NULL;
  }

  struct sockaddr_in saddr;
  memset(&saddr, 0, sizeof(saddr));
  saddr.sin_family = AF_INET;
  saddr.sin_addr.s_addr = htonl(INADDR_ANY);
  saddr.sin_port = htons(port);
  if (bind(sock, (struct sockaddr*)&saddr, sizeof(saddr)) < 0) {
    dprintf(log_fd, "Unable to bind to port %d: %s\n", port, strerror(errno));
    close(sock);
    return NULL;
  }
  if (listen(sock, 2) < 0) {
    dprintf(log_fd, "Unable to listen on socket: %s\n", strerror(errno));
    close(sock);
    return NULL;
  }
  struct rsp_conn *conn = (struct rsp_conn *)malloc(sizeof(*conn));
  if (conn == NULL) {
    close(sock);
    return NULL;
  }
  dprintf(log_fd, "listening on port %d\n", port);
  conn->listen_fd = sock;
  conn->log_fd = log_fd;
  conn->proto.send_acks = 1;  // start out sending acks
  init_gdb_model(&conn->model);
  return conn;
}

void gdb_server_set_arch(struct rsp_conn *conn, struct sail_arch *arch) {
  conn->arch = arch;
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

// request and response handling

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
  case M_RUN_RUNNING:
  default:
    // We shouldn't be getting this if we are running.
    dprintf(conn->log_fd, "Unhandled stop reply for state %d\n", conn->model.run_state);
    conn_exit(conn, 1);
    break;
  }
}

static void send_reg_val(struct rsp_conn *conn, struct rsp_buf *r, mach_bits reg) {
  struct sail_arch *arch = conn->arch;
  int nbytes = (arch->archlen == ARCH32) ? 4 : 8;  // only RV32 or RV64 for now
  for (int i = 0; i < nbytes; i++) {
    unsigned char c = (unsigned char) (reg & 0xff);
    append_rsp_buf_hex_byte(conn, r, c);
    reg >>= 8;
  }
}

static void handle_regs_read(struct rsp_conn *conn, struct rsp_buf *req, struct rsp_buf *resp) {
  mach_bits regval;
  for (uint64_t i = 0; i < 32; i++) {
    regval = conn->arch->get_reg(conn, conn->arch, i);
    send_reg_val(conn, resp, regval);
  }
  regval = conn->arch->get_pc(conn, conn->arch);
  send_reg_val(conn, resp, regval);
}

static void handle_reg_read(struct rsp_conn *conn, struct rsp_buf *req, struct rsp_buf *resp) {
  // extract regno,regval
  int ofs = 1; // past 'p'
  uint64_t regno = 0;
  if (extract_hex_integer_be(conn, req, &ofs, '#', &regno) < 0) {
    dprintf(conn->log_fd, "internal error: no 'p' packet terminator '#' found\n");
    exit(1);
  }

  uint64_t regval = (regno == 32) ?
    conn->arch->get_pc(conn, conn->arch) : conn->arch->get_reg(conn, conn->arch, regno);
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

  if (regno == 32)
    conn->arch->set_pc(conn, conn->arch, regval);
  else
    conn->arch->set_reg(conn, conn->arch, regno, regval);

  make_ok_resp(conn, resp);
}

static void handle_step(struct rsp_conn *conn, struct rsp_buf *req, struct rsp_buf *resp) {
  if (match_req_cmd(req, "s#")) {
    conn->arch->step(conn, conn->arch);
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
    conn->model.run_state = M_RUN_RUNNING;
    struct sail_arch *arch = conn->arch;
    // continue at current address
    while (!arch->is_done(conn, arch)) {
      if (!arch->step(conn, arch)) {
        dprintf(conn->log_fd, "unable to step model, exiting.\n");
        conn_exit(conn, 1);
      }

      mach_bits pc = arch->get_pc(conn, arch);
      if (match_breakpoint(conn, pc)) {
        conn->model.run_state = M_RUN_BREAKPOINT;
        handle_stop_reply(conn, req, resp);
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
          conn->model.run_state = M_RUN_BREAKPOINT;
          // send a stop-reply as above
          handle_stop_reply(conn, req, resp);
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

void gdb_server_run(struct rsp_conn *conn) {
  if ((conn->conn_fd = accept(conn->listen_fd, (struct sockaddr *)NULL, NULL)) < 0) {
    dprintf(conn->log_fd, "[dbg] error accepting connection: %s\n", strerror(errno));
    exit(1);
  }
  if (fcntl(conn->conn_fd, F_SETFL, O_NONBLOCK) < 0) {
    dprintf(conn->log_fd, "[dbg] error making connection non-blocking: %s\n", strerror(errno));
    exit(1);
  }

  grow_rsp_buf(conn, &req);
  grow_rsp_buf(conn, &resp);
  gdb_server_dispatch(conn, &req, &resp);
}
