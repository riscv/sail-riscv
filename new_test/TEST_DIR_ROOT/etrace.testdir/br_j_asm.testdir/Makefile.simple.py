# vim: set tabstop=4 shiftwidth=4 expandtab
# ====================================================================================================================
# Filename:		Makefile.simple.py
#
# Description:	Makefile for building and running and checking a RISC-V Sail model test
#   
#               Written in the pmake format
#
#               Four targets required:
#
#                   build - compile any objects that are needed
#
#                   run - run the command.  put stdout and stderr into "logfile".
#                       the check target will look for the keyword "error" (in all
#                       its possible forms).
#
#                   check - check the results of run. "test.passed" must be detected.
#                       "test.failed" indicates an error
#
#                   clean - remove generated artifacts
#
# Author(s):	Bill McSpadden (bill@riscv.org)
#
# Revision:		See git log
#
# ====================================================================================================================

exec(open("./makefile.get_sandbox_root.header.py").read())
TEST_DIR_PATH = get_sandbox_root()

info("TEST_DIR_PATH: " + TEST_DIR_PATH)
info("TEST_DIR_PATH realpath: " + str(realpath(TEST_DIR_PATH)))
info("TEST_DIR_PATH abspath:  " + str(abspath(TEST_DIR_PATH)))

# Tools need to be in your $PATH,  or the path must be fully specified.
CC32		= "riscv32-unknown-elf-gcc"
ASM32		= "riscv32-unknown-elf-gcc"
LD32		= "riscv32-unknown-elf-ld"
OBJDUMP32   = "riscv32-unknown-elf-objdump"

CC64		= "riscv64-unknown-elf-gcc"
ASM64		= "riscv64-unknown-elf-gcc"
LD64		= "riscv64-unknown-elf-ld"
OBJDUMP64   = "riscv64-unknown-elf-objdump"

#=========================================================
# List of source files that are the source for a test
C_SRC		= wildcard("*.c")
info("C_SRC: " + C_SRC)
#ASM_SRC		= wildcard("*.S *.s")   # TODO: this doesn't work
ASM_SRC		= wildcard("*.S")
info("ASM_SRC: " + ASM_SRC)


#=========================================================
# Per test-instance test definition
#	These variables are what make the instance of the test
#	unique. 

CONFIG_BASE		= "0x80000000"
MARCH          	= " -march=rv32imc_zicsr -mabi=ilp32"
#MARCH          	= " -march=rv32imc       -mabi=ilp32"

CC_FLAGS	    = ""
ASM_FLAGS 		= "-c -DCONFIG_BASE=" + CONFIG_BASE + MARCH
LD_FILE 		= ""
LD_FLAGS		= " -T riscv_test.ld"
OBJDUMP_FLAGS   = "-t -Dz"
RUN_FLAGS 		= ""
XLEN			= "32"
OBJDIR_TMP		= strip(XLEN + ASM_FLAGS + CC_FLAGS + LD_FILE + LD_FLAGS + RUN_FLAGS)
OBJDIR_TMP      = OBJDIR_TMP.replace(" ", "_")
OBJDIR_TMP      = OBJDIR_TMP.replace("-", "_")
OBJDIR_TMP      = OBJDIR_TMP.replace("=", "_")
OBJDIR_TMP      = OBJDIR_TMP.replace("__", "_")
UNIQ_TESTNAME   = addprefix("RV", OBJDIR_TMP)
ARTIFACT_DIR    = UNIQ_TESTNAME + ".artifactdir/"

C_OBJS		= addprefix(UNIQ_TESTNAME + ".artifactdir/", subst(".c", ".o", C_SRC))
info("C_OBJS: " + C_OBJS)
ASM_OBJS	= addprefix(UNIQ_TESTNAME + ".artifactdir/", subst(".s", ".o", (subst(".S", ".o", ASM_SRC))))
info("ASM_OBJS: " + ASM_OBJS)
OBJS_BASE	= C_OBJS + ASM_OBJS

# =========================================================
# Rules

def build__recipe(t) :
    echo("building " + t.target)
    return 0

Rule("build", [ ARTIFACT_DIR + "test.elf", ARTIFACT_DIR + "test.dump" ], recipe = build__recipe, phony = True)

def test_dump__recipe(t) :
    echo("building " + t.target)
    cmd = OBJDUMP32 + " " + OBJDUMP_FLAGS + " " + ARTIFACT_DIR + "test.elf" + " > " + t.target
    echo("cmd: " + cmd)
    return os.system(cmd)

Rule(ARTIFACT_DIR + "test.dump", [ARTIFACT_DIR + "test.elf"], test_dump__recipe, phony = False)

def test_elf__recipe(t) :
    echo("building " + t.target)
    cmd = LD32 + LD_FLAGS + " -o " + t.target + " " + OBJS_BASE
    echo("cmd: " + cmd)
    return os.system(cmd)

Rule(ARTIFACT_DIR + "test.elf", [ OBJS_BASE ], recipe = test_elf__recipe, phony = False)

def asm__recipe(t) :
    echo("building " + t.target)
    if (os.system("mkdir -p " + ARTIFACT_DIR) != 0) :
        echo("error: unable to mkdir " + ARTIFACT_DIR, ">>", "./test.failed")
        sys.exit(1)
    cmd = ASM32 + " " + ASM_FLAGS + " -o " + t.target + " " + ' '.join(t.prerequisites)
    echo("cmd: " + cmd)
    return os.system(cmd)

Rule(ARTIFACT_DIR + "%.o", [ "%.S" ], asm__recipe, phony = False)

def run__recipe(t) :
    echo("building " + t.target)
    cmd = TEST_DIR_PATH +  "/../../c_emulator/riscv_sim_RV" + XLEN + " " + RUN_FLAGS + " " + ARTIFACT_DIR + "test.elf" + " | tee " + ARTIFACT_DIR + "logfile"
    echo("cmd: " + cmd)
    ret_val = os.system(cmd)
    if ret_val != 0 :
        echo ("error: non-zero exit value for target, run", ">>", ARTIFACT_DIR + "logfile")
    return ret_val

Rule("run", [ ARTIFACT_DIR + "test.elf" ], run__recipe, phony = True)

def check__recipe(t) :
    echo("building " + t.target)
    ret_val = 0
    if os.path.isfile(ARTIFACT_DIR + "test.failed") :
        echo("error: " + ARTIFACT_DIR + "test.failed" + "detected.  Test failed", ">>", "./test.failed")
        ret_val = 1

    # Search log file for the word "error"
    ret = os.system("grep -i -q error " + ARTIFACT_DIR + "logfile")
    if ret == 0 :   # grep return value of zero means a match was seen
        echo("error: keyword 'error' found in " + ARTIFACT_DIR + "logfile" + " Test failed", ">>", ARTIFACT_DIR + "test.failed")
        ret_val = 1

    if not os.path.isfile(ARTIFACT_DIR + "test.failed") :
        echo("passed: ",  ">>", ARTIFACT_DIR + "test.passed")
        ret_val = 0
    return ret_val

Rule("check", [  ], check__recipe, phony = True)

def clean__recipe(t) :
    echo("building " + t.target)
    os.system("rm -f test.passed test.failed")
    os.system("rm -rf *.artifactdir")
    return 0

Rule("clean", [ ], clean__recipe, phony = True)




