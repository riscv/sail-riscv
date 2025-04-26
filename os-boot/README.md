# Booting OS images

The Sail model implements a very simple platform based on the one
implemented by the Spike reference simulator. It implements a console
output port similar to Spike's HTIF (host-target interface) mechanism,
and an interrupt controller based on Spike's CLINT (core-local
interrupt controller). Console input is not currently supported.

32-bit OS boots require a workaround for the 64-bit HTIF interface,
which is currently not supported.

## Build your own ELF

```bash
make -C linux
```

This will generate `os-boot/linux/build/fw_payload.elf`.

### Boot ELF

```bash
make sail
```

### Results

You should see the OpenSBI banner after a few seconds.
