// vim: set tabstop=4 shiftwidth=4 expandtab
// ============================================================================
// Filename:    rv_cfg_func.h
//
// Description: Functions prototype support for rv_cfg
//
// Author(s):   Bill McSpadden (bill@riscv.org)
//
// Revision:    See git log
// ============================================================================

#pragma once

#include "sail.h" 
#include <libfyaml.h>
#include <sys/stat.h>
#include "riscv_platform_impl.h"

//This macro must be defined before including pcre2.h. For a program that uses
//only one code unit width, it makes it possible to use generic function names
//such as pcre2_compile().
#define PCRE2_CODE_UNIT_WIDTH 8
#include <pcre2.h>

// ==================================================
// typedefs and structs

// Keep these in monotonically increasing linear order 
//  as they are used as indices into an array where the 
//  index is the enum.
typedef enum 
    { 
    RV_CFG_ISA      = 0, 
    RV_CFG_PLATFORM = 1, 
    RV_CFG_DEBUG    = 2,
    RV_CFG_LAST     = 3
    } rv_cfg_e;

typedef struct  rv_cfg_enum2string_tt
    {
    rv_cfg_e    e;
    char *      s;
    } rv_cfg_enum2string_t;

typedef struct rv_cfg_enum2doc_tt
    {
    rv_cfg_e                e;
    struct fy_document *    fyd;
    char *                  filename;
    } rv_cfg_enum2doc_t;

// ==================================================
// Function prototypes just for the C side of things.
//  The items in this section should only be used on
//  the C side of the simulator.

int             rv_cfg_c_init(void);
char *          rv_cfg_c_get_string(rv_cfg_e e);
rv_cfg_e        rv_cfg_c_get_enum(char * s);
int             rv_cfg_c_build_from_file(rv_cfg_e rv_cfg_type, char * filename );
unsigned int    rv_cfg_c_int(char *);
char *          rv_cfg_c_string(char *);
bool            rv_cfg_c_bool(char *);
int             rv_cfg_c_configure(void);
void            rv_cfg_c_dump_yaml(char *);
int             rv_cfg_c_ext_enable(char * isa_str, char * ext_pattern);
bool            rv_cfg_c_bool(char * key_str);
bool            rv_cfg_c_path_exists(char * path);



// ==================================================
// Function prototypes for the Sail interface

// It doesn't appear that Sail does anything with the
//  function's return value.  "return values" are done
//  by passing a pointer to a return value struct, which
//  is the first element in the function's argument list.

int             rv_cfg_s_int(sail_int *, char *);
int             rv_cfg_s_string(sail_string , char *);
bool            rv_cfg_s_bool(sail_string , char *);
unit            rv_cfg_s_dump_yaml(char *);

//#endif
