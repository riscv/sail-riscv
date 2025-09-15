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
    # 2 ^ 'n is only well-formed if 'n >= 0.
    --strict-exponentials
    # Minimum required Sail compiler version.
    --require-version ${SAIL_REQUIRED_VER}
)

set(project_file "riscv.sail_project")

# Reconfigure if the project file changes.
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${project_file})

execute_process(
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMAND
        ${SAIL_BIN}
        ${project_file}
        --require-version ${SAIL_REQUIRED_VER}
        # include riscv_termination.sail in the list of dependencies
        --variable "TERMINATION_FILE = true"
        --all-modules
        --list-files
    OUTPUT_VARIABLE sail_list_files
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY
)

separate_arguments(sail_srcs UNIX_COMMAND "${sail_list_files}")

############# C #############

# Generate C code from Sail model
set(c_model_no_ext "${CMAKE_BINARY_DIR}/sail_riscv_model")
set(c_model "${c_model_no_ext}.cpp")
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
    DEPENDS ${sail_srcs} ${project_file}
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
        # Output C++ code.
        --cpp
        # Make the output Model class derive from a PlatformInterface class
        # Its public members become protected in Model.
        --cpp-derive-from "protected PlatformInterface"
        # Don't generate a main() function.
        --c-no-main
        # Extra #include's.
        --c-header-include riscv_platform_if.h
        --c-include riscv_softfloat.h
        # Don't dead-code eliminate these functions.
        --c-preserve init_model
        --c-preserve init_boot_requirements
        --c-preserve try_step
        --c-preserve tick_clock
        --c-preserve enable_htif
        --c-preserve set_pc_reset_address
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
        --all-modules
        ${project_file}
)

add_custom_target(generated_sail_riscv_model DEPENDS ${c_model} ${c_model_header})
install(FILES ${schema_file}
    DESTINATION ${CMAKE_INSTALL_DATADIR}/${CMAKE_PROJECT_NAME}
)

############# JSON #############

# Generate JSON snippets file.
set(model_doc "sail_riscv_model.json")

add_custom_command(
    DEPENDS ${sail_srcs} ${project_file}
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
        --all-modules
        ${project_file}
)

