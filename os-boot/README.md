# Booting OS images

The Sail model implements a very simple platform based on the one implemented by the Spike reference simulator. It implements Spike's HTIF (Host-Target Interface) which allows console output, and an interrupt controller based on Spike's CLINT (core-local interrupt controller). Console input is not currently supported.

32-bit OS boots require a workaround for the 64-bit HTIF interface, which is currently not supported.

## Build your own ELF

```bash
make -C linux -j4
```

This will generate `os-boot/linux/build/fw_payload.elf`.

### Boot ELF

```bash
make -C linux sail
```

You should see the OpenSBI banner after a few seconds. Eventually it will crash when it fails to find an `init` process which the image does not currently include.
