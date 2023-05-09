// vim: set tabstop=4 shiftwidth=4 expandtab
// ============================================================================
// Filename:    rv_cfg_func.c
//
// Description: Functions to be called by Sail and C to get values from a yaml file.
//
// Author(s):   Bill McSpadden (bill@riscv.org)
//
// Revision:    See git log
// ============================================================================

#include <sail.h>
#include "rv_cfg_func.h"
#include "string.h"

/* RISC-V Config YAML configuration support */
static char                *rv_config_platform_file = NULL;
static int                 rv_config_platform_fd = 0;
static struct fy_document  *rv_config_fyd_platform = NULL;

static char                *rv_config_isa_file = NULL;
static int                 rv_config_isa_fd = 0;
static struct fy_document  *rv_config_fyd_isa      = NULL;

// rv_cfg_enum2string_a is built (in rv_cfg_init()) so that the
//  array index is the enum value.  A poor man's associative array.
static rv_cfg_enum2string_t  rv_cfg_enum2string_a[RV_CFG_LAST];

#define EXPAND(__ENUM2STR__)  { __ENUM2STR__, #__ENUM2STR__ }
static rv_cfg_enum2string_t  rv_cfg_enum2string_init_a[] = 
    {
        EXPAND(RV_CFG_ISA),
        EXPAND(RV_CFG_PLATFORM),
        EXPAND(RV_CFG_DEBUG),
    };

static rv_cfg_enum2doc_t rv_cfg_enum2doc_a[RV_CFG_LAST];

extern int64_t zxlen_val;

// ============================================================================
int
rv_cfg_c_init()
    {
    for (int i = 0; i < RV_CFG_LAST; i++)
        {
        rv_cfg_enum2string_a[rv_cfg_enum2string_init_a[i].e].e = rv_cfg_enum2string_init_a[i].e;
        rv_cfg_enum2string_a[rv_cfg_enum2string_init_a[i].e].s = rv_cfg_enum2string_init_a[i].s;
        }

    }