add_custom_target(generated_sail_riscv_docs DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/${model_doc}")

############# HTML #############

# Generate HTML tgz
set(model_html_tgz "sail_riscv_html.tgz")
set(model_html_out "html_docs")

add_custom_command(
    DEPENDS ${sail_srcs} ${project_file}
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${model_html_out}"
    VERBATIM
    COMMENT "Building HTML from Sail model"
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    # Ensure the output directory exists to work around
    # a bug in Sail 0.19.1 that got fixed in
    # https://github.com/rems-project/sail/commit/cbd2c49b8953378685cb135306ed4a3bcde07824
    COMMAND
        cmake -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/${model_html_out}"
    COMMAND
        ${SAIL_BIN}
        ${sail_common}
        # Generate HTML
        --html
        -o "${CMAKE_CURRENT_BINARY_DIR}/${model_html_out}"
        # Input files
        --all-modules
        ${project_file}
)
# Create tgz with the build directory as working directory.
add_custom_command(
    DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/${model_html_out}"
    OUTPUT ${model_html_tgz}
    VERBATIM
    COMMENT "Creating HTML tgz bundle"
    COMMAND
        cmake -E tar cvfz ${model_html_tgz} ${model_html_out}
)

add_custom_target(generated_html_tgz DEPENDS ${model_html_tgz})
add_dependencies(generated_sail_riscv_docs generated_html_tgz)

############# Formal #############

# Theorem prover backends require compile time configuration.
foreach (xlen IN ITEMS 32 64)
    # Use ELEN=XLEN.
    set(config_file "${CMAKE_BINARY_DIR}/config/rv${xlen}d_v256_e${xlen}.json")
    # This name is used in a lot of places so it excludes the `_v256_e{xlen}`
    # for backwards compatibility.
    set(arch "rv${xlen}d")

    ############# SMT #############

    # Generate smtlib2 code from the Sail code.
    # A separate .smt2 file is created for each $property or $counterexample.
    # Since the true output files are unknown we need to manually
    # generate a file to indicate that we have run this command.
    set(smt_stamp_file "${CMAKE_CURRENT_BINARY_DIR}/smt_${arch}.stamp")
    add_custom_command(
        DEPENDS ${sail_srcs} ${project_file}
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
            --all-modules
            ${project_file}
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

    ############# RMEM #############

    # Generate riscv.lem, riscv_toFromInterp2.ml and riscv.defs
    # These are used for "rmem".
    add_custom_command(
        DEPENDS ${sail_srcs} ${project_file}
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
            --all-modules
            ${project_file}
    )
    add_custom_command(
        DEPENDS ${sail_srcs} ${project_file}
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
            --all-modules
            ${project_file}
    )
    add_custom_command(
        DEPENDS ${sail_srcs} ${project_file}
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
            --all-modules
            ${project_file}
    )

    add_custom_target(generated_rmem_${arch} DEPENDS
        "rmem_${arch}.lem"
        "rmem_${arch}_toFromInterp2.ml"
        "rmem_${arch}.defs"
    )

    ############# Rocq #############

    # Build Rocq (formerly Coq) definitions.
    add_custom_command(
        DEPENDS ${sail_srcs} ${project_file}
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
            --all-modules
            --variable "TERMINATION_FILE = true"
            ${project_file}
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

    ############# Lean #############

    # Build Lean definitions
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
    set(lean_sail_executable
        --lean-import-file ../handwritten_support/RiscvExtrasExecutable.lean
        -o "Lean_${arch_uppercase}_executable"
    )
    add_custom_command(
        DEPENDS
            ${sail_srcs}
            ${project_file}
            ${config_file}
            ${CMAKE_SOURCE_DIR}/handwritten_support/RiscvExtras.lean
        VERBATIM
        OUTPUT "Lean_${arch_uppercase}/Lean${arch_uppercase}.lean"
        COMMENT "Building Lean definitions from Sail model (${arch})"
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMAND
            ${SAIL_BIN}
            ${sail_common}
            ${lean_sail_common}
            ${lean_sail_default}
            --all-modules
            --variable "TERMINATION_FILE = true"
            ${project_file}
    )
    add_custom_command(
        DEPENDS
            ${sail_srcs}
            ${project_file}
            ${config_file}
            ${CMAKE_SOURCE_DIR}/handwritten_support/RiscvExtrasExecutable.lean
        VERBATIM
        OUTPUT "Lean_${arch_uppercase}_executable/Lean${arch_uppercase}Executable.lean"
        COMMENT "Building executable Lean definitions from Sail model (${arch})"
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMAND
            ${SAIL_BIN}
            ${sail_common}
            ${lean_sail_common}
            ${lean_sail_executable}
            --all-modules
            --variable "TERMINATION_FILE = true"
            ${project_file}
    )

    add_custom_target(generated_lean_${arch} DEPENDS "Lean_${arch_uppercase}/Lean${arch_uppercase}.lean")
    add_custom_target(generated_lean_executable_${arch} DEPENDS "Lean_${arch_uppercase}_executable/Lean${arch_uppercase}Executable.lean")

    ############# Lem #############

    # Build Lem definitions, en route to Isabelle or HOL4.
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
            --all-modules
            ${project_file}
        COMMAND
            echo
            "declare {isabelle} rename field sync_exception_ext = sync_exception_ext_exception"
            >>
            ${CMAKE_CURRENT_BINARY_DIR}/${arch}_types.lem

    )
    add_custom_target(generated_lem_${arch} DEPENDS "${arch}.lem")

    ############# Isabelle #############

    # Build Isabelle definitions from Lem
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
endforeach()
