The C emulator implements a very basic GDB remote server, allowing it
to be used as a remote target for GDB.

The files in this directory can be used to test this feature, using
the example used in the spike RISC-V simulator.  Make sure you have
the RISCV toolchain in your path.  If you don't have a toolchain
already, you may need to build this toolchain using `crosstool`.

From the top-level `sail-riscv` directory:

```
$ make -C debugger
$ ./c_emulator/riscv_sim_RV64 -g 9333 -B 0x10000000 -z 0x20000 debugger/rot13-64
```

In another terminal, start gdb (built from the RISC-V toolchain) and
connect it to the emulator:

```
$ riscv64-unknown-linux-gnu-gdb debugger/rot13-64
There is NO WARRANTY, to the extent permitted by law.
Type "show copying" and "show warranty" for details.
This GDB was configured as "--host=x86_64-build_pc-linux-gnu --target=riscv64-unknown-linux-gnu".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<http://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
    <http://www.gnu.org/software/gdb/documentation/>.
	
For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from debugger/rot13-64...done.
(gdb) target remote localhost:9333
Remote debugging using localhost:9333
main () at rot13.c:9
9    ;
(gdb) print wait
$1 = 1
(gdb) print wait=0
$2 = 0
(gdb) print text
$3 = "Vafgehpgvba frgf jnag gb or serr!"
(gdb) b done
Breakpoint 1 at 0x10010062: file rot13.c, line 22.
(gdb) c
Continuing.

Breakpoint 1, main () at rot13.c:24
24    ;
(gdb) p wait
$4 = 0

```
