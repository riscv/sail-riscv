function(string_upper_initial s result)
    string(SUBSTRING ${s} 0 1 initial)
    string(SUBSTRING ${s} 1 -1 remainder)
    string(TOUPPER ${initial} new_initial)
    string(CONCAT new ${new_initial} ${remainder})
    set("${result}" "${new}" PARENT_SCOPE)
endfunction()

# Common Sail flags for all commands.
set(sail_common
    # Don't allow implicit var declaration (like Python). This is
    # deprecated because it is error-prone.
    --strict-var
    # bits('n) is only well-formed if 'n >= 0.
    --strict-bitvector
    # Minimum required Sail compiler version.
    --require-version ${SAIL_REQUIRED_VER}
)

foreach (variant IN ITEMS "" "smt" "rocq" "rmem" "lean" "lem" "isabelle")

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
        "riscv_insts_zaamo.sail"
        "riscv_insts_zalrsc.sail"
        "riscv_insts_zca.sail"
        "riscv_insts_mext.sail"
        "riscv_insts_zicsr.sail"
        "riscv_insts_hext.sail"
        "riscv_insts_reserved_fence.sail"
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
        "riscv_insts_zawrs.sail"
        "riscv_insts_zvbb.sail"
        "riscv_insts_zvbc.sail"
        "riscv_insts_zvkg.sail"
        "riscv_insts_zvkned.sail"
        "riscv_insts_zvknhab.sail"
        "riscv_insts_zvksed.sail"
        "riscv_insts_zvksh.sail"
        # Zimop and Zcmop should be at the end so they can be overridden by earlier extensions
        "riscv_insts_zimop.sail"
        "riscv_insts_zcmop.sail"
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
        "riscv_sys_reservation.sail"
        "riscv_sys_control.sail"
    )

    set(sail_vm_srcs
        "riscv_vmem_pte.sail"
        "riscv_vmem_ptw.sail"
        "riscv_vmem_tlb.sail"
        "riscv_vmem.sail"
        "riscv_vmem_utils.sail"
    )

    set(prelude
        "prelude.sail"
        "riscv_errors.sail"
        "riscv_xlen.sail"
        "riscv_flen.sail"
        "riscv_vlen.sail"
        "prelude_mem_addrtype.sail"
        "prelude_mem_metadata.sail"
        "prelude_mem.sail"
        "arithmetic.sail"
        "rvfi_dii.sail"
        "rvfi_dii_v1.sail"
        "rvfi_dii_v2.sail"
    )

    set(sail_regs_srcs
        "riscv_csr_begin.sail"
        "riscv_callbacks.sail"
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
        "riscv_version.sail"
        "riscv_extensions.sail"
        "riscv_types_common.sail"
        "riscv_types_ext.sail"
        "riscv_types.sail"
        "riscv_vmem_types.sail"
        ${sail_regs_srcs}
        ${sail_sys_srcs}
        "riscv_platform.sail"
        "riscv_sstc.sail"
        "riscv_mem.sail"
        "riscv_inst_retire.sail"
        ${sail_vm_srcs}
        # Shared/common code for the cryptography extension.
        "riscv_types_kext.sail"
        "riscv_zvk_utils.sail"
    )

    set(sail_step_srcs
        "riscv_step_common.sail"
        "riscv_step_ext.sail"
        "riscv_decode_ext.sail"
        "riscv_fetch_rvfi.sail"
        "riscv_fetch.sail"
        "riscv_step.sail"
    )

    if (variant STREQUAL "rocq" OR variant STREQUAL "lean")
        list(APPEND sail_step_srcs
            "riscv_termination.sail"
        )
    endif()

    set(sail_cfg_srcs
        "riscv_validate_config.sail"
        "riscv_device_tree.sail"
    )

    set(sail_model_srcs
        "riscv_model.sail"
    )

    set(test_srcs
        "unit_tests/test_mstatus.sail"
    )

    # Final file list.
    set(sail_srcs
        ${sail_arch_srcs}
        ${sail_seq_inst_srcs}
        ${sail_step_srcs}
        ${sail_cfg_srcs}
        ${sail_model_srcs}
        ${test_srcs}
        "main.sail"
    )

    # Generate C code from Sail model
    if (NOT variant)
        set(c_model_no_ext "${CMAKE_BINARY_DIR}/sail_riscv_model")
        set(c_model "${c_model_no_ext}.c")
        set(c_model_header "${c_model_no_ext}.h")
        # JSON schema for configuration file.
        set(schema_file "${CMAKE_BINARY_DIR}/sail_riscv_config_schema.json")

        if (COVERAGE)
            set(branch_info_file "${c_model_no_ext}.branch_info")
            set(coverage_args "--c-coverage" ${branch_info_file})
        else()
            set(branch_info_file)
            set(coverage_args)
        endif()

        add_custom_command(
            DEPENDS ${sail_srcs}
            OUTPUT ${c_model} ${c_model_header} ${branch_info_file} ${schema_file}
            VERBATIM
            COMMENT "Building C code from Sail model"
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMAND
                ${SAIL_BIN}
                ${sail_common}
                # Output file (without extension).
                -o ${c_model_no_ext}
                # Generate a file containing information about all possible branches.
                # See https://github.com/rems-project/sail/blob/sail2/sailcov/README.md
                ${coverage_args}
                # Generate schema for configuration.
                --output-schema ${schema_file}

                # Optimisations.
                -O --Oconstant-fold
                # Cache Z3 results in z3_problems file to speed up incremental compilation.
                --memo-z3
                # Output C code.
                -c
                # Generate a C header too.
                --c-generate-header
                # Don't generate a main() function.
                --c-no-main
                # Extra #include's.
                --c-include riscv_prelude.h
                --c-include riscv_platform.h
                --c-include riscv_callbacks.h
                # Don't dead-code eliminate these functions.
                --c-preserve init_model
                --c-preserve try_step
                --c-preserve tick_clock
                --c-preserve force_pc
                --c-preserve generate_dts
                --c-preserve config_is_valid
                --c-preserve generate_canonical_isa_string
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
                --c-preserve rvfi_write
                --c-preserve rvfi_read
                --c-preserve rvfi_mem_exception
                --c-preserve rvfi_wX
                --c-preserve rvfi_trap
                # Input files.
                ${sail_srcs}
        )

        add_custom_target(generated_sail_riscv_model DEPENDS ${c_model} ${c_model_header})
        install(FILES ${schema_file}
            DESTINATION ${CMAKE_INSTALL_DATADIR}/${CMAKE_PROJECT_NAME}
        )
    endif()

    if (NOT variant)
        # Generate JSON snippets file.
        set(model_doc "sail_riscv_model.json")

        add_custom_command(
            DEPENDS ${sail_srcs}
            OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${model_doc}"
            VERBATIM
            COMMENT "Building documentation JSON from Sail model"
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMAND
                ${SAIL_BIN}
                ${sail_common}
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
                # Input files.
                ${sail_srcs}
        )

        add_custom_target(generated_sail_riscv_docs DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/${model_doc}")
    endif()

    if (variant)
        # Theorem prover backends require compile time configuration.
        foreach (arch IN ITEMS "rv32d" "rv64d")
            set(config_file "${CMAKE_SOURCE_DIR}/config/${arch}.json")

            if (variant STREQUAL "smt")
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
                        ${sail_common}
                        # Generate SMT files.
                        --smt
                        # The prefix of the output files.
                        -o "${CMAKE_CURRENT_BINARY_DIR}/model"
                        --config ${config_file}
                        # Input files.
                        ${sail_srcs}
                    COMMAND ${CMAKE_COMMAND} -E touch ${smt_stamp_file}
                )

                add_custom_target(generated_smt_${arch} DEPENDS ${smt_stamp_file})

                # Add a test for the SMT properties. Use --auto-smt is a bit
                # nicer than just running the generated SMT files through Z3
                # because Sail will convert counter-examples into nice Sail
                # values instead of raw SMT2. Or it will try to at least.
                # TODO: Currently we'll only test this on RV64D. It's quite
                # slow and there aren't any properties that depend on XLEN/FLEN
                # currently.
                if (arch STREQUAL rv64d)
                    add_test(
                        NAME smt_properties_${arch}
                        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                        COMMAND
                            ${SAIL_BIN}
                            ${sail_common}
                            # Generate SMT files.
                            --smt
                            # Also prove them.
                            --smt-auto
                            # Use Z3 rather than CBMC since we have it installed.
                            --smt-auto-solver z3
                            # The prefix of the output files.
                            -o "${CMAKE_CURRENT_BINARY_DIR}/model"
                            --config ${config_file}
                            # Input files.
                            ${sail_srcs}
                    )
                endif()
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
                        ${sail_common}
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
                        --config ${config_file}
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
                        ${sail_common}
                        --tofrominterp
                        --tofrominterp-lem
                        --tofrominterp-mwords
                        --tofrominterp-output-dir ${CMAKE_CURRENT_BINARY_DIR}
                        # The prefix of the output files.
                        -o "rmem_${arch}"
                        --config ${config_file}
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
                        ${sail_common}
                        --marshal
                        # The prefix of the output files.
                        -o "rmem_${arch}"
                        --config ${config_file}
                        # Input files.
                        ${sail_srcs}
                )

                add_custom_target(generated_rmem_${arch} DEPENDS
                    "rmem_${arch}.lem"
                    "rmem_${arch}_toFromInterp2.ml"
                    "rmem_${arch}.defs"
                )
            endif()

            # Build Rocq (formerly Coq) definitions.
            if (variant STREQUAL "rocq")
                add_custom_command(
                    DEPENDS ${sail_srcs}
                    VERBATIM
                    OUTPUT "${CMAKE_BINARY_DIR}/rocq/${arch}.v" "${CMAKE_BINARY_DIR}/rocq/${arch}_types.v"
                    COMMENT "Building Rocq definitions from Sail model (${arch})"
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    COMMAND
                        ${SAIL_BIN}
                        ${sail_common}
                        --dcoq-undef-axioms
                        --coq
                        --coq-lib riscv_extras
                        --coq-lib mem_metadata
                        --coq-output-dir "${CMAKE_BINARY_DIR}/rocq"
                        # The prefix of the output files.
                        -o "${arch}"
                        --config ${config_file}
                        # Input files.
                        ${sail_srcs}
                )
                add_custom_command(
                    DEPENDS build_rocq_common "${CMAKE_BINARY_DIR}/rocq/${arch}.v" "${CMAKE_BINARY_DIR}/rocq/${arch}_types.v"
                    VERBATIM
                    OUTPUT "${CMAKE_BINARY_DIR}/rocq/${arch}.vo" "${CMAKE_BINARY_DIR}/rocq/${arch}_types.vo"
                    COMMENT "Building Rocq definitions from Sail model (${arch})"
                    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/rocq"
                    COMMAND
                        coqc
                        -R . Riscv
                        "${arch}_types.v"
                    COMMAND
                        coqc
                        -R . Riscv
                        "${arch}.v"
                )
                add_custom_target(generated_rocq_${arch} DEPENDS "${CMAKE_BINARY_DIR}/rocq/${arch}.v")
                add_custom_target(build_rocq_${arch} DEPENDS "${CMAKE_BINARY_DIR}/rocq/${arch}.vo")
            endif()

            # Build Lean definitions
            if (variant STREQUAL "lean")
                string(TOUPPER ${arch} arch_uppercase)
                set(lean_sail_common
                    --config ${config_file}
                    --lean
                    --memo-z3
                    --lean-output-dir ${CMAKE_CURRENT_BINARY_DIR}
                    --lean-force-output
                    --lean-non-beq-type instruction
                )
                set(lean_sail_default
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
                )
                add_custom_command(
                    DEPENDS
                        ${sail_srcs}
                        ${config_file}
                        ${CMAKE_SOURCE_DIR}/handwritten_support/RiscvExtrasExecutable.lean
                    VERBATIM
                    OUTPUT "lean_${arch_uppercase}.lean"
                    COMMENT "Building Lean definitions from Sail model (${arch})"
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    COMMAND
                        ${SAIL_BIN}
                        ${sail_common}
                        ${lean_sail_common}
                        ${lean_sail_default}
                        ${sail_srcs}
                )
                add_custom_command(
                    DEPENDS
                        ${sail_srcs}
                        ${config_file}
                        ${CMAKE_SOURCE_DIR}/handwritten_support/RiscvExtras.lean
                    VERBATIM
                    OUTPUT "lean_executable_${arch_uppercase}.lean"
                    COMMENT "Building executable Lean definitions from Sail model (${arch})"
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    COMMAND
                        ${SAIL_BIN}
                        ${sail_common}
                        ${lean_sail_common}
                        ${lean_sail_executable}
                        ${sail_srcs}
                )

                add_custom_target(generated_lean_${arch} DEPENDS "lean_${arch_uppercase}.lean")
                add_custom_target(generated_lean_executable_${arch} DEPENDS "lean_executable_${arch_uppercase}.lean")
            endif()

            # Build Lem definitions, en route to Isabelle or HOL4.
            if (variant STREQUAL "lem")
                string_upper_initial("${arch}" arch_thy)
                add_custom_command(
                    DEPENDS ${sail_srcs} ${config_file}
                    VERBATIM
                    OUTPUT "${arch}.lem" "${arch}_types.lem" "${CMAKE_BINARY_DIR}/isabelle/${arch}/${arch_thy}_lemmas.thy"
                    COMMENT "Building Lem definitions from Sail model (${arch})"
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    COMMAND
                        ${SAIL_BIN}
                        ${sail_common}
                        --lem
                        --lem-lib Riscv_extras
                        --lem-lib Riscv_extras_fdext
                        --lem-output-dir ${CMAKE_CURRENT_BINARY_DIR}
                        # Sail also produces a lemmas file just for Isabelle
                        --isa-output-dir "${CMAKE_BINARY_DIR}/isabelle/${arch}"
                        # The prefix of the output files.
                        -o "${arch}"
                        --config ${config_file}
                        # Input files.
                        ${sail_srcs}
                    COMMAND
                        echo
                        "declare {isabelle} rename field sync_exception_ext = sync_exception_ext_exception"
                        >>
                        ${CMAKE_CURRENT_BINARY_DIR}/${arch}_types.lem

                )
                add_custom_target(generated_lem_${arch} DEPENDS "${arch}.lem")
            endif()

            # Build Isabelle definitions from Lem
            if (variant STREQUAL "isabelle")
                string_upper_initial("${arch}" arch_thy)
                file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/isabelle/${arch}")
                add_custom_command(
                    DEPENDS "${arch}.lem" "${arch}_types.lem"
                    VERBATIM
                    OUTPUT "${CMAKE_BINARY_DIR}/isabelle/${arch}/${arch_thy}.thy" "${CMAKE_BINARY_DIR}/isabelle/${arch}/${arch_thy}_types.thy"
                    COMMENT "Building Isabelle definitions from Lem definitions (${arch})"
                    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                    COMMAND
                        lem
                        -no_lifting_toplevel_match_for ${arch_thy}_types.ast
                        -wl ign
                        -isa
                        -outdir ${CMAKE_BINARY_DIR}/isabelle/${arch}
                        -lib Sail=${sail_dir}/src/gen_lib
                        ${CMAKE_SOURCE_DIR}/handwritten_support/riscv_extras.lem
                        ${CMAKE_SOURCE_DIR}/handwritten_support/riscv_extras_fdext.lem
                        ${arch}_types.lem
                        ${arch}.lem
                    COMMAND
                        sed
                        -e "s/datatype ast/datatype (plugins only: size) ast/"
                        -e "s/record( 'asidlen, 'valen, 'palen, 'ptelen) TLB_Entry/record (overloaded) ( 'asidlen, 'valen, 'palen, 'ptelen) TLB_Entry/"
                        "${CMAKE_BINARY_DIR}/isabelle/${arch}/${arch_thy}_types.thy"
                        >
                        "${CMAKE_BINARY_DIR}/isabelle/${arch}/${arch_thy}_types.thy.new"
                    COMMAND
                        mv
                        "${CMAKE_BINARY_DIR}/isabelle/${arch}/${arch_thy}_types.thy.new"
                        "${CMAKE_BINARY_DIR}/isabelle/${arch}/${arch_thy}_types.thy"
                    COMMAND
                        sed
                        -e "s/by pat_completeness auto/by pat_completeness (auto intro!: let_cong bind_cong result.case_cong)/"
                        -e "s/WriteRAM_Meta addr width meta/WriteRAM_Meta addr width ()/"
                        "${CMAKE_BINARY_DIR}/isabelle/${arch}/${arch_thy}.thy"
                        >
                        "${CMAKE_BINARY_DIR}/isabelle/${arch}/${arch_thy}.thy.new"
                    COMMAND
                        mv
                        "${CMAKE_BINARY_DIR}/isabelle/${arch}/${arch_thy}.thy.new"
                        "${CMAKE_BINARY_DIR}/isabelle/${arch}/${arch_thy}.thy"
                    COMMAND
                        sed
                        "s/%ARCH%/${arch_thy}/"
                        "${CMAKE_SOURCE_DIR}/handwritten_support/ROOT.in"
                        >
                        "${CMAKE_BINARY_DIR}/isabelle/${arch}/ROOT"
                )
                add_custom_target(generated_isabelle_${arch} DEPENDS "${CMAKE_BINARY_DIR}/isabelle/${arch}/${arch_thy}.thy")
            endif()
        endforeach()
    endif()
endforeach()
