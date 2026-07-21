This directory implements a usable fragment of the Remote Serial
Protocol for a debugger like GDB and LLDB, allowing it to connect to
the simulator and debug the execution of the ELF file loaded by the
simulator. This requires that the debugger support the RISC-V target.

## Usage

To use the simulator in this mode, run it as:

```
$ sail_riscv_sim [other options] [--trace-gdbserver] --gdb-server-port <port> <elf_file>
```

The `--trace-gdbserver` option logs the messages in the protocol into
the trace file.

Then, from another terminal, run the debugger on the ELF file
specified above. For GDB,

```
$ riscv64-unknown-elf-gdb <elf_file>
```

and then at the GDB prompt,

```
(gdb) target remote localhost:<port>
```

where `<port>` is the port number specified in above when running
`sail_riscv_sim`. Optionally, you can turn on logging for the
protocol communication with

```
(gdb) set debug remote 1
```

Similarly, for an LLDB that supports the RISC-V target, do

```
$ lldb <elf_file>
```

and then at the LLDB prompt,

```
(lldb) gdb-remote localhost:<port>
```

Optionally, you can turn on logging for the protocol with

```
(lldb) log enable gdb-remote packets
```

and increasingly more verbose logging with

```
(lldb) log enable gdb-remote all
(lldb) log enable lldb all
```

If the debugger closes the connection, the simulator exits.

## Known limitations

Access to vector registers and CSRs is currently not supported.

## Reporting issues

Please run the simulator with `--trace-gdbserver` and share the trace
log. It would be good to enable debug logging on the debugger side as
well (see above). Usually the issue is a packet that is not in the
currently supported fragment of the protocol.
