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

build/opensbi/Makefile: downloads/opensbi.tar.xz
	mkdir -p build/opensbi
	tar --touch --directory build/opensbi --strip-components=1 --extract --file downloads/opensbi.tar.xz

CROSS_COMPILE := $(shell pwd)/build/gcc/bin/$(RISCV_COMPILER_PREFIX)

# Rule to build OpenSBI, with the Linux kernel embedded in it.
#
# FW_TEXT_START is 0 by default which doesn't leave space for the emulator bootloader.
# 0x80000000 is the default start of Spike's memory.
$(elf): build/opensbi/Makefile build/gcc/bin/$(RISCV_COMPILER_PREFIX)gcc
	$(MAKE) -C build/opensbi FW_TEXT_START=0x80000000 FW_PAYLOAD=y PLATFORM=generic CROSS_COMPILE=$(CROSS_COMPILE)
	cp build/opensbi/build/platform/generic/firmware/fw_payload.elf $(elf)

build/sail.dtb: sail.dts
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
LIMIT_INSTRUCTIONS := 50000000

# Run with the Sail emulator from this repo.
.PHONY: sail
sail: build/sail.dtb $(elf)
	../../build/c_emulator/riscv_sim_rv64d --no-trace -p -l $(LIMIT_INSTRUCTIONS) --device-tree-blob build/sail.dtb $(elf)

# Run with Spike: https://github.com/riscv-software-src/riscv-isa-sim
# This can achieve around 9 MIPS.
.PHONY: spike
spike: $(elf)
	spike --instructions=$(LIMIT_INSTRUCTIONS) $(elf)

# Run with QEMU. This is over 1 GIPS.
.PHONY: qemu
qemu: $(elf)
	qemu-system-riscv64 -M virt -m 256M -nographic -bios $(elf)
