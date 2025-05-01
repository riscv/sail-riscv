.PHONY: clean all dist-clean spike sail qemu

elf := build/fw_payload.elf

all: $(elf)

RISCV_COMPILER_URL ?= https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/2025.01.20/riscv64-glibc-ubuntu-24.04-gcc-nightly-2025.01.20-nightly.tar.xz
LINUX_VERSION ?= 6.14.4
OPENSBI_VERSION ?= 1.6

src/gcc.tar.xz:
	mkdir -p src
ifeq (, $(wildcard src/gcc.tar.xz))
	curl -L $(RISCV_COMPILER_URL) -o src/gcc.tar.xz
endif

build/riscv/bin/riscv64-unknown-linux-gnu-gcc: src/gcc.tar.xz
	mkdir -p build
	tar --touch --directory build --extract --file src/gcc.tar.xz

src/linux.tar.xz:
	mkdir -p src
ifeq (, $(wildcard src/linux.tar.xz))
	curl -L https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$(LINUX_VERSION).tar.xz -o src/linux.tar.xz
endif

build/linux-$(LINUX_VERSION)/Makefile: src/linux.tar.xz
	mkdir -p build
	tar --touch --directory build --extract --file src/linux.tar.xz

src/opensbi.tar.xz:
	mkdir -p src
ifeq (, $(wildcard src/opensbi.tar.xz))
	curl -L https://github.com/riscv-software-src/opensbi/archive/refs/tags/v$(OPENSBI_VERSION).tar.gz -o src/opensbi.tar.xz
endif

build/opensbi-$(OPENSBI_VERSION)/Makefile: src/opensbi.tar.xz
	mkdir -p build
	tar --touch --directory build --extract --file src/opensbi.tar.xz

CROSS_COMPILE := $(shell pwd)/build/riscv/bin/riscv64-unknown-linux-gnu-

# Number of instructions to run.
LIMIT_INSTRUCTIONS ?= 1500000

build/linux-$(LINUX_VERSION)/arch/riscv/boot/Image: build/linux-$(LINUX_VERSION)/Makefile build/riscv/bin/riscv64-unknown-linux-gnu-gcc
	$(MAKE) -C build/linux-$(LINUX_VERSION) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=riscv defconfig
	$(MAKE) -C build/linux-$(LINUX_VERSION) CROSS_COMPILE=$(CROSS_COMPILE) CONFIG_HVC_RISCV_SBI=y ARCH=riscv Image

# FW_TEXT_START is 0 by default which doesn't leave space for the emulator bootloader.
# 0x80000000 is the default start of Spike's memory.
build/opensbi-$(OPENSBI_VERSION)/build/platform/generic/firmware/fw_payload.elf: build/opensbi-$(OPENSBI_VERSION)/Makefile build/linux-$(LINUX_VERSION)/arch/riscv/boot/Image build/riscv/bin/riscv64-unknown-linux-gnu-gcc
	$(MAKE) -C build/opensbi-$(OPENSBI_VERSION) FW_TEXT_START=0x80000000 FW_PAYLOAD=y FW_PAYLOAD_PATH=../linux-$(LINUX_VERSION)/arch/riscv/boot/Image PLATFORM=generic CROSS_COMPILE=$(CROSS_COMPILE)

$(elf): build/opensbi-$(OPENSBI_VERSION)/build/platform/generic/firmware/fw_payload.elf
	cp build/opensbi-$(OPENSBI_VERSION)/build/platform/generic/firmware/fw_payload.elf $(elf)

sail.dtb: sail.dts
	dtc < sail.dts -o sail.dtb

spike: $(elf)
	spike --instructions=$(LIMIT_INSTRUCTIONS) $(elf)

# Run on Sail.
sail: sail.dtb $(elf)
	../../build/c_emulator/riscv_sim_rv64d --no-trace -p -l $(LIMIT_INSTRUCTIONS) --device-tree-blob sail.dtb -t /dev/stdout $(elf)

qemu: $(elf)
	qemu-system-riscv64 -M virt -m 256M -nographic -bios $(elf)

clean:
	rm -rf build
	rm -f sail.dtb

dist-clean:
	rm -rf build
	rm -f sail.dtb
	rm -rf src
