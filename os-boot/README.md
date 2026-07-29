# Booting OS images

The Sail model implements a very simple platform based on the one implemented by the Spike reference simulator. It implements Spike's HTIF (Host-Target Interface) which allows console output, and an interrupt controller based on Spike's CLINT (core-local interrupt controller). Console input is not currently supported.

32-bit OS boots require a workaround for the 64-bit HTIF interface, which is currently not supported.

## Build and boot a basic Linux image

Two images can be built, Linux and the Xvisor hypervisor. Both are OpenSBI with
the payload embedded in it.

```bash
make -j4
```

This generates `os-boot/build/fw_payload_linux.elf` and
`os-boot/build/fw_payload_xvisor.elf`. Build just one with `make linux` or
`make xvisor`.

This image can be booted on the model as follows:

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

### Known issues

`xvisor_spike` and `xvisor_qemu` do not currently work.

Spike's default device tree does not match the Sail platform, and passing the
model's one with `--dtb` instead fails because Spike reads the ISA from it and
rejects the extensions it does not implement, starting with `zic64b`. Limiting
the extensions in the device tree to what Spike actually supports makes it work.

The QEMU failure has not been diagnosed.

TODO: get both targets working.

## Booting a more complete Linux image

To boot Linux to a prompt, Linux typically uses a `initramfs`, which needs to be placed in memory, with its location specified in the device tree. Such an image takes much longer to boot, and while it boots to a user space shell, input to the shell is not currently supported.

The build command above also builds the `initramfs` image using Busybox.

```bash
make -j4
```

This version can be booted on the model using:

```bash
make linux_ramfs_sail
```

## Booting custom Linux images

When booting custom versions of Linux and `initramfs` images, the following
steps need to be followed after those images are built:

1. Generate a device tree blob for the configuration that includes the
   memory location of the `initramfs` (e.g. `rootfs.cpio`) for the
   boot image (e.g. `fw_payload.elf` when bundled with OpenSBI). This
   uses the device tree compiler (`dtc`) available in the
   `device-tree-compiler` package on Debian-based systems and the
   `dtc` package on Fedora-based ones.

```bash
$ sail_riscv_sim --print-device-tree --initramfs rootfs.cpio fw_payload.elf | dtc > sail_boot.dtb
```

2. Boot the image:

```bash
$ sail_riscv_sim --initramfs rootfs.cpio --device-tree-blob sail_boot.dtb fw_payload.elf
```
