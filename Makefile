SAIL_SEQ_INST  = riscv.sail riscv_jalr_seq.sail
SAIL_RMEM_INST = riscv.sail riscv_jalr_rmem.sail

SAIL_SEQ_INST_SRCS  = riscv_insts_begin.sail $(SAIL_SEQ_INST) riscv_insts_end.sail
SAIL_RMEM_INST_SRCS = riscv_insts_begin.sail $(SAIL_RMEM_INST) riscv_insts_end.sail

# non-instruction sources
SAIL_OTHER_SRCS = prelude.sail riscv_types.sail riscv_sys.sail riscv_platform.sail riscv_mem.sail riscv_vmem.sail
SAIL_OTHER_RVFI_SRCS = prelude.sail rvfi_dii.sail riscv_types.sail riscv_sys.sail riscv_platform.sail riscv_mem.sail riscv_vmem.sail

SAIL_SRCS      = $(addprefix model/,$(SAIL_OTHER_SRCS) $(SAIL_SEQ_INST_SRCS)  riscv_step.sail riscv_analysis.sail)
SAIL_RMEM_SRCS = $(addprefix model/,$(SAIL_OTHER_SRCS) $(SAIL_RMEM_INST_SRCS) riscv_step.sail riscv_analysis.sail)
SAIL_RVFI_SRCS = $(addprefix model/,$(SAIL_OTHER_RVFI_SRCS) $(SAIL_SEQ_INST_SRCS)  riscv_step.sail riscv_analysis.sail)
SAIL_COQ_SRCS  = $(addprefix model/,$(SAIL_OTHER_SRCS) $(SAIL_SEQ_INST_SRCS)  riscv_termination.sail riscv_analysis.sail)

PLATFORM_OCAML_SRCS = $(addprefix ocaml_emulator/,platform.ml platform_impl.ml riscv_ocaml_sim.ml)

#Attempt to work with either sail from opam or built from repo in SAIL_DIR
ifneq ($(SAIL_DIR),)
# Use sail repo in SAIL_DIR
SAIL:=$(SAIL_DIR)/sail
export SAIL_DIR
else
# Use sail from opam package
SAIL_DIR=$(shell opam config var sail:share)
SAIL:=sail
endif
SAIL_LIB_DIR:=$(SAIL_DIR)/lib
export SAIL_LIB_DIR
SAIL_SRC_DIR:=$(SAIL_DIR)/src

LEM_DIR?=$(shell opam config var lem:share)
export LEM_DIR

#Coq BBV library hopefully checked out in directory above us
BBV_DIR?=../bbv

C_WARNINGS ?=
#-Wall -Wextra -Wno-unused-label -Wno-unused-parameter -Wno-unused-but-set-variable -Wno-unused-function
C_INCS = $(addprefix c_emulator/,riscv_prelude.h riscv_platform_impl.h riscv_platform.h)
C_SRCS = $(addprefix c_emulator/,riscv_prelude.c riscv_platform_impl.c riscv_platform.c)

C_FLAGS = -I $(SAIL_LIB_DIR) -I c_emulator
C_LIBS  = -lgmp -lz

# The C simulator can be built to be linked against Spike for tandem-verification.
# This needs the C bindings to Spike from https://github.com/SRI-CSL/l3riscv
# TV_SPIKE_DIR in the environment should point to the top-level dir of the L3
# RISC-V, containing the built C bindings to Spike.
# RISCV should be defined if TV_SPIKE_DIR is.
ifneq (,$(TV_SPIKE_DIR))
C_FLAGS += -I $(TV_SPIKE_DIR)/src/cpp -DENABLE_SPIKE
C_LIBS  += -L $(TV_SPIKE_DIR) -ltv_spike -Wl,-rpath=$(TV_SPIKE_DIR)
C_LIBS  += -L $(RISCV)/lib -lfesvr -lriscv -Wl,-rpath=$(RISCV)/lib
endif

ifneq (,$(COVERAGE))
C_FLAGS += --coverage -O1
SAIL_FLAGS += -Oconstant_fold
else
C_FLAGS += -O2
endif

all: ocaml_emulator/riscv_ocaml_sim c_emulator/riscv_sim riscv_isa riscv_coq riscv_hol

.PHONY: all riscv_coq riscv_isa

check: $(SAIL_SRCS) model/main.sail Makefile
	$(SAIL) $(SAIL_FLAGS) $(SAIL_SRCS) model/main.sail

