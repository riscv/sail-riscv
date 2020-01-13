all: riscv_config2sail

.PHONY: FORCE
FORCE:

# Attempt to work with either sail from opam or built from repo in SAIL_DIR
ifneq ($(SAIL_DIR),)
# Use sail repo in SAIL_DIR
SAIL:=$(SAIL_DIR)/sail
export SAIL_DIR
else
# Use sail from opam package
SAIL_DIR:=$(shell opam config var sail:share)
SAIL:=sail
endif
SAIL_LIB_DIR:=$(SAIL_DIR)/lib
export SAIL_LIB_DIR
SAIL_SRC_DIR:=$(SAIL_DIR)/src

riscv_config2sail: FORCE
	dune build src/riscv_config2sail.exe
	ln -sf _build/default/src/riscv_config2sail.exe riscv_config2sail

test: riscv_config2sail
	./riscv_config2sail -i examples/template_isa_checked.yaml -p examples/template_platform_checked.yaml -o test.sail
	$(SAIL) -c -O -o test sail/riscv_config_types.sail test.sail

clean:
	dune clean
	rm -f riscv_config2sail

