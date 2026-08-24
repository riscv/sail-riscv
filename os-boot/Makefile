##### Compilation #####

RISCV_COMPILER_PREFIX := riscv64-buildroot-linux-gnu-

# Payloads that get embedded into OpenSBI to make the final bootable image.
payload_linux  := build/linux/arch/riscv/boot/Image
payload_xvisor := build/xvisor/build/vmm.bin

.PHONY: all linux xvisor
all: linux xvisor

linux: build/fw_payload_linux.elf
xvisor: build/fw_payload_xvisor.elf

# Generic rule to download tools.
downloads/%.tar.xz: %.url
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

# Path to Sail emulator.
SAIL_SIM ?= ../build/c_emulator/sail_riscv_sim

build/sail.dts: $(SAIL_SIM)
	mkdir -p build
	$(SAIL_SIM) --print-device-tree >$@

build/sail.dtb: build/sail.dts
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
%_sail: build/sail.dtb build/fw_payload_%.elf $(SAIL_SIM)
	$(SAIL_SIM) --show-times --inst-limit $(limit_$*) --device-tree-blob build/sail.dtb build/fw_payload_$*.elf

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
%_sail_profile: build/sail.dtb build/fw_payload_%.elf $(SAIL_SIM)
	rm -f build/prof_$*.out
	CPUPROFILE=build/prof_$*.out LD_PRELOAD=/usr/local/lib/libtcmalloc_and_profiler.so $(SAIL_SIM) --show-times --inst-limit $(limit_$*) --device-tree-blob build/sail.dtb build/fw_payload_$*.elf
	pprof -http : build/prof_$*.out

# Run with Spike: https://github.com/riscv-software-src/riscv-isa-sim
%_spike: build/fw_payload_%.elf
	spike --instructions=$(limit_$*) build/fw_payload_$*.elf

# Run with QEMU.
%_qemu: build/fw_payload_%.elf
	qemu-system-riscv64 -M virt -m 256M -nographic -bios build/fw_payload_$*.elf
