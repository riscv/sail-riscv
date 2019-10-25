.PHONE: all clean

all: rot13-64

rot13-64: rot13.c
	riscv64-unknown-linux-gnu-gcc  -g -Og -o rot13-64.o -c rot13.c
	riscv64-unknown-linux-gnu-gcc  -g -Og -T spike.lds -nostartfiles -o rot13-64 rot13-64.o

clean:
	-rm rot13-64 rot13-64.o
