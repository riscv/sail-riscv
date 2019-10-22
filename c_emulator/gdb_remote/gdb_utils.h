#ifndef _GDB_UTILS_H_
#define _GDB_UTILS_H_

// protocol and connection state

struct proto_state {
  int send_acks;
};

typedef enum {
  M_RUN_START,
  M_RUN_RUNNING,
  M_RUN_BREAKPOINT,
  M_RUN_HALT         // currently unused
} model_run_state_t;

struct sw_breakpoint {
  int active;     // 0 -> inactive
  int kind;       // either 2 (c.ebreak) or 4 (ebreak)
  uint64_t addr;  // pc
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
  struct sail_arch *arch;
};

void init_gdb_model(struct model_state *model);
void conn_exit(struct rsp_conn *conn, int code);

// protocol message buffers

#define BUFSZ 2048
struct rsp_buf {
  char *cmd_buf;
  int bufofs;
  int bufsz;
};

void grow_rsp_buf(struct rsp_conn *conn, struct rsp_buf *b);
void append_rsp_buf_bytes(struct rsp_conn *conn, struct rsp_buf *b, const char *msg, int mlen);
void append_rsp_buf_msg(struct rsp_conn *conn, struct rsp_buf *b, const char *msg);
void append_rsp_buf_hex_byte(struct rsp_conn *conn, struct rsp_buf *b, unsigned char byte);

// hex utils

int int_of_hex(char c);
char hex_of_int(unsigned val);
void push_hex_byte(char *buf, uint8_t byte);

// integers from endian-specific hex-encodings
int extract_hex_integer_be(struct rsp_conn *c, struct rsp_buf *r, int *start_ofs, char terminator, uint64_t *val);
int extract_hex_integer_le(struct rsp_conn *conn, struct rsp_buf *req, int *start_ofs, char terminator, uint64_t *val);

// basic interface to the sail model.

typedef enum {
  ARCH32,
  ARCH64,
} archlen_t;

struct sail_arch {
  archlen_t archlen;
  uint64_t  nregs;    // inclusive bound, and typically includes the PC register
  mach_bits (*get_reg)(struct rsp_conn *conn, struct sail_arch *arch, uint64_t regno);
  mach_bits (*get_pc)(struct rsp_conn *conn, struct sail_arch *arch);
  void (*set_reg) (struct rsp_conn *conn, struct sail_arch *arch, uint64_t regno, mach_bits regval);
  void (*set_pc) (struct rsp_conn *conn, struct sail_arch *arch, mach_bits regval);

  int (*step) (struct rsp_conn *conn, struct sail_arch *arch);
  bool (*is_done) (struct rsp_conn *conn, struct sail_arch *arch);
  void *arch_info;
};

#endif // _GDB_UTILS_H_
