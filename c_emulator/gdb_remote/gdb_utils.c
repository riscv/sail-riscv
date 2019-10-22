#include <assert.h>
#include <inttypes.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>

#include "sail.h"
#include "rts.h"
#include "gdb_utils.h"

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
int extract_hex_integer_be(struct rsp_conn *conn, struct rsp_buf *req, int *start_ofs, char terminator, uint64_t *val) {
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
int extract_hex_integer_le(struct rsp_conn *conn, struct rsp_buf *req, int *start_ofs, char terminator, uint64_t *val) {
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

// protocol message utilities

void grow_rsp_buf(struct rsp_conn *conn, struct rsp_buf *b) {
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

void append_rsp_buf_bytes(struct rsp_conn *conn, struct rsp_buf *b, const char *msg, int mlen) {
  while (b->bufofs + mlen >= b->bufsz) {
    grow_rsp_buf(conn, b);
  }
  memcpy(b->cmd_buf + b->bufofs, msg, mlen);
  b->bufofs += mlen;
  b->cmd_buf[b->bufofs] = 0;
}

void append_rsp_buf_msg(struct rsp_conn *conn, struct rsp_buf *b, const char *msg) {
  append_rsp_buf_bytes(conn, b, msg, strlen(msg));
}

void append_rsp_buf_hex_byte(struct rsp_conn *conn, struct rsp_buf *b, unsigned char byte) {
  while (b->bufofs + 2 >= b->bufsz) {
    grow_rsp_buf(conn, b);
  }
  push_hex_byte(b->cmd_buf + b->bufofs, byte);
  b->bufofs += 2;
}


// other state and connection utils

void init_gdb_model(struct model_state *model) {
  memset(model, 0, sizeof(*model));
  model->run_state = M_RUN_START;
  model->step_no = 0;
}

void conn_exit(struct rsp_conn *conn, int code) {
  close(conn->conn_fd);
  close(conn->listen_fd);
  close(conn->log_fd);
  exit(code);
}


