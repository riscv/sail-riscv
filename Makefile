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

PLATFORM_OCAML_SRCS = $(addprefix ocaml/,platform.ml platform_impl.ml platform_main.ml)

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
SAIL_SRC_DIR:=$(SAIL_DIR)/src

#Coq BBV library hopefully checked out in directory above us
BBV_DIR?=../bbv

C_WARNINGS ?=
#-Wall -Wextra -Wno-unused-label -Wno-unused-parameter -Wno-unused-but-set-variable -Wno-unused-function
C_INCS = $(addprefix c/,riscv_prelude.h riscv_platform_impl.h riscv_platform.h)
C_SRCS = $(addprefix c/,riscv_prelude.c riscv_platform_impl.c riscv_platform.c)

C_FLAGS = -I $(SAIL_LIB_DIR) -I c
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

all: ocaml/platform c/riscv_sim riscv_isa riscv_coq

.PHONY: all riscv_coq riscv_isa

check: $(SAIL_SRCS) model/main.sail Makefile
	$(SAIL) $(SAIL_FLAGS) $(SAIL_SRCS) model/main.sail

interpret: $(SAIL_SRCS) model/main.sail
	$(SAIL) -i $(SAIL_FLAGS) $(SAIL_SRCS) model/main.sail

cgen: $(SAIL_SRCS) model/main.sail
	$(SAIL) -cgen $(SAIL_FLAGS) $(SAIL_SRCS) model/main.sail

generated_models/ocaml/riscv.ml: $(SAIL_SRCS) Makefile
	$(SAIL) $(SAIL_FLAGS) -ocaml -ocaml-nobuild -ocaml_build_dir generated_models/ocaml -o riscv $(SAIL_SRCS)

