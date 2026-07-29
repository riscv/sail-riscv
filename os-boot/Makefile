##### Compilation #####

RISCV_COMPILER_PREFIX := riscv64-buildroot-linux-gnu-

# Payloads that get embedded into OpenSBI to make the final bootable image.
payload_linux  := build/linux/arch/riscv/boot/Image
payload_xvisor := build/xvisor/build/vmm.bin

# Built binaries.
linux_elf  := build/fw_payload_linux.elf
xvisor_elf := build/fw_payload_xvisor.elf

# Initramfs filesystem image.
ramfs := build/rootfs.cpio

.PHONY: all linux xvisor
all: linux xvisor ramfs

linux: $(linux_elf)
xvisor: $(xvisor_elf)
ramfs: $(ramfs)

# Generic rules to download tools.

downloads/%.tar.xz: %.url
	mkdir -p downloads
	curl --location '$(shell cat $<)' --output $@

downloads/%.tar.bz2: %.url
	mkdir -p downloads
	curl --location '$(shell cat $<)' --output $@

# Rules to extract tools. For simplicity we strip the first directory component because it varies.
build/gcc/bin/$(RISCV_COMPILER_PREFIX)gcc: downloads/gcc.tar.xz
	mkdir -p build/gcc
	tar --touch --directory build/gcc --strip-components=1 --extract --file downloads/gcc.tar.xz

build/linux/Makefile: downloads/linux.tar.xz
	mkdir -p build/linux
	tar --touch --directory build/linux --strip-components=1 --extract --file downloads/linux.tar.xz

build/xvisor/Makefile: downloads/xvisor.tar.xz
	mkdir -p build/xvisor
	tar --touch --directory build/xvisor --strip-components=1 --extract --file downloads/xvisor.tar.xz

build/opensbi/Makefile: downloads/opensbi.tar.xz
	mkdir -p build/opensbi
	tar --touch --directory build/opensbi --strip-components=1 --extract --file downloads/opensbi.tar.xz

build/busybox/Makefile: downloads/busybox.tar.bz2
	mkdir -p build/busybox
	tar --touch --directory build/busybox --strip-components=1 --extract --file downloads/busybox.tar.bz2

CROSS_COMPILE := $(shell pwd)/build/gcc/bin/$(RISCV_COMPILER_PREFIX)

# Rule to build the Linux kernel.
build/linux/arch/riscv/boot/Image: build/linux/Makefile build/gcc/bin/$(RISCV_COMPILER_PREFIX)gcc
	$(MAKE) -C build/linux CROSS_COMPILE=$(CROSS_COMPILE) ARCH=riscv defconfig
	$(MAKE) -C build/linux CROSS_COMPILE=$(CROSS_COMPILE) CONFIG_HVC_RISCV_SBI=y ARCH=riscv Image

# Rule to build Xvisor.
build/xvisor/build/vmm.bin: build/xvisor/Makefile build/gcc/bin/$(RISCV_COMPILER_PREFIX)gcc
	$(MAKE) -C build/xvisor CROSS_COMPILE=$(CROSS_COMPILE) ARCH=riscv generic-64b-defconfig
	$(MAKE) -C build/xvisor CROSS_COMPILE=$(CROSS_COMPILE) ARCH=riscv -j$(shell nproc)

build/fw_payload_linux.elf:  $(payload_linux)
build/fw_payload_xvisor.elf: $(payload_xvisor)

# Rule to build OpenSBI, with the payload embedded in it.
#
# FW_TEXT_START is 0 by default which doesn't leave space for the emulator bootloader.
# 0x80000000 is the default start of Spike's memory.
#
# Each payload gets its own OpenSBI output dir, otherwise they overwrite each other.
build/fw_payload_%.elf: build/opensbi/Makefile
	$(MAKE) -C build/opensbi O=$(abspath build/opensbi_$*) \
	  FW_TEXT_START=0x80000000 FW_PAYLOAD=y \
	  FW_PAYLOAD_PATH=$(abspath $(payload_$*)) \
	  PLATFORM=generic CROSS_COMPILE=$(CROSS_COMPILE)
	cp build/opensbi_$*/platform/generic/firmware/fw_payload.elf $@