// ============================================================================
int
rv_cfg_c_configure(void)
    {
    char    * RV_ISA;


    // ====================================================================
    // Get the ISA string.  Much of the configuration is derived from this
    //  string.
    RV_ISA = rv_cfg_c_string("/hart0/ISA");

    // ====================================================================
    // Do the configuration.
    rv_enable_rvc           = rv_cfg_c_ext_enable(RV_ISA, "C");
    rv_enable_fdext         = rv_cfg_c_ext_enable(RV_ISA, "F");
    rv_enable_next          = rv_cfg_c_ext_enable(RV_ISA, "N");
    rv_enable_zfinx         = rv_cfg_c_ext_enable(RV_ISA, "Zfinx");
    rv_enable_dirty_update  = rv_cfg_c_ext_enable(RV_ISA, "Ssptead");               //TODO:  Use this, ....
    //rv_enable_dirty_update  = rv_cfg_c_bool_c("/hart0/pte_dirty_update_enable");    //   .... not this

    rv_enable_misaligned    = rv_cfg_c_bool("/hart0/hw_data_misaligned_support");

    rv_enable_pmp                   =   (
                                            (rv_cfg_c_bool("/hart0/pmpaddr0/rv32/accessible") ) ||
                                            (rv_cfg_c_bool("/hart0/pmpaddr0/rv64/accessible") )
                                        ) ;

    rv_ram_size                     = rv_cfg_c_int("/ram_size") << 20;    // Convert to MBs
    rv_reset_address                = rv_cfg_c_int("/reset/address");

    rv_enable_writable_misa         = rv_cfg_c_path_exists("/hart0/misa/rv32/extensions/type/warl");
    rv_mtval_has_illegal_inst_bits  = rv_cfg_c_bool("/hart0/mtval/has_illegal_inst_bits");

    // ====================================================================
    // Print out the configuration that you just pulled out from the
    //  RISCV-Config files.  Print it out in terms of the Golden Model
    //  variables that are used in Sail.
#define CFG_STRING_FMT "%-56s"
    printf("=================================================================================\n");
    printf("Start: RISC-V Golden Model configuration values.....\n");
    printf(CFG_STRING_FMT "'%s'\n", "RV_ISA: ",                                                 RV_ISA);
    printf(CFG_STRING_FMT "%s\n",   "C ext support (rv_enable_rvc): " ,                         rv_enable_rvc                   ? "true" : "false");
    printf(CFG_STRING_FMT "%s\n",   "F/D ext support (rv_enable_fdext):",                       rv_enable_fdext                 ? "true" : "false");
    printf(CFG_STRING_FMT "%s\n",   "N ext support (rv_enable_next): ",                         rv_enable_next                  ? "true" : "false");
    printf(CFG_STRING_FMT "%s\n",   "Zfinx ext support (rv_enable_zfinx): ",                    rv_enable_zfinx                 ? "true" : "false");
    printf(CFG_STRING_FMT "%s\n",   "enable misaligned support (rv_enable_misaligned): ",       rv_enable_misaligned            ? "true" : "false");
    printf(CFG_STRING_FMT "%s\n",   "enable pmp support (rv_enable_pmp): ",                     rv_enable_pmp                   ? "true" : "false");
    printf(CFG_STRING_FMT "%ld MB\n", "ram size (rv_ram_size): ",                               rv_ram_size >> 20);
    printf(CFG_STRING_FMT "0x%lx\n", "reset address (rv_reset_address, zPC): ",                 rv_reset_address);
    printf(CFG_STRING_FMT "%s\n",   "PTE dirty update enable (rv_enable_dirty_update): ",       rv_enable_dirty_update          ? "true" : "false");
    printf(CFG_STRING_FMT "%s\n",   "writable misa (rv_enable_writable_misa): ",                rv_enable_writable_misa         ? "true" : "false");
    printf(CFG_STRING_FMT "%s\n",   "mtval: illegal inst (rv_mtval_has_illegal_inst_bits): ",   rv_mtval_has_illegal_inst_bits  ? "true" : "false");
    printf("End: RISC-V Golden Model configuration values.....\n");
    printf("=================================================================================\n");

    // ====================================
    // Error checking of configuration.
    //  Most error checking of allowed configurations is done 
    //  by the RISCV-Config validator script.  It is assumed
    //  that the user has validated his implementation-specific
    //  config file using the validator script.
    //
    //  TODO:  Would it make sense to run the validator script
    //      here in order to ensure that legal configurations
    //      are being run?  I believe RISCOF already does this
    //      when running the arch-tests.

// TODO:  Need a method for getting XLEN from the Sail model so
//  that we can compare it against the ISA string.
//    // ====================================
//    // Error checking of configuration.  XLEN
//    printf("%s, %d: zxlen_val: %ld\n", __FILE__, __LINE__, zxlen_val);
//    if (zxlen_val == 32) 
//        {
//        if (!rv_cfg_c_ext_enable(RV_ISA, "RV32"))
//            {
//            fprintf(stderr, "%s, %d: incompatable settings for zxlen_val and RV_ISA. both must be 32.", 
//                    __FILE__, __LINE__);
//            exit(1);
//            }
//        RV32ISA = RV_ISA;
//        }
//    else if (zxlen_val == 64) 
//        {
//        if (!rv_cfg_c_ext_enable(RV_ISA, "RV64"))
//            {
//            fprintf(stderr, "%s, %d: incompatable settings for zxlen_val and RV_ISA. both must be 64.", 
//                    __FILE__, __LINE__);
//            exit(1);
//            }
//        RV64ISA = RV_ISA;
//        }
//    else if (zxlen_val == 128) 
//        {
//        if (!rv_cfg_c_ext_enable(RV_ISA, "RV128"))
//            {
//            fprintf(stderr, "%s, %d: incompatable settings for zxlen_val and RV_ISA. both must be 128.", 
//                    __FILE__, __LINE__);
//            exit(1);
//            }
//        RV128ISA = RV_ISA;
//        }
//    else
//        {
//        fprintf(stderr, "%s, %d: invalid setting for zxlen_val: %d.", 
//                __FILE__, __LINE__, zxlen_val);
//        }

    // ====================================
    // Check extension settings for mutual exclusivity
    // TODO:  should I introduce 'assert' as an error reporting mechanism
    //      instead of this ad hoc mechanism?
    if ((rv_enable_fdext == true) && (rv_enable_zfinx == true))
        {
        fprintf(stderr, "%s, %d: incompatable settings for [fd]ext and Zfinx. both cannot be enabled.", 
                __FILE__, __LINE__);
        exit(1);
        }

    }

