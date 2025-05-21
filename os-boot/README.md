# Booting OS images

The Sail model implements a very simple platform based on the one implemented by the Spike reference simulator. It implements Spike's HTIF (Host-Target Interface) which allows console output, and an interrupt controller based on Spike's CLINT (core-local interrupt controller). Console input is not currently supported.

32-bit OS boots require a workaround for the 64-bit HTIF interface, which is currently not supported.

## Build your own openSBI

```bash
make -j4 -C opensbi
```

This will generate `os-boot/opensbi/build/fw_payload.elf`.

### Boot openSBI ELF

```bash
make sail -C opensbi
```

You should see the OpenSBI banner and then `Test payload running` after a few minutes.
