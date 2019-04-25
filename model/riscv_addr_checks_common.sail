/* Extensions may wish to interpose on fetch, control transfer, and data
 * addresses used to access memory and perhaps modify them.  This file
 * defines the return values used by functions that perform this interposition.
 *
 * The model defines defaults for these functions in riscv_addr_checks.sail;
 * extensions would need to define their own functions to override them.
 */

union Ext_FetchAddr_Check ('a : Type) = {
  Ext_FetchAddr_OK  : xlenbits,  /* PC value to use for the actual fetch */
  Ext_FetchAddr_Error : 'a
}

union Ext_ControlAddr_Check ('a : Type) = {
  Ext_ControlAddr_OK : xlenbits, /* PC value to use for the target of the control operation */
  Ext_ControlAddr_Error : 'a
}

union Ext_DataAddr_Check ('a : Type) = {
  Ext_DataAddr_OK : xlenbits,    /* Address to use for the data access */
  Ext_DataAddr_Error : 'a
}