// ============================================================================
bool
rv_cfg_c_path_exists(char * path)
    {
    struct fy_path_parse_cfg    cfg;
    struct fy_path_parser       *fypp;
    bool                        ret;

    cfg.flags = FYPPCF_QUIET;
    cfg.userdata = NULL;
    cfg.diag = NULL;

    fypp = fy_path_parser_create(&cfg);
    ret = (fy_path_parse_expr_from_string(fypp, path, -1) == NULL) ? false : true;
    fy_path_parser_destroy(fypp);

    return(ret);
    }

// ============================================================================
bool
rv_cfg_c_bool(char * key_str)
    {
    char    *s;

    s = rv_cfg_c_string(key_str);

    if ( strcmp("true", s) == 0)
        {
        return(true);
        }
    else if ( strcmp("false", s) == 0 )
        {
        return(false);
        }
    else
        {
        fprintf(stderr, "%s, %d: internal error. '%s' does not appear to be a bool.\n", 
                __FILE__, __LINE__, key_str);
        exit(1);
        }
    }

// ============================================================================
int
rv_cfg_c_ext_enable(char * isa_str, char * ext_pattern)
    {
    pcre2_code          *re;
    int                 errornumber;
    PCRE2_SIZE          erroroffset;
    pcre2_match_data    *match_data;
    int                 rc;

    re = pcre2_compile(
        ext_pattern,            /* the pattern */
        PCRE2_ZERO_TERMINATED,  /* indicates pattern is zero-terminated */
        0,                      /* default options */
        &errornumber,           /* for error number */
        &erroroffset,           /* for error offset */
        NULL);                  /* use default compile context */

    if (re == NULL)     // Compilation failed
        {
        PCRE2_UCHAR buffer[256];
        pcre2_get_error_message(errornumber, buffer, sizeof(buffer));
        printf("PCRE2 compilation failed at offset %d: %s\n", (int)erroroffset,
                buffer);
        }    

    match_data = pcre2_match_data_create_from_pattern(re, NULL);

    rc = pcre2_match(
        re,                   /* the compiled pattern */
        isa_str,              /* the subject string */
        strlen(isa_str),      /* the length of the subject */
        0,                    /* start at offset 0 in the subject */
        0,                    /* default options */
        match_data,           /* block for storing the result */
        NULL);                /* use default match context */

    if ((rc == 0) || (rc == -1))    // Does not match
        {
        return(0);
        }
    else if (rc == 1)
        {
        return(1);
        }
    else
        {
        fprintf(stderr, "%s, %d: unexpected match return value, %d, for '%s' in ISA string %s\n",
                __FILE__, __LINE__, rc, ext_pattern, isa_str);
        exit(1);
        }
    }

// ============================================================================
char *
rv_cfg_c_get_string(rv_cfg_e e)
    {
    return(rv_cfg_enum2string_a[e].s);
    }

// ============================================================================
rv_cfg_e
rv_cfg_c_get_enum(char * s)
    {
    for (int i = 0; i < (sizeof(rv_cfg_enum2string_a)/sizeof(rv_cfg_enum2string_t)); i++)
        {
        if ( strcmp(rv_cfg_enum2string_a[i].s, s) == 0 )
            {
            return(rv_cfg_enum2string_a[i].e);
            }
        }
    fprintf(stderr, "%s, %d: error:  internal error.  bad lookup of '%s'\n", __FILE__, __LINE__, s);
    exit(1);
    }


// ============================================================================
int 
rv_cfg_c_build_from_file(rv_cfg_e rv_cfg_type, char * filename )
    {
    struct stat buffer;
    struct fy_document  *fyd = NULL;

    printf("%s file: %s\n", rv_cfg_c_get_string(rv_cfg_type), filename);
    if ( (stat(filename, &buffer) == -1) ) 
        {
        fprintf(stderr, "%s, %d: error: file, %s, does not exist.\n", __FILE__, __LINE__, filename);
        return(0);
        }

    rv_cfg_enum2doc_a[rv_cfg_type].fyd = fy_document_build_from_file(NULL, filename);
    if (! rv_cfg_enum2doc_a[rv_cfg_type].fyd)
        {
        fprintf(stderr, "unable to build document from %s\n", filename);
        return(0);
        }
    rv_cfg_enum2doc_a[rv_cfg_type].filename = filename;
    rv_cfg_enum2doc_a[rv_cfg_type].e        = rv_cfg_type;

    printf("%s, %d: rv_cfg file, '%s', loaded successfully as %s.\n", 
            __FILE__, __LINE__, rv_cfg_enum2doc_a[rv_cfg_type].filename, 
            rv_cfg_c_get_string(rv_cfg_enum2doc_a[rv_cfg_type].e));

    return (1);
    }