ocaml/_sbuild/platform_main.native: generated_models/ocaml/riscv.ml ocaml/_tags $(PLATFORM_OCAML_SRCS) Makefile
	mkdir -p ocaml/_sbuild
	cp ocaml/_tags $(PLATFORM_OCAML_SRCS) generated_models/ocaml/*.ml ocaml/_sbuild
	cd ocaml/_sbuild && ocamlbuild -use-ocamlfind platform_main.native

ocaml/_sbuild/coverage.native: ocaml/_sbuild/riscv.ml ocaml/_tags.bisect $(PLATFORM_OCAML_SRCS) Makefile
	cp $(PLATFORM_OCAML_SRCS) generated_models/ocaml/*.ml ocaml/_sbuild
	cp ocaml/_tags.bisect ocaml/_sbuild/_tags
	cd ocaml/_sbuild && ocamlbuild -use-ocamlfind platform_main.native && cp -L platform_main.native coverage.native

ocaml/platform: ocaml/_sbuild/platform_main.native
	rm -f $@ && ln -s _sbuild/platform_main.native $@

ocaml/coverage: ocaml/_sbuild/coverage.native
	rm -f ocaml/platform && ln -s _sbuild/coverage.native ocaml/platform # since the test scripts runs this file
	rm -rf bisect*.out bisect ocaml/coverage
	./test/run_tests.sh # this will generate bisect*.out files in this directory
	mkdir ocaml/bisect && mv bisect*.out bisect/
	mkdir ocaml/coverage && bisect-ppx-report -html ocaml/coverage/ -I ocaml/_sbuild/ bisect/bisect*.out

gcovr:
	gcovr -r . --html --html-detail -o index.html

generated_models/ocaml/riscv_duopod_ocaml: model/prelude.sail model/riscv_duopod.sail
	$(SAIL) $(SAIL_FLAGS) -ocaml -ocaml_build_dir generated_models/ocaml -o riscv_duopod_ocaml $^

ocaml/tracecmp: ocaml/tracecmp.ml
	ocamlfind ocamlopt -annot -linkpkg -package unix $^ -o $@

generated_models/c/riscv.c: $(SAIL_SRCS) model/main.sail Makefile
	$(SAIL) $(SAIL_FLAGS) -O -memo_z3 -c -c_include riscv_prelude.h -c_include riscv_platform.h $(SAIL_SRCS) model/main.sail 1> $@

c/riscv_c: generated_models/c/riscv.c $(C_INCS) $(C_SRCS) Makefile
	gcc $(C_WARNINGS) $(C_FLAGS) $< $(C_SRCS) $(SAIL_LIB_DIR)/*.c -lgmp -lz -I $(SAIL_LIB_DIR) -o $@

generated_models/c/riscv_model.c: $(SAIL_SRCS) model/main.sail Makefile
	$(SAIL) $(SAIL_FLAGS) -O -memo_z3 -c -c_include riscv_prelude.h -c_include riscv_platform.h -c_no_main $(SAIL_SRCS) model/main.sail 1> $@

c/riscv_sim: generated_models/c/riscv_model.c c/riscv_sim.c $(C_INCS) $(C_SRCS) $(CPP_SRCS) Makefile
	gcc -g $(C_WARNINGS) $(C_FLAGS) $< c/riscv_sim.c $(C_SRCS) $(SAIL_LIB_DIR)/*.c $(C_LIBS) -o $@

generated_models/c/riscv_rvfi_model.c: $(SAIL_RVFI_SRCS) model/main_rvfi.sail Makefile
	$(SAIL) $(SAIL_FLAGS) -O -memo_z3 -c -c_include riscv_prelude.h -c_include riscv_platform.h -c_no_main $(SAIL_RVFI_SRCS) model/main_rvfi.sail | sed '/^[[:space:]]*$$/d' > $@

c/riscv_rvfi: generated_models/c/riscv_rvfi_model.c c/riscv_sim.c $(C_INCS) $(C_SRCS) $(CPP_SRCS) Makefile
	gcc -g $(C_WARNINGS) $(C_FLAGS) $< -DRVFI_DII c/riscv_sim.c $(C_SRCS) $(SAIL_LIB_DIR)/*.c $(C_LIBS) -o $@

latex: $(SAIL_SRCS) Makefile
	$(SAIL) -latex -latex_prefix sail -o sail_ltx $(SAIL_SRCS)

generated_models/lem/riscv_duopod.lem: $(addprefix model/, prelude.sail riscv_duopod.sail)
	$(SAIL) $(SAIL_FLAGS) -lem -lem_output_dir generated_models/lem -lem_mwords -lem_lib Riscv_extras -o riscv_duopod $^
generated_models/isabelle/Riscv_duopod.thy: generated_models/lem/riscv_duopod.lem lem/riscv_extras.lem
	lem -isa -outdir generated_models/isabelle -lib Sail=$(SAIL_SRC_DIR)/lem_interp -lib Sail=$(SAIL_SRC_DIR)/gen_lib \
		lem/riscv_extras.lem \
		generated_models/lem/riscv_duopod_types.lem \
		generated_models/lem/riscv_duopod.lem

riscv_duopod: generated_models/ocaml/riscv_duopod_ocaml generated_models/isabelle/Riscv_duopod.thy

riscv_isa: generated_models/isabelle/Riscv.thy

generated_models/lem/riscv.lem: $(SAIL_SRCS) Makefile
	$(SAIL) $(SAIL_FLAGS) -lem -lem_output_dir generated_models/lem -o riscv -lem_mwords -lem_lib Riscv_extras $(SAIL_SRCS)

generated_models/lem/riscv_sequential.lem: $(SAIL_SRCS) Makefile
	$(SAIL_DIR)/sail -lem -lem_output_dir generated_models/lem -lem_sequential -o riscv_sequential -lem_mwords -lem_lib Riscv_extras_sequential $(SAIL_SRCS)

generated_models/isabelle/Riscv.thy: generated_models/lem/riscv.lem lem/riscv_extras.lem Makefile
	lem -isa -outdir generated_models/isabelle -lib Sail=$(SAIL_SRC_DIR)/lem_interp -lib Sail=$(SAIL_SRC_DIR)/gen_lib \
		lem/riscv_extras.lem \
		generated_models/lem/riscv_types.lem \
		generated_models/lem/riscv.lem
	sed -i 's/datatype ast/datatype (plugins only: size) ast/' generated_models/isabelle/Riscv_types.thy

generated_models/hol4/riscvScript.sml: generated_models/lem/riscv.lem lem/riscv_extras.lem
	lem -hol -outdir generated_models/hol4 -lib $(SAIL_LIB_DIR)/hol -i $(SAIL_LIB_DIR)/hol/sail2_prompt_monad.lem -i $(SAIL_LIB_DIR)/hol/sail2_prompt.lem \
	    -lib $(SAIL_DIR)/src/lem_interp -lib $(SAIL_DIR)/src/gen_lib \
		lem/riscv_extras.lem \
		generated_models/lem/riscv_types.lem \
		generated_models/lem/riscv.lem

$(addprefix generated_models/hol4/,riscvTheory.uo riscvTheory.ui): generated_models/hol4/riscvScript.sml
	(cd generated_models/hol4 && Holmake riscvTheory.uo)

COQ_LIBS = -R $(BBV_DIR)/theories bbv -R $(SAIL_LIB_DIR)/coq Sail -R coq '' -R generated_models/coq ''

riscv_coq: $(addprefix generated_models/coq/,riscv.v riscv_types.v)

$(addprefix generated_models/coq/,riscv.v riscv_types.v): $(SAIL_COQ_SRCS) Makefile
	$(SAIL) $(SAIL_FLAGS) -dcoq_undef_axioms -coq -coq_output_dir generated_models/coq -o riscv -coq_lib riscv_extras $(SAIL_COQ_SRCS)
$(addprefix generated_models/coq/,riscv_duopod.v riscv_duopod_types.v): model/prelude.sail model/riscv_duopod.sail
	$(SAIL) $(SAIL_FLAGS) -dcoq_undef_axioms -coq -coq_output_dir generated_models/coq -o riscv_duopod -coq_lib riscv_extras $^
%.vo: %.v
	coqc $(COQ_LIBS) $<
generated_models/coq/riscv.vo: generated_models/coq/riscv_types.vo coq/riscv_extras.vo
generated_models/coq/riscv_duopod.vo: generated_models/coq/riscv_duopod_types.vo coq/riscv_extras.vo

# we exclude prelude.sail here, most code there should move to sail lib
#LOC_FILES:=$(SAIL_SRCS) main.sail
#include $(SAIL_DIR)/etc/loc.mk

clean:
	-rm -rf generated_models/ocaml/* generated_models/c/*
	-rm -rf generated_models/lem/* generated_models/isabelle/* generated_models/hol4/* generated_models/coq/*
	-rm -f c/riscv_sim c/riscv_rvfi
	-rm -rf ocaml/_sbuild ocaml/_build ocaml/platform ocaml/tracecmp
	-rm -f *.gcno *.gcda
	-Holmake cleanAll
	ocamlbuild -clean
