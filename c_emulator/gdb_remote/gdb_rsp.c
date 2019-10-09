#include <assert.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

// to develop and debug the protocol, set the debug flag on gdb:
//
// (gdb) set debug remote 1
// (gdb) target remote localhost:<port>

struct proto_state {
  int send_acks;
};

struct rsp_conn {
  int listen_fd;
  int conn_fd;
  int log_fd;
  struct proto_state proto;
};

static struct rsp_conn conn;

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
  // todo: mark non-blocking
  if (listen(sock, 2) < 0) {
    dprintf(log_fd, "Unable to listen on socket: %s\n", strerror(errno));
    return -1;
  }
  dprintf(log_fd, "listening on port %d\n", port);
  conn.listen_fd = sock;
  conn.log_fd = log_fd;
  conn.proto.send_acks = 1;  // start out sending acks
  return 0;
}

#define BUFSZ 1024
struct rsp_buf {
  char *cmd_buf;
  int bufofs;
  int bufsz;
};

// buffer utils

static void grow_rsp_buf(struct rsp_conn *conn, struct rsp_buf *b) {
  if (b->cmd_buf == NULL) {
    if ((b->cmd_buf = (char *)malloc(BUFSZ*sizeof(char) + 1)) == NULL) {
      dprintf(conn->log_fd, "[dbg] unable to init cmd_buf\n");
      exit(1);
    }
    b->bufofs = 0;
    b->bufsz = BUFSZ;
    return;
  }

  b->cmd_buf = (char *)realloc(b->cmd_buf, 2*b->bufsz + 1);
  if (b->cmd_buf == NULL) {
    dprintf(conn->log_fd, "[dbg] cannot realloc to %d bytes, quitting!\n", 2*b->bufsz + 1);
    exit(1);
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


static struct rsp_buf req  = { NULL, 0, 0 };
static struct rsp_buf resp = { NULL, 0, 0 };

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
      dprintf(conn->log_fd, "[dbg] Error reading socket: %s\n", strerror(errno));
      exit(1);
    }
    dprintf(conn->log_fd, "[dbg] <- ");
    for (int i = 0; i < nbytes; i++) {
      dprintf(conn->log_fd, "%c", buf[i]);
    }
    dprintf(conn->log_fd, "\n");

    int ofs = 0;
    if (!saw_start) {
      /* wait for the '$' */
      while (buf[ofs] != '$') {
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
static void make_error_resp(struct rsp_conn *conn, struct rsp_buf *r, unsigned char err) {
  while (r->bufofs + 3 > r->bufsz) {
    grow_rsp_buf(conn, r);
  }
  r->cmd_buf[r->bufofs++] = 'E';
  push_hex_byte(r->cmd_buf + r->bufofs, err);
  r->bufofs += 2;
}

static void handle_query(struct rsp_conn *conn, struct rsp_buf *req, struct rsp_buf *resp) {
  if (match_req_cmd(req, "qSupported:")) {
    append_rsp_buf_msg(conn, resp, "multiprocess-;swbreak-;hwbreak-;qRelocInsn-");
    append_rsp_buf_msg(conn, resp, ";fork-events-;vfork-events-;exec-events-");
    append_rsp_buf_msg(conn, resp, ";vContSupported-;QThreadEvents-;no-resumed-");

    // offer no-ack mode
    append_rsp_buf_msg(conn, resp, ";QStartNoAckMode+");
    return;
  }
  if (match_req_cmd(req, "QStartNoAckMode")) {
    append_rsp_buf_msg(conn, resp, "OK");
    conn->proto.send_acks = 0;
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
      append_rsp_buf_msg(conn, resp, "OK");
      return;
    }
  }
  make_error_resp(conn, resp, 1);
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
  case 'H':
    handle_set_context(conn, req, resp);
    break;
  default:
    dprintf(conn->log_fd, "Unsupported cmd %c\n", req->cmd_buf[0]);
    exit(1);
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
      exit(1);
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
    read_req(conn, req);
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
  grow_rsp_buf(&conn, &req);
  grow_rsp_buf(&conn, &resp);
  gdb_server_dispatch(&conn, &req, &resp);
}
