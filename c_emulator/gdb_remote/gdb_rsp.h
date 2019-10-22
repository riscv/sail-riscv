#ifndef _GDB_RSP_H_
#define _GDB_RSP_H_

#include "gdb_utils.h"

struct rsp_conn *gdb_server_init(int port, int log_fd);
void gdb_server_set_arch(struct rsp_conn *conn, struct sail_arch *arch);
void gdb_server_run(struct rsp_conn *conn);

#endif