# Build Busybox as a static binary.
#
# Traffic control (networking/tc.c) doesn't compile on some kernels.
# Ensure the Busybox uses the cross compiler.
build/busybox/.config: build/busybox/Makefile build/gcc/bin/$(RISCV_COMPILER_PREFIX)gcc
	CROSS_COMPILE=$(CROSS_COMPILE) $(MAKE) -C build/busybox defconfig
	sed 's/^.*CONFIG_STATIC is not set.*/CONFIG_STATIC=y/' -i build/busybox/.config
	sed 's/^CONFIG_TC=y/CONFIG_TC=n/' -i build/busybox/.config

# Prepare busybox install
build/busybox/_install/bin/busybox: build/busybox/.config
	CROSS_COMPILE=$(CROSS_COMPILE) $(MAKE) -C build/busybox
	CROSS_COMPILE=$(CROSS_COMPILE) $(MAKE) -C build/busybox install

# Prepare rootfs cpio.
$(ramfs): init-busybox build/busybox/_install/bin/busybox
	cp init-busybox build/busybox/_install/init
	cd build/busybox/_install && find . | cpio --create --format=newc --file ../rootfs.cpio
	cp build/busybox/rootfs.cpio $(ramfs)

# Path to Sail emulator.
SAIL_SIM ?= ../build/c_emulator/sail_riscv_sim

# Device tree without initramfs.

build/sail.dts: $(SAIL_SIM)
	mkdir -p build
	$(SAIL_SIM) --print-device-tree >$@

build/sail.dtb: build/sail.dts
	mkdir -p build
	dtc $< -o $@

# Device tree with initramfs.

build/sail_ramfs.dts: $(SAIL_SIM) $(linux_elf) $(ramfs)
	mkdir -p build
	$(SAIL_SIM) --initramfs $(ramfs) $(linux_elf) --print-device-tree >$@

build/sail_ramfs.dtb: build/sail_ramfs.dts
	mkdir -p build
	dtc $< -o $@

.PHONY: clean
clean:
	rm -rf build

.PHONY: distclean
distclean:
	rm -rf build
	rm -rf downloads

##### Running #####

# Number of instructions to run. Execution speed is around 300 kIPS, so this
# takes a while. Spike and QEMU are much faster.
#
# Linux: the image has no userspace, so there is no 'init' and it crashes there.
# Xvisor: the prompt appears but that's as far as it gets, the model can't read
# from stdin so there is no way to type anything.
limit_linux  := 20000000
limit_xvisor := 21000000

# Run with the Sail emulator from this repo.
%_sail: build/fw_payload_%.elf build/sail.dtb $(SAIL_SIM)
	$(SAIL_SIM) --show-times --inst-limit $(limit_$*) --device-tree-blob build/sail.dtb $<

# Boot with initramfs

linux_ramfs_sail: build/sail_ramfs.dtb $(linux_elf) $(ramfs) $(SAIL_SIM)
	$(SAIL_SIM) --initramfs $(ramfs) --device-tree-blob build/sail_ramfs.dtb $(linux_elf)

# Run the profiler. This requires gperftools and pprof:
#
#     git clone https://github.com/gperftools/gperftools
#     cd gperftools
#     # There's CMake support but unfortunately it's broken.
#     # See https://github.com/gperftools/gperftools/issues/1576
#     ./autogen.sh
#     ./configure
#     make -j4
#     sudo make install
#
#     go install github.com/google/pprof@latest
#
%_sail_profile: build/fw_payload_%.elf build/sail.dtb $(SAIL_SIM)
	rm -f build/prof_$*.out
	CPUPROFILE=build/prof_$*.out LD_PRELOAD=/usr/local/lib/libtcmalloc_and_profiler.so $(SAIL_SIM) --show-times --inst-limit $(limit_$*) --device-tree-blob build/sail.dtb $<
	pprof -http : build/prof_$*.out

# Run with Spike: https://github.com/riscv-software-src/riscv-isa-sim
%_spike: build/fw_payload_%.elf
	spike --instructions=$(limit_$*) $<

# Run with QEMU.
%_qemu: build/fw_payload_%.elf
	qemu-system-riscv64 -M virt -m 256M -nographic -bios $<