// ============================================================================
unsigned int
rv_cfg_c_int(char * key_str)
    {
    struct fy_document      *fyd = NULL;
    //unsigned int            yaml_val_int;
             int            yaml_val_int;
    int                     count;
    char                    *tmp_str;


    for (int i = 0; i < RV_CFG_LAST; i++)
        {
        char    *conversion_str;
        if ( (fyd = rv_cfg_enum2doc_a[i].fyd) == NULL)
            {
            continue;
            }

        conversion_str = " %i";
        tmp_str = malloc(strlen(key_str) + strlen(conversion_str) + 1);
        strcpy(tmp_str, key_str);
        strcat(tmp_str, conversion_str);
        //printf("%s, %d: scanf string: %s\n", __FILE__, __LINE__, tmp_str);

        count = fy_document_scanf(fyd, tmp_str, &yaml_val_int);
        if (count == 1)
            {
            free(tmp_str);
            return(yaml_val_int);
            }
        free(tmp_str);
        }

    // If we've gotten to this point, we've gone through each of the 
    //  rv_cfg files and didn't find the pattern  OR  the pattern
    //  didn't match the conversion string.  In either case,  there is
    //  something wrong.

    fprintf(stderr, "%s, %d: the key, %s, was not found.\n", __FILE__, __LINE__, key_str);
    exit(1);
    return(0);      // Never taken.
    }

// ============================================================================
char *
rv_cfg_c_string(char * key_str)
    {
    struct fy_document      *fyd = NULL;
//    char                    *yaml_val_string;
    char                    yaml_val_string[1024];
    int                     count;
    char                    *tmp_str;
    char                    *ret_str_ptr;

    for (int i = 0; i < RV_CFG_LAST; i++)
        {
        char    *conversion_str;
        if ( (fyd = rv_cfg_enum2doc_a[i].fyd) == NULL)
            {
            continue;
            }

        //printf("%s, %d: checking yaml file, %s\n", __FILE__, __LINE__, rv_cfg_enum2doc_a[i].filename);
        conversion_str = " %1023s";
        tmp_str = malloc(strlen(key_str) + strlen(conversion_str) + 1);
        strcpy(tmp_str, key_str);
        strcat(tmp_str, conversion_str);
        //printf("%s, %d: scanf string: '%s'\n", __FILE__, __LINE__, tmp_str);

        count = fy_document_scanf(fyd, tmp_str, yaml_val_string);
        if (count == 1)
            {
            free(tmp_str);
            ret_str_ptr = malloc(strlen(yaml_val_string)); // TODO: where should this be freed?
            strcpy(ret_str_ptr, yaml_val_string);
            return(ret_str_ptr);
            }
        free(tmp_str);
        }

    // If we've gotten to this point, we've gone through each of the 
    //  rv_cfg files and didn't find the pattern  OR  the pattern
    //  didn't match the conversion string.  In either case,  there is
    //  something wrong.

    fprintf(stderr, "%s, %d: the key, '%s', was not found.\n", __FILE__, __LINE__, key_str);
    exit(1);
    return(0);      // Never taken.
    }

// ============================================================================
void
rv_cfg_c_dump_yaml_c(char *yaml_filename)
    {
    struct fy_document      *fyd = NULL;

    fyd = fy_document_build_from_file(NULL, yaml_filename);
    fy_emit_document_to_fp(fyd, FYECF_DEFAULT | FYECF_SORT_KEYS, stdout);
    free(fyd);
    }

// ============================================================================
int
rv_cfg_s_int(sail_int *zret_int,  char * yaml_key_str)
    {
//    printf("%s, %d: entering rv_cfg_s_int()\n", __FILE__, __LINE__);
    mpz_set_ui(*zret_int, rv_cfg_c_int(yaml_key_str));
    return(1);
    }

// ============================================================================
int
//rv_cfg_s_string(sail_string **s,  char * yaml_key_str)
rv_cfg_s_string(sail_string s,  char * yaml_key_str)
    {
//    printf("%s, %d: entering rv_cfg_string()\n", __FILE__, __LINE__);
    s = rv_cfg_c_string(yaml_key_str);
    return(1);
    }

// ============================================================================
unit
rv_cfg_s_dump_yaml(char *yaml_filename)
    {
    rv_cfg_c_dump_yaml(yaml_filename);
    }

