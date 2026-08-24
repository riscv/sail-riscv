# Booting OS images

The Sail model implements a very simple platform based on the one implemented by the Spike reference simulator. It implements Spike's HTIF (Host-Target Interface) which allows console output, and an interrupt controller based on Spike's CLINT (core-local interrupt controller). Console input is not currently supported.

32-bit OS boots require a workaround for the 64-bit HTIF interface, which is currently not supported.

## Build your own ELF

Two images can be built, Linux and the Xvisor hypervisor. Both are OpenSBI with
the payload embedded in it.

```bash
make -j4
```

This generates `os-boot/build/fw_payload_linux.elf` and
`os-boot/build/fw_payload_xvisor.elf`. Build just one with `make linux` or
`make xvisor`.

### Boot ELF

```bash
make linux_sail
make xvisor_sail
```

You should see the OpenSBI banner after a few seconds.

Linux eventually crashes when it fails to find an `init` process, which the
image does not currently include. Xvisor reaches its prompt and stops there,
since console input is not supported and there is no way to type anything.

The same naming works for the other simulators, `linux_spike`, `xvisor_qemu`,
and so on.
