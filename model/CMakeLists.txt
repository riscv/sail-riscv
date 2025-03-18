foreach (xlen IN ITEMS 32 64)
    foreach (flen IN ITEMS 32 64)
        foreach (variant IN ITEMS "" "rvfi" "coq" "rmem" "lean")
            set(arch "rv${xlen}")
            if (flen EQUAL 32)
                string(APPEND arch "f")
            else()
                string(APPEND arch "d")
            endif()
            if (variant)
                string(APPEND arch "_${variant}")
            endif()

            set(sail_xlen
                "riscv_xlen${xlen}.sail"
                "riscv_xlen.sail"
            )

            # TODO: Unfortunately 32 or 64 bit float support is a compile time.
            # See https://github.com/riscv/sail-riscv/issues/348
            if (flen EQUAL 64)
                set(sail_flen "riscv_flen_D.sail")
            else()
                set(sail_flen "riscv_flen_F.sail")
            endif()
            list(APPEND sail_flen "riscv_flen.sail")

            set(sail_vlen "riscv_vlen.sail")

            # Instruction sources, depending on target
            set(sail_check_srcs
                "riscv_addr_checks_common.sail"
                "riscv_addr_checks.sail"
                "riscv_misa_ext.sail"
            )

            set(vext_srcs
                "riscv_insts_vext_utils.sail"
                "riscv_insts_vext_fp_utils.sail"
                "riscv_insts_vext_vset.sail"
                "riscv_insts_vext_arith.sail"
                "riscv_insts_vext_fp.sail"
                "riscv_insts_vext_mem.sail"
                "riscv_insts_vext_mask.sail"
                "riscv_insts_vext_vm.sail"
                "riscv_insts_vext_fp_vm.sail"
                "riscv_insts_vext_red.sail"
                "riscv_insts_vext_fp_red.sail"
            )

            set(sail_default_inst
                "riscv_insts_base.sail"
                "riscv_insts_zifencei.sail"
                "riscv_insts_aext.sail"
                "riscv_insts_zca.sail"
                "riscv_insts_mext.sail"
                "riscv_insts_zicsr.sail"
                "riscv_insts_hints.sail"
                "riscv_insts_fext.sail"
                "riscv_insts_zcf.sail"
                "riscv_insts_dext.sail"
                "riscv_insts_zcd.sail"
                "riscv_insts_svinval.sail"
                "riscv_insts_zba.sail"
                "riscv_insts_zbb.sail"
                "riscv_insts_zbc.sail"
                "riscv_insts_zbs.sail"
                "riscv_insts_zcb.sail"
                "riscv_insts_zfh.sail"
                # Zfa needs to be added after fext, dext and Zfh (as it needs
                # definitions from those)
                "riscv_insts_zfa.sail"
                "riscv_insts_zkn.sail"
                "riscv_insts_zks.sail"
                "riscv_insts_zbkb.sail"
                "riscv_insts_zbkx.sail"
                "riscv_insts_zicond.sail"
                ${vext_srcs}
                "riscv_insts_zicbom.sail"
                "riscv_insts_zicboz.sail"
            )

            if (variant STREQUAL "rmem")
                set(sail_seq_inst
                    ${sail_default_inst}
                    "riscv_jalr_rmem.sail"
                    "riscv_insts_rmem.sail"
                )
            else()
                set(sail_seq_inst
                    ${sail_default_inst}
                    "riscv_jalr_seq.sail"
                )
            endif()

            set(sail_seq_inst_srcs
                "riscv_insts_begin.sail"
                ${sail_seq_inst}
                "riscv_insts_end.sail"
                "riscv_csr_end.sail"
            )

            set(sail_sys_srcs
                "riscv_vext_control.sail"
                "riscv_sys_exceptions.sail"
                "riscv_sync_exception.sail"
                "riscv_zihpm.sail"
                "riscv_sscofpmf.sail"
                "riscv_zkr_control.sail"
                "riscv_zicntr_control.sail"
                "riscv_softfloat_interface.sail"
                "riscv_fdext_regs.sail"
                "riscv_fdext_control.sail"
                "riscv_smcntrpmf.sail"
                "riscv_sys_control.sail"
            )

            set(sail_vm_srcs
                "riscv_vmem_pte.sail"
                "riscv_vmem_ptw.sail"
                "riscv_vmem_tlb.sail"
                "riscv_vmem.sail"
            )

            set(prelude
                "prelude.sail"
                "riscv_errors.sail"
                ${sail_xlen}
                ${sail_flen}
                ${sail_vlen}
                "prelude_mem_addrtype.sail"
                "prelude_mem_metadata.sail"
                "prelude_mem.sail"
            )

            if (variant STREQUAL "rvfi")
                list(APPEND prelude "rvfi_dii.sail")
            endif()

            set(sail_regs_srcs
                "riscv_csr_begin.sail"
                "riscv_reg_type.sail"
                "riscv_freg_type.sail"
                "riscv_regs.sail"
                "riscv_pc_access.sail"
                "riscv_sys_regs.sail"
                "riscv_pmp_regs.sail"
                "riscv_pmp_control.sail"
                "riscv_ext_regs.sail"
                ${sail_check_srcs}
                "riscv_vreg_type.sail"
                "riscv_vext_regs.sail"
            )

            set(sail_arch_srcs
                ${prelude}
                "riscv_extensions.sail"
                "riscv_types_common.sail"
                "riscv_types_ext.sail"
                "riscv_types.sail"
                "riscv_vmem_types.sail"
                ${sail_regs_srcs}
                ${sail_sys_srcs}
                "riscv_platform.sail"
                "riscv_mem.sail"
                ${sail_vm_srcs}
                # Shared/common code for the cryptography extension.
                "riscv_types_kext.sail"
            )

            if (variant STREQUAL "rvfi")
                set(riscv_step_ext "riscv_step_rvfi.sail")
                set(riscv_fetch "riscv_fetch_rvfi.sail")
            else()
                set(riscv_step_ext "riscv_step_ext.sail")
                set(riscv_fetch "riscv_fetch.sail")
            endif()

            set(sail_step_srcs
                "riscv_step_common.sail"
                ${riscv_step_ext}
                "riscv_decode_ext.sail"
                ${riscv_fetch}
                "riscv_step.sail"
            )

            if (variant STREQUAL "coq")
                list(APPEND sail_step_srcs
                    "riscv_termination.sail"
                )
            endif()

            # Final file list.
            set(sail_srcs
                ${sail_arch_srcs}
                ${sail_seq_inst_srcs}
                ${sail_step_srcs}
                "main.sail"
            )

            # Convert to absolute paths, so we can run

            # Generate C code from Sail model with & without RVFI-DII support.
            if (NOT variant OR variant STREQUAL "rvfi")
                set(c_model_no_ext "${CMAKE_BINARY_DIR}/riscv_model_${arch}")
                set(c_model "${c_model_no_ext}.c")

                if (COVERAGE)
                    set(branch_info_file "${c_model_no_ext}.branch_info")
                    set(coverage_args "--c-coverage" ${branch_info_file})
                else()
                    set(branch_info_file)
                    set(coverage_args)
                endif()

                add_custom_command(
                    DEPENDS ${sail_srcs}
                    OUTPUT ${c_model} ${branch_info_file}
                    VERBATIM
                    COMMENT "Building C code from Sail model (${arch})"
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    COMMAND
                        ${SAIL_BIN}
                        # Output file (without extension).
                        -o ${c_model_no_ext}
                        # Generate a file containing information about all possible branches.
                        # See https://github.com/rems-project/sail/blob/sail2/sailcov/README.md
                        ${coverage_args}
                        # Don't allow implicit var declaration (like Python). This is
                        # deprecated because it is error-prone.
                        --strict-var
                        # bits('n) is only well-formed if 'n >= 0.
                        --strict-bitvector
                        # Minimum required Sail compiler version.
                        --require-version ${SAIL_REQUIRED_VER}
                        # Optimisations.
                        -O --Oconstant-fold
                        # Cache Z3 results in z3_problems file to speed up incremental compilation.
                        --memo-z3
                        # Output C code.
                        -c
                        # Don't generate a main() function.
                        --c-no-main
                        # Extra #include's.
                        --c-include riscv_prelude.h
                        --c-include riscv_platform.h
                        # Don't dead-code eliminate these functions. These should match the
                        # ones used from riscv_sail.h
                        --c-preserve init_model
                        --c-preserve step
                        --c-preserve tick_clock
                        --c-preserve tick_platform
                        # Preserve RVFI functions.
                        --c-preserve rvfi_set_instr_packet
                        --c-preserve rvfi_get_cmd
                        --c-preserve rvfi_get_insn
                        --c-preserve rvfi_get_v2_trace_size
                        --c-preserve rvfi_get_v2_support_packet
                        --c-preserve rvfi_get_exec_packet_v1
                        --c-preserve rvfi_get_exec_packet_v2
                        --c-preserve rvfi_get_mem_data
                        --c-preserve rvfi_get_int_data
                        --c-preserve rvfi_zero_exec_packet
                        --c-preserve rvfi_halt_exec_packet
                        --c-preserve print_instr_packet
                        --c-preserve print_rvfi_exec
                        # Input files.
                        ${sail_srcs}
                )

                add_custom_target(generated_model_${arch} DEPENDS ${c_model})
            endif()

            if (NOT variant)
                # Generate JSON snippets file.
                set(model_doc "riscv_model_${arch}.json")

                add_custom_command(
                    DEPENDS ${sail_srcs}
                    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${model_doc}"
                    VERBATIM
                    COMMENT "Building documentation JSON from Sail model (${arch})"
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    COMMAND
                        ${SAIL_BIN}
                        # Generate JSON documentation file.
                        --doc
                        # Format to interpret comments as. You can also use 'asciidoc'
                        # in which case it will interpret them as Markdown and output them
                        # as Asciidoc, but there's a bug in the Sail compiler so it can't
                        # parse the Markdown and it doesn't seem to output the comments
                        # anyway.
                        --doc-format identity
                        # Don't pretty-print the JSON output. It's too big to be readable anyway.
                        --doc-compact
                        # Actually embed the code snippets in the JSON as plain text rather
                        # than referencing them. The other option is base64.
                        --doc-embed plain
                        # The directory that the JSON will be saved in.
                        -o ${CMAKE_CURRENT_BINARY_DIR}
                        # The name of the JSON file.
                        --doc-bundle ${model_doc}
                        # Minimum required Sail compiler version.
                        --require-version ${SAIL_REQUIRED_VER}
                        # Input files.
                        ${sail_srcs}
                )

                add_custom_target(generated_docs_${arch} DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/${model_doc}")

                # Generate smtlib2 code from the Sail code.
                # A separate .smt2 file is created for each $property or $counterexample.
                # Since the true output files are unknown we need to manually
                # generate a file to indicate that we have run this command.
                set(smt_stamp_file "${CMAKE_CURRENT_BINARY_DIR}/smt_${arch}.stamp")
                add_custom_command(
                    DEPENDS ${sail_srcs}
                    VERBATIM
                    OUTPUT ${smt_stamp_file}
                    COMMENT "Building smtlib2 from Sail model (${arch})"
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    COMMAND
                        ${SAIL_BIN}
                        # Generate SMT files.
                        --smt
                        # The prefix of the output files.
                        -o "${CMAKE_CURRENT_BINARY_DIR}/model"
                        # Minimum required Sail compiler version.
                        --require-version ${SAIL_REQUIRED_VER}
                        # Input files.
                        ${sail_srcs}
                    COMMAND ${CMAKE_COMMAND} -E touch ${smt_stamp_file}
                )

                add_custom_target(generated_smt_${arch} DEPENDS ${smt_stamp_file})
            endif()

            if (variant STREQUAL "rmem")
                # Generate riscv.lem, riscv_toFromInterp2.ml and riscv.defs
                # These are used for "rmem".
                add_custom_command(
                    DEPENDS ${sail_srcs}
                    VERBATIM
                    OUTPUT "rmem_${arch}.lem"
                    COMMENT "Building rmem lem from Sail model (${arch})"
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    COMMAND
                        ${SAIL_BIN}
                        # Generate lem files.
                        --lem
                        --lem-mwords
                        --lem-lib Riscv_extras
                        --lem-lib Riscv_extras_fdext
                        --lem-lib Mem_metadata
                        # Output dir for Lem.
                        --lem-output-dir ${CMAKE_CURRENT_BINARY_DIR}
                        # Output dir for ISabelle auxiliary theories.
                        # We do not need the Isabelle .thy files, but sail always generates them.
                        --isa-output-dir ${CMAKE_CURRENT_BINARY_DIR}
                        # The prefix of the output files.
                        -o "lem_${arch}"
                        # Minimum required Sail compiler version.
                        --require-version ${SAIL_REQUIRED_VER}
                        # Input files.
                        ${sail_srcs}
                )
                add_custom_command(
                    DEPENDS ${sail_srcs}
                    VERBATIM
                    OUTPUT "rmem_${arch}_toFromInterp2.ml"
                    COMMENT "Building rmem toFromInterp2.ml from Sail model (${arch})"
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    COMMAND
                        ${SAIL_BIN}
                        --tofrominterp
                        --tofrominterp-lem
                        --tofrominterp-mwords
                        --tofrominterp-output-dir ${CMAKE_CURRENT_BINARY_DIR}
                        # The prefix of the output files.
                        -o "rmem_${arch}"
                        # Minimum required Sail compiler version.
                        --require-version ${SAIL_REQUIRED_VER}
                        # Input files.
                        ${sail_srcs}
                )
                add_custom_command(
                    DEPENDS ${sail_srcs}
                    VERBATIM
                    OUTPUT "rmem_${arch}.defs"
                    COMMENT "Building rmem defs from Sail model (${arch})"
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    COMMAND
                        ${SAIL_BIN}
                        --marshal
                        # The prefix of the output files.
                        -o "rmem_${arch}"
                        # Minimum required Sail compiler version.
                        --require-version ${SAIL_REQUIRED_VER}
                        # Input files.
                        ${sail_srcs}
                )

                add_custom_target(generated_rmem_${arch} DEPENDS
                    "rmem_${arch}.lem"
                    "rmem_${arch}_toFromInterp2.ml"
                    "rmem_${arch}.defs"
                )
            endif()

            # Build Coq definitions.
            if (variant STREQUAL "coq")
                add_custom_command(
                    DEPENDS ${sail_srcs}
                    VERBATIM
                    OUTPUT "coq_${arch}.?"
                    COMMENT "Building Coq definitions from Sail model (${arch})"
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    COMMAND
                        ${SAIL_BIN}
                        -dcoq_undef_axioms
                        --coq
                        --coq-lib riscv_extras
                        --coq-lib mem_metadata
                        --coq-output-dir ${CMAKE_CURRENT_BINARY_DIR}
                        # The prefix of the output files.
                        -o "coq_${arch}"
                        # Minimum required Sail compiler version.
                        --require-version ${SAIL_REQUIRED_VER}
                        # Input files.
                        ${sail_srcs}
                )
                add_custom_target(generated_coq_${arch} DEPENDS "coq_${arch}.?")
            endif()

            # Build Lean definitions
            if (variant STREQUAL "lean")
                string(TOUPPER ${arch} arch_uppercase)
                add_custom_command(
                    DEPENDS ${sail_srcs}
                    VERBATIM
                    OUTPUT "lean_${arch_uppercase}.lean"
                    COMMENT "Building Lean definitions from Sail model (${arch})"
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    COMMAND
                        ${SAIL_BIN}
                        --lean
                        --memo-z3
                        --require-version ${SAIL_REQUIRED_VER}
                        --lean-output-dir ${CMAKE_CURRENT_BINARY_DIR}
                        --lean-force-output
                        --lean-noncomputable
                        --lean-noncomputable-function encdec_forwards
                        --lean-noncomputable-function encdec_backwards
                        --lean-noncomputable-function encdec_forwards_matches
                        --lean-noncomputable-function encdec_backwards_matches
                        --lean-noncomputable-function encdec_compressed_forwards
                        --lean-noncomputable-function encdec_compressed_backwards
                        --lean-noncomputable-function encdec_compressed_forwards_matches
                        --lean-noncomputable-function encdec_compressed_backwards_matches
                        --lean-import-file ../handwritten_support/RiscvExtras.lean
                        -o "Lean_${arch_uppercase}"
                        ${sail_srcs}
                )

                add_custom_target(generated_lean_${arch} DEPENDS "lean_${arch_uppercase}.lean")
            endif()
        endforeach()
    endforeach()
endforeach()
