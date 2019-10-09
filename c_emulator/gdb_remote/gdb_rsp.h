#ifndef _GDB_RSP_H_
#define _GDB_RSP_H_

int gdb_server_init(int port, int log_fd);
void gdb_server_run(void);

#endif