interpret: $(SAIL_SRCS) model/main.sail
	$(SAIL) -i $(SAIL_FLAGS) $(SAIL_SRCS) model/main.sail

cgen: $(SAIL_SRCS) model/main.sail
	$(SAIL) -cgen $(SAIL_FLAGS) $(SAIL_SRCS) model/main.sail

generated_definitions/ocaml/riscv.ml: $(SAIL_SRCS) Makefile
	mkdir -p generated_definitions/ocaml
	$(SAIL) $(SAIL_FLAGS) -ocaml -ocaml-nobuild -ocaml_build_dir generated_definitions/ocaml -o riscv $(SAIL_SRCS)

ocaml_emulator/_sbuild/riscv_ocaml_sim.native: generated_definitions/ocaml/riscv.ml ocaml_emulator/_tags $(PLATFORM_OCAML_SRCS) Makefile
	mkdir -p ocaml_emulator/_sbuild
	cp ocaml_emulator/_tags $(PLATFORM_OCAML_SRCS) generated_definitions/ocaml/*.ml ocaml_emulator/_sbuild
	cd ocaml_emulator/_sbuild && ocamlbuild -use-ocamlfind riscv_ocaml_sim.native

ocaml_emulator/_sbuild/coverage.native: generated_definitions/ocaml/riscv.ml ocaml_emulator/_tags.bisect $(PLATFORM_OCAML_SRCS) Makefile
	mkdir -p ocaml_emulator/_sbuild
	cp $(PLATFORM_OCAML_SRCS) generated_definitions/ocaml/*.ml ocaml_emulator/_sbuild
	cp ocaml_emulator/_tags.bisect ocaml_emulator/_sbuild/_tags
	cd ocaml_emulator/_sbuild && ocamlbuild -use-ocamlfind riscv_ocaml_sim.native && cp -L riscv_ocaml_sim.native coverage.native

ocaml_emulator/riscv_ocaml_sim: ocaml_emulator/_sbuild/riscv_ocaml_sim.native
	rm -f $@ && ln -s _sbuild/riscv_ocaml_sim.native $@

ocaml_emulator/coverage: ocaml_emulator/_sbuild/coverage.native
	rm -f ocaml_emulator/riscv_ocaml_sim && ln -s ocaml_emulator/_sbuild/coverage.native ocaml_emulator/riscv_ocaml_sim # since the test scripts runs this file
	rm -rf bisect*.out bisect ocaml_emulator/coverage
	./test/run_tests.sh # this will generate bisect*.out files in this directory
	mkdir ocaml_emulator/bisect && mv bisect*.out bisect/
	mkdir ocaml_emulator/coverage && bisect-ppx-report -html ocaml_emulator/coverage/ -I ocaml_emulator/_sbuild/ bisect/bisect*.out

gcovr:
	gcovr -r . --html --html-detail -o index.html

generated_definitions/ocaml/riscv_duopod_ocaml: model/prelude.sail model/riscv_duopod.sail
	mkdir -p generated_definitions/ocaml
	$(SAIL) $(SAIL_FLAGS) -ocaml -ocaml_build_dir generated_definitions/ocaml -o riscv_duopod_ocaml $^

ocaml_emulator/tracecmp: ocaml_emulator/tracecmp.ml
	ocamlfind ocamlopt -annot -linkpkg -package unix $^ -o $@

generated_definitions/c/riscv.c: $(SAIL_SRCS) model/main.sail Makefile
	mkdir -p generated_definitions/c
	$(SAIL) $(SAIL_FLAGS) -O -memo_z3 -c -c_include riscv_prelude.h -c_include riscv_platform.h $(SAIL_SRCS) model/main.sail 1> $@

c_emulator/riscv_c: generated_definitions/c/riscv.c $(C_INCS) $(C_SRCS) Makefile
	gcc $(C_WARNINGS) $(C_FLAGS) $< $(C_SRCS) $(SAIL_LIB_DIR)/*.c -lgmp -lz -I $(SAIL_LIB_DIR) -o $@

generated_definitions/c/riscv_model.c: $(SAIL_SRCS) model/main.sail Makefile
	mkdir -p generated_definitions/c
	$(SAIL) $(SAIL_FLAGS) -O -memo_z3 -c -c_include riscv_prelude.h -c_include riscv_platform.h -c_no_main $(SAIL_SRCS) model/main.sail 1> $@

c_emulator/riscv_sim: generated_definitions/c/riscv_model.c c_emulator/riscv_sim.c $(C_INCS) $(C_SRCS) $(CPP_SRCS) Makefile
	gcc -g $(C_WARNINGS) $(C_FLAGS) $< c_emulator/riscv_sim.c $(C_SRCS) $(SAIL_LIB_DIR)/*.c $(C_LIBS) -o $@

generated_definitions/c/riscv_rvfi_model.c: $(SAIL_RVFI_SRCS) model/main_rvfi.sail Makefile
	mkdir -p generated_definitions/c
	$(SAIL) $(SAIL_FLAGS) -O -memo_z3 -c -c_include riscv_prelude.h -c_include riscv_platform.h -c_no_main $(SAIL_RVFI_SRCS) model/main_rvfi.sail | sed '/^[[:space:]]*$$/d' > $@

c_emulator/riscv_rvfi: generated_definitions/c/riscv_rvfi_model.c c_emulator/riscv_sim.c $(C_INCS) $(C_SRCS) $(CPP_SRCS) Makefile
	gcc -g $(C_WARNINGS) $(C_FLAGS) $< -DRVFI_DII c_emulator/riscv_sim.c $(C_SRCS) $(SAIL_LIB_DIR)/*.c $(C_LIBS) -o $@

latex: $(SAIL_SRCS) Makefile
	mkdir -p generated_definitions/latex
	$(SAIL) -latex -latex_prefix sail -o generated_definitions/latex $(SAIL_SRCS)

generated_definitions/isabelle/ROOT: handwritten_support/ROOT
	mkdir -p generated_definitions/isabelle
	cp handwritten_support/ROOT generated_definitions/isabelle/

generated_definitions/lem/riscv_duopod.lem: $(addprefix model/, prelude.sail riscv_duopod.sail)
	mkdir -p generated_definitions/lem
	$(SAIL) $(SAIL_FLAGS) -lem -lem_output_dir generated_definitions/lem -isa_output_dir generated_definitions/isabelle -lem_mwords -lem_lib Riscv_extras -o riscv_duopod $^
generated_definitions/isabelle/Riscv_duopod.thy: generated_definitions/isabelle/ROOT generated_definitions/lem/riscv_duopod.lem handwritten_support/riscv_extras.lem
	lem -isa -outdir generated_definitions/isabelle -lib Sail=$(SAIL_SRC_DIR)/lem_interp -lib Sail=$(SAIL_SRC_DIR)/gen_lib \
		handwritten_support/riscv_extras.lem \
		generated_definitions/lem/riscv_duopod_types.lem \
		generated_definitions/lem/riscv_duopod.lem

riscv_duopod: generated_definitions/ocaml/riscv_duopod_ocaml generated_definitions/isabelle/Riscv_duopod.thy

riscv_isa: generated_definitions/isabelle/Riscv.thy
riscv_isa_build: riscv_isa
ifeq ($(wildcard $(LEM_DIR)/isabelle-lib),)
	$(error Lem directory not found. Please set the LEM_DIR environment variable)
endif
ifeq ($(wildcard $(SAIL_LIB_DIR)/isabelle),)
	$(error lib directory of Sail not found. Please set the SAIL_LIB_DIR environment variable)
endif
	isabelle build -b -d $(LEM_DIR)/isabelle-lib -d $(SAIL_LIB_DIR)/isabelle -d generated_definitions/isabelle Sail-RISC-V

generated_definitions/lem/riscv.lem: $(SAIL_SRCS) Makefile
	mkdir -p generated_definitions/lem
	$(SAIL) $(SAIL_FLAGS) -lem -lem_output_dir generated_definitions/lem -isa_output_dir generated_definitions/isabelle -o riscv -lem_mwords -lem_lib Riscv_extras $(SAIL_SRCS)

generated_definitions/lem/riscv_sequential.lem: $(SAIL_SRCS) Makefile
	mkdir -p generated_definitions/lem
	$(SAIL_DIR)/sail -lem -lem_output_dir generated_definitions/lem -isa_output_dir generated_definitions/isabelle -lem_sequential -o riscv_sequential -lem_mwords -lem_lib Riscv_extras_sequential $(SAIL_SRCS)

generated_definitions/isabelle/Riscv.thy: generated_definitions/isabelle/ROOT generated_definitions/lem/riscv.lem handwritten_support/riscv_extras.lem Makefile
	lem -isa -outdir generated_definitions/isabelle -lib Sail=$(SAIL_SRC_DIR)/lem_interp -lib Sail=$(SAIL_SRC_DIR)/gen_lib \
		handwritten_support/riscv_extras.lem \
		generated_definitions/lem/riscv_types.lem \
		generated_definitions/lem/riscv.lem
	sed -i 's/datatype ast/datatype (plugins only: size) ast/' generated_definitions/isabelle/Riscv_types.thy

generated_definitions/hol4/Holmakefile: handwritten_support/Holmakefile
	mkdir -p generated_definitions/hol4
	cp handwritten_support/Holmakefile generated_definitions/hol4

generated_definitions/hol4/riscvScript.sml: generated_definitions/hol4/Holmakefile generated_definitions/lem/riscv.lem handwritten_support/riscv_extras.lem
	lem -hol -outdir generated_definitions/hol4 -lib $(SAIL_LIB_DIR)/hol -i $(SAIL_LIB_DIR)/hol/sail2_prompt_monad.lem -i $(SAIL_LIB_DIR)/hol/sail2_prompt.lem \
	    -lib $(SAIL_DIR)/src/lem_interp -lib $(SAIL_DIR)/src/gen_lib \
		handwritten_support/riscv_extras.lem \
		generated_definitions/lem/riscv_types.lem \
		generated_definitions/lem/riscv.lem

$(addprefix generated_definitions/hol4/,riscvTheory.uo riscvTheory.ui): generated_definitions/hol4/Holmakefile generated_definitions/hol4/riscvScript.sml
ifeq ($(wildcard $(LEM_DIR)/hol-lib),)
	$(error Lem directory not found. Please set the LEM_DIR environment variable)
endif
ifeq ($(wildcard $(SAIL_LIB_DIR)/hol),)
	$(error lib directory of Sail not found. Please set the SAIL_LIB_DIR environment variable)
endif
	(cd generated_definitions/hol4 && Holmake riscvTheory.uo)

riscv_hol: generated_definitions/hol4/riscvScript.sml
riscv_hol_build: generated_definitions/hol4/riscvTheory.uo

COQ_LIBS = -R $(BBV_DIR)/theories bbv -R $(SAIL_LIB_DIR)/coq Sail -R coq '' -R generated_definitions/coq '' -R handwritten_support ''

riscv_coq: $(addprefix generated_definitions/coq/,riscv.v riscv_types.v)
riscv_coq_build: generated_definitions/coq/riscv.vo

$(addprefix generated_definitions/coq/,riscv.v riscv_types.v): $(SAIL_COQ_SRCS) Makefile
	mkdir -p generated_definitions/coq
	$(SAIL) $(SAIL_FLAGS) -dcoq_undef_axioms -coq -coq_output_dir generated_definitions/coq -o riscv -coq_lib riscv_extras $(SAIL_COQ_SRCS)
$(addprefix generated_definitions/coq/,riscv_duopod.v riscv_duopod_types.v): model/prelude.sail model/riscv_duopod.sail
	mkdir -p generated_definitions/coq
	$(SAIL) $(SAIL_FLAGS) -dcoq_undef_axioms -coq -coq_output_dir generated_definitions/coq -o riscv_duopod -coq_lib riscv_extras $^

%.vo: %.v
ifeq ($(wildcard $(BBV_DIR)/theories),)
	$(error BBV directory not found. Please set the BBV_DIR environment variable)
endif
ifeq ($(wildcard $(SAIL_LIB_DIR)/coq),)
	$(error lib directory of Sail not found. Please set the SAIL_LIB_DIR environment variable)
endif
	coqc $(COQ_LIBS) $<

generated_definitions/coq/riscv.vo: generated_definitions/coq/riscv_types.vo handwritten_support/riscv_extras.vo
generated_definitions/coq/riscv_duopod.vo: generated_definitions/coq/riscv_duopod_types.vo handwritten_support/riscv_extras.vo

# we exclude prelude.sail here, most code there should move to sail lib
#LOC_FILES:=$(SAIL_SRCS) main.sail
#include $(SAIL_DIR)/etc/loc.mk

clean:
	-rm -rf generated_definitions/ocaml/* generated_definitions/c/*
	-rm -rf generated_definitions/lem/* generated_definitions/isabelle/* generated_definitions/hol4/* generated_definitions/coq/*
	-rm -f c_emulator/riscv_sim c_emulator/riscv_rvfi
	-rm -rf ocaml_emulator/_sbuild ocaml_emulator/_build ocaml_emulator/riscv_ocaml_sim ocaml_emulator/tracecmp
	-rm -f *.gcno *.gcda
	-Holmake cleanAll
	ocamlbuild -clean
