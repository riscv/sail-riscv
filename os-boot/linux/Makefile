##### Compilation #####

RISCV_COMPILER_PREFIX := riscv64-buildroot-linux-gnu-

# This is the final bootable OpenSBI + Linux image.
elf := build/fw_payload.elf

.PHONY: all
all: $(elf)

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

build/opensbi/Makefile: downloads/opensbi.tar.xz
	mkdir -p build/opensbi
	tar --touch --directory build/opensbi --strip-components=1 --extract --file downloads/opensbi.tar.xz

CROSS_COMPILE := $(shell pwd)/build/gcc/bin/$(RISCV_COMPILER_PREFIX)

# Rule to build the Linux kernel.
build/linux/arch/riscv/boot/Image: build/linux/Makefile build/gcc/bin/$(RISCV_COMPILER_PREFIX)gcc
	$(MAKE) -C build/linux CROSS_COMPILE=$(CROSS_COMPILE) ARCH=riscv defconfig
	$(MAKE) -C build/linux CROSS_COMPILE=$(CROSS_COMPILE) CONFIG_HVC_RISCV_SBI=y ARCH=riscv Image

# Rule to build OpenSBI, with the Linux kernel embedded in it.
#
# FW_TEXT_START is 0 by default which doesn't leave space for the emulator bootloader.
# 0x80000000 is the default start of Spike's memory.
$(elf): build/opensbi/Makefile build/linux/arch/riscv/boot/Image build/gcc/bin/$(RISCV_COMPILER_PREFIX)gcc
	$(MAKE) -C build/opensbi FW_TEXT_START=0x80000000 FW_PAYLOAD=y FW_PAYLOAD_PATH=../linux/arch/riscv/boot/Image PLATFORM=generic CROSS_COMPILE=$(CROSS_COMPILE)
	cp build/opensbi/build/platform/generic/firmware/fw_payload.elf $(elf)

# Path to Sail emulator.
SAIL_SIM ?= ../../build/c_emulator/sail_riscv_sim

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

# Number of instructions to run. The image does not include userspace; there
# is no 'init' available, so it will crash at that point. It takes about
# 200 million instructions to get to that point. Execution speed is around
# 300 kIPS so it takes around 10 minutes. Spike and QEMU are much faster.
LIMIT_INSTRUCTIONS := 20000000

# Run with the Sail emulator from this repo.
.PHONY: sail
sail: build/sail.dtb $(elf) $(SAIL_SIM)
	$(SAIL_SIM) --show-times --inst-limit $(LIMIT_INSTRUCTIONS) --device-tree-blob build/sail.dtb $(elf)

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
.PHONY: sail_profile
sail_profile: build/sail.dtb $(elf) $(SAIL_SIM)
	rm -f build/prof.out
	CPUPROFILE=build/prof.out LD_PRELOAD=/usr/local/lib/libtcmalloc_and_profiler.so $(SAIL_SIM) --show-times --inst-limit $(LIMIT_INSTRUCTIONS) --device-tree-blob build/sail.dtb $(elf)
	pprof -http : build/prof.out

# Run with Spike: https://github.com/riscv-software-src/riscv-isa-sim
.PHONY: spike
spike: $(elf)
	spike --instructions=$(LIMIT_INSTRUCTIONS) $(elf)

# Run with QEMU.
.PHONY: qemu
qemu: $(elf)
	qemu-system-riscv64 -M virt -m 256M -nographic -bios $(elf)
