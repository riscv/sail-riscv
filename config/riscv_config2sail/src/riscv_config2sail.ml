(**************************************************************************)
(*     Sail                                                               *)
(*                                                                        *)
(*  Copyright (c) 2019                                                    *)
(*    Robert Norton-Wright                                                *)
(*                                                                        *)
(*  All rights reserved.                                                  *)
(*                                                                        *)
(*  This software was developed by the University of Cambridge Computer   *)
(*  Laboratory as part of the Rigorous Engineering of Mainstream Systems  *)
(*  (REMS) project, funded by EPSRC grant EP/K008528/1.                   *)
(*                                                                        *)
(*  Redistribution and use in source and binary forms, with or without    *)
(*  modification, are permitted provided that the following conditions    *)
(*  are met:                                                              *)
(*  1. Redistributions of source code must retain the above copyright     *)
(*     notice, this list of conditions and the following disclaimer.      *)
(*  2. Redistributions in binary form must reproduce the above copyright  *)
(*     notice, this list of conditions and the following disclaimer in    *)
(*     the documentation and/or other materials provided with the         *)
(*     distribution.                                                      *)
(*                                                                        *)
(*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''    *)
(*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED     *)
(*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A       *)
(*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR   *)
(*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,          *)
(*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT      *)
(*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF      *)
(*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND   *)
(*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,    *)
(*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT    *)
(*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF    *)
(*  SUCH DAMAGE.                                                          *)
(**************************************************************************)

open Yaml
open Rresult

(* Basic type for representing a sail value that we 
   are going to pretty print or serialise *)
type sail_value =
  | Unit
  | Bool of bool
  | Int of int64
  | Id of string (* e.g. enum constructor *)
  | String of string
  | TupleValue of sail_value list
  | StructValue of string * ((string * sail_value) list) (* Construct id then field names and values *)
  | UnionValue of string * sail_value (* Constructor ID + argument *)
  | Array of sail_value list

let n_spaces n = String.make n ' '

let rec pp_sail_value ?(indent=0) ?(indent_width=2) v = match v with
  | Unit -> "()"
  | Bool b -> if b then "true" else "false"
  | Int  i -> Int64.format "%u" i
  | String s -> "\"" ^ s ^ "\""
  | Id s -> s
  | StructValue(t, fvs) ->
     let kvs = List.map (fun (k,v) -> (n_spaces (indent + indent_width)) ^ k ^ " = " ^ (pp_sail_value ~indent:(indent + indent_width)  v)) fvs in
     "struct {\n" ^ (String.concat ", \n" kvs) ^ "\n" ^ (n_spaces indent) ^ "} : " ^ t
  | UnionValue(cid, v) ->
     cid ^ "(" ^ (pp_sail_value ~indent:indent v) ^ ")"
  | Array xs ->
     let xss = List.map pp_sail_value xs in
     "[|" ^ (String.concat ", " xss) ^ "|]"
  | TupleValue xs ->
     let xss = List.map pp_sail_value xs in
     "(" ^ (String.concat ", " xss) ^ ")"

let opt_file_out : string ref = ref ""
let opt_isa_yaml : string ref = ref ""
let opt_platform_yaml : string ref = ref ""
let opt_file_arguments = ref ([]:string list)
let options = Arg.align ([
  ( "-o", Arg.Set_string (opt_file_out), "<file> select output filename");
  ( "-i", Arg.Set_string (opt_isa_yaml), "<file> select isa yaml filename");
  ( "-p", Arg.Set_string (opt_platform_yaml), "<file> select platform yaml filename");
])

let usage_msg =
    ("riscv_config2sail %%VERSION%%\n"
     ^ "usage:       riscv_config2sail -i isa.yaml -p platform.yaml -o output.sail\n"
    )

let _ =
  Arg.parse options
    (fun s ->
      opt_file_arguments := (!opt_file_arguments) @ [s])
    usage_msg

let yaml_to_string y =
  match Yaml.yaml_to_string y with
  | Ok s -> s
  | Error (`Msg s) -> s

let find_key (k:string) (yaml:yaml) =
  let (_, v) =
    match yaml with
    | `O(ks) -> (try List.find (fun (s, _) -> s.value = k) ks with
                | Not_found -> raise (Failure(Printf.sprintf "Failed to find key '%s' on '%s'" k (yaml_to_string yaml))))
    | _ -> raise (Failure (Printf.sprintf "Attempted to find key '%s' on non-dict '%s'" k (yaml_to_string yaml))) in
  v

let rec find_path ks yaml =
  match ks with
  | []     -> yaml
  | k::ks' -> find_path ks' (find_key k yaml)

let has_key k yaml =
  match yaml with
  | `O(ks) -> List.exists (fun (s, _) -> s.value = k) ks
  | _ -> false

let rec has_path ks yaml =
  match ks with
  | []     -> false
  | [k]    -> has_key k yaml
  | k::ks' -> has_path ks' (find_key k yaml)

let get_string path yaml =
  let s = find_path path yaml in
  match s with
  | `Scalar(sc) -> sc.value
  | _ -> raise (Failure(Printf.sprintf "Expected scalar value at path '%s' in '%s'" (String.concat "." path) (yaml_to_string yaml)))

let get_string_val k ?(yk=[k]) yaml =
  (k, String(get_string yk yaml))

let get_bool path yaml =
  let s = get_string path yaml in
  match s with
  | "true" -> true
  | "false" -> false
  | _ -> raise (Failure(Printf.sprintf "Expected boolean at path '%s' in '%s' but got '%s'" (String.concat "." path) (yaml_to_string yaml) s))

let get_bool_val k ?(yk=[k]) yaml =
  (k, Bool(get_bool yk yaml))

let get_int64 path yaml =
  let s = get_string path yaml in
  try Int64.of_string s with
  | Failure(s) -> raise (Failure (Printf.sprintf "Expected int64 at path '%s' in '%s' but got %s" (String.concat "." path) (yaml_to_string yaml) s))

let get_int_val k ?(yk=[k]) yaml = 
  (k, Int(get_int64 yk yaml))

let get_int (s : yaml) = match s with
  | `Scalar(s) -> (try Int(Int64.of_string (s.value)) with
                  | Failure(_) -> raise (Failure (Printf.sprintf "get_int failed on '%s'" s.value)))
  | _ -> raise (Failure(Printf.sprintf "Expected int64 but got '%s'" (yaml_to_string s)))

let get_list f (yaml : yaml) = match yaml with
  | `A(l) -> List.map f l
  | _ -> raise (Failure(Printf.sprintf "Expected array but got '%s'" (yaml_to_string yaml)))

let get_warl_range_entry (yaml : yaml) = match yaml with
  | `A([v])      -> UnionValue("WARL_range_value", get_int v)
  | `A([v1; v2]) -> UnionValue("WARL_range_interval", TupleValue([get_int v1; get_int v2]))
  | _            -> raise (Failure(Printf.sprintf "Expected one or two entry array but got '%s'" (yaml_to_string yaml)))

let get_warl_range k ?(yk=[k]) yaml =
  let range_yaml = find_path yk yaml in
  let rl = Array(get_list get_warl_range_entry (find_key "rangelist" range_yaml)) in
  let mode = get_string ["mode"] range_yaml in
  (k,
  StructValue (
      "WARL_range",
      [
        ("rangelist", rl);
        ("mode", Id ("WARL_" ^ mode))
      ]
    )
  )

let get_warl_bitmask k ?(yk=[k; "bitmask"]) yaml =
  let bm_yaml = find_path yk yaml in
  (k,
  StructValue (
      "WARL_bitmask",
      [
        get_int_val "mask" bm_yaml;
        get_int_val "default_val" ~yk:["default"] bm_yaml
      ]
    )
  )

let get_warl_either k ?(yk=[k]) yaml =
  let y = find_path yk yaml in
  if has_key "range" y then
    let (_, rv) = get_warl_range "range" y in
    (k, UnionValue("WARL_range", rv))
  else
    let (_, bmv) = get_warl_bitmask "" ~yk:["bitmask"] y in
    (k, UnionValue("WARL_bitmask", bmv))

let get_misa_config k yaml =
  let misa = find_key k yaml in
  (k,
  StructValue (
      "misa_config",
      [
        get_bool_val "implemented" misa;
        get_warl_range "MXL" ~yk:["MXL"; "range"] misa;
        get_warl_bitmask "Extensions" misa
      ]
    ))
  
let get_id_reg_config k yaml =
  let id_yaml = find_key k yaml in
  let implemented = get_bool ["implemented"] id_yaml in
  let id_val = if implemented then (get_int64 ["id"] id_yaml) else Int64.zero in (* XXX is there a difference between not implemented and id of zero?! *)
  (k, StructValue(
      "id_reg_config",
      [
        get_bool_val "implemented" id_yaml;
        ("id", Int(id_val));
      ]
  ))

let get_hardwired_config k yaml =
  let hw_yaml = find_key k yaml in
  (k,
   StructValue(
       "hardwired_config",
      [
        get_bool_val "is_hardwired" hw_yaml;
        get_int_val "hardwired_val" hw_yaml
      ]
     )
  )


let get_xxl_config k yaml =
  let xxl_yaml = find_key k yaml in
  let implemented = get_bool ["implemented"] xxl_yaml in
  if implemented then
    let hardwired_mxl = "MXL" = get_string ["hardwired_field"] xxl_yaml in
    (k,
     StructValue(
        "XXL_config",
        [
          get_warl_range "rnge" ~yk:["range"] xxl_yaml;
          get_bool_val "is_hardwired" xxl_yaml;
          ("hardwired_mxl", Bool(hardwired_mxl))
        ]
      )
    )
  else
    (k,
     StructValue(
        "XXL_config",
        [
          ("rnge", StructValue("WARL_range", [("rangelist", Array([])); ("mode", Id("WARL_Unchanged"))]));
          ("is_hardwired", Bool(true));
          ("hardwired_mxl", Bool(true))
        ]
      )
    )

let get_x_is_hardwired x yaml =
  get_bool_val ~yk:[x;"is_hardwired"] (x ^ "_is_hardwired") yaml

let get_mstatus_config k yaml =
  let mstatus_yaml = find_key k yaml in
  (k,
  StructValue(
      "mstatus_config",
      [
        get_hardwired_config "XS" mstatus_yaml;
        get_warl_range "FS" ~yk:["FS"; "range"] mstatus_yaml;
        get_warl_range "MPP" ~yk:["MPP"; "range"] mstatus_yaml;
        get_xxl_config "SXL" mstatus_yaml;
        get_xxl_config "UXL" mstatus_yaml;
        get_x_is_hardwired "TSR"  mstatus_yaml;
        get_x_is_hardwired "TW"   mstatus_yaml;
        get_x_is_hardwired "TVM"  mstatus_yaml;
        get_x_is_hardwired "MXR"  mstatus_yaml;
        get_x_is_hardwired "SUM"  mstatus_yaml;
        get_x_is_hardwired "SPP"  mstatus_yaml;
        get_x_is_hardwired "MPRV" mstatus_yaml;
        get_x_is_hardwired "SPIE" mstatus_yaml;
        get_x_is_hardwired "UPIE" mstatus_yaml;
        get_x_is_hardwired "SIE"  mstatus_yaml;
        get_x_is_hardwired "UIE"  mstatus_yaml;
      ]
    )
  )

let get_tvec_config k yaml =
  let y = find_key k yaml in
  (k,
   StructValue(
       "tvec_config",
       [
         get_warl_range "base" ~yk:["BASE"; "range"] y;
         get_warl_range "mode" ~yk:["MODE"; "range"] y;
       ]
     )
  )  


let get_bm_hw_config k yaml =
  let y = find_key k yaml in
  (k,
   StructValue(
       "bitmask_hardwired_config",
       [
         get_warl_bitmask "mask" ~yk:["bitmask"] y;
         get_bool_val "is_hardwired" y;
         get_int_val "hardwired_val" y;
       ]
     )
  )

let get_mhpmcounter_config k yaml =
  let y = find_key k yaml in
  (k,
   StructValue(
       "mhpmcounter_config",
       [
         get_bool_val "is_hardwired" y;
         get_int_val "hardwired_val" y;
       ]
     )
  )

let get_satp_config k yaml =
  let y = find_key k yaml in
  (k,
   StructValue(
       "satp_config",
       [
         get_warl_range "mode" ~yk:["MODE"; "range"] y;
         get_warl_either "asid" ~yk:["ASID"] y;
         get_warl_either "ppn" ~yk:["PPN"] y;
       ]
     )
  )

let get_label_address_config k yaml =
  let y = find_key k yaml in
  if has_key "address" y then
    let av = get_int64 ["address"] y in
    (k, UnionValue("LA_Address", Int(av)))
  else
    let lv = get_string ["label"] y in
    (k, UnionValue("LA_Label", String(lv)))

let get_address_implemented_config k yaml =
  let y = find_key k yaml in
  (k,
  StructValue(
      "address_implemented_config",
      [
        get_int_val "address" y;
        get_bool_val "implemented" y;
      ]
    )
  )

let get_cause_config k yaml =
  let y = find_key k yaml in
  (k,
  StructValue(
      "cause_config",
      [
        get_bool_val "implemented" y;
        ("values", Array(get_list get_int (find_key "values" y)));
      ]
    )
  )

let get_mhpmevent_config k yaml =
  let is_hardwired = get_bool [k; "is_hardwired"] yaml in
  if is_hardwired then
    let v = get_int64 [k; "hardwired_val"] yaml in
    (k,
    UnionValue(
        "WARL_range",
        StructValue(
            "WARL_range",
              [
                ("rangelist", Array([UnionValue("WARL_range_value", Int(v))]));
                ("mode", Id ("WARL_Unchanged"))
              ]
          )
      )
    )
  else
    get_warl_either k yaml

let read_yaml_file s =
  match Bos.OS.File.read Fpath.(v s) >>= yaml_of_string with
  | Rresult.Ok(y) -> y
  | Rresult.Error(`Msg m) -> raise (Failure (Printf.sprintf "Failed to read %s: '%s'" s m))

let zicsr_re = Str.regexp_string "Zicsr"
let zifencei_re = Str.regexp_string "Zifencei"

let contains_regexp r s =
  try ignore(Str.search_forward r s 0); true
  with Not_found -> false

let get_isa_config k y =
  let isa_s = get_string [k] y in
  (k,
  StructValue (
    "isa_config",
    [
      ("I", Bool(String.contains isa_s 'I'));
      ("M", Bool(String.contains isa_s 'M'));
      ("F", Bool(String.contains isa_s 'F'));
      ("A", Bool(String.contains isa_s 'A'));
      ("D", Bool(String.contains isa_s 'D'));
      ("C", Bool(String.contains isa_s 'C'));
      ("S", Bool(String.contains isa_s 'S'));
      ("U", Bool(String.contains isa_s 'U'));
      ("Zicsr", Bool(contains_regexp zicsr_re isa_s));
      ("Zifencei", Bool(contains_regexp zifencei_re isa_s));
    ]
  ))

let main () =
  try
    if !opt_isa_yaml = "" then
      raise (Failure "Please specify an isa yaml file using -i");
    if !opt_platform_yaml = "" then
      raise (Failure "Please specify an platform yaml file using -p");
    if !opt_file_out = "" then
      raise (Failure "Please specify an output file using -o");
  let isa_yaml = read_yaml_file !opt_isa_yaml in
  let platform_yaml = read_yaml_file !opt_platform_yaml in
  let isa_config =
    StructValue
      ("riscv_isa_config", [
         get_isa_config "ISA" isa_yaml;
         get_bool_val "hw_data_misaligned_support" isa_yaml;
         get_int_val "xlen" isa_yaml;
         get_misa_config "misa" isa_yaml;
         get_id_reg_config "mvendorid" isa_yaml;
         get_id_reg_config "marchid" isa_yaml;
         get_id_reg_config "mimpid" isa_yaml;
         get_int_val "mhartid" isa_yaml;
         get_mstatus_config "mstatus" isa_yaml;
         get_tvec_config "mtvec" isa_yaml;
         get_warl_bitmask "mideleg" ~yk:["mideleg";"bitmask"] isa_yaml;
         get_warl_bitmask "medeleg" ~yk:["medeleg";"bitmask"] isa_yaml;
         get_warl_bitmask "mip" ~yk:["mip";"bitmask"] isa_yaml;
         get_warl_bitmask "mie" ~yk:["mie";"bitmask"] isa_yaml;
         get_warl_either "mepc" isa_yaml;
         get_warl_bitmask "mcountinhibit" isa_yaml;
         get_bm_hw_config "mcounteren" isa_yaml;
         get_mhpmcounter_config "mcycle" isa_yaml;
         get_mhpmcounter_config "minstret" isa_yaml;
         get_mhpmcounter_config "mhpmcounter3" isa_yaml; 
         get_mhpmcounter_config "mhpmcounter4" isa_yaml; 
         get_mhpmcounter_config "mhpmcounter5" isa_yaml; 
         get_mhpmcounter_config "mhpmcounter6" isa_yaml; 
         get_mhpmcounter_config "mhpmcounter7" isa_yaml; 
         get_mhpmcounter_config "mhpmcounter8" isa_yaml; 
         get_mhpmcounter_config "mhpmcounter9" isa_yaml; 
         get_mhpmcounter_config "mhpmcounter10" isa_yaml;
         get_mhpmcounter_config "mhpmcounter11" isa_yaml;
         get_mhpmcounter_config "mhpmcounter12" isa_yaml;
         get_mhpmcounter_config "mhpmcounter13" isa_yaml;
         get_mhpmcounter_config "mhpmcounter14" isa_yaml;
         get_mhpmcounter_config "mhpmcounter15" isa_yaml;
         get_mhpmcounter_config "mhpmcounter16" isa_yaml;
         get_mhpmcounter_config "mhpmcounter17" isa_yaml;
         get_mhpmcounter_config "mhpmcounter18" isa_yaml;
         get_mhpmcounter_config "mhpmcounter19" isa_yaml;
         get_mhpmcounter_config "mhpmcounter20" isa_yaml;
         get_mhpmcounter_config "mhpmcounter21" isa_yaml;
         get_mhpmcounter_config "mhpmcounter22" isa_yaml;
         get_mhpmcounter_config "mhpmcounter23" isa_yaml;
         get_mhpmcounter_config "mhpmcounter24" isa_yaml;
         get_mhpmcounter_config "mhpmcounter25" isa_yaml;
         get_mhpmcounter_config "mhpmcounter26" isa_yaml;
         get_mhpmcounter_config "mhpmcounter27" isa_yaml;
         get_mhpmcounter_config "mhpmcounter28" isa_yaml;
         get_mhpmcounter_config "mhpmcounter29" isa_yaml;
         get_mhpmcounter_config "mhpmcounter30" isa_yaml;
         get_mhpmcounter_config "mhpmcounter31" isa_yaml;
         get_tvec_config "stvec" isa_yaml;
         get_warl_bitmask "sip" isa_yaml;
         get_warl_bitmask "sie" isa_yaml;
         get_bm_hw_config "scounteren" isa_yaml;
         get_warl_either "sepc" isa_yaml;
         get_satp_config "satp" isa_yaml;
      ]) in
  let platform_config =
    StructValue
      ("riscv_platform_config",
       [
         get_label_address_config "reset" platform_yaml;
         get_label_address_config "nmi" platform_yaml;
         get_address_implemented_config "mtime" platform_yaml;
         get_address_implemented_config "mtimecmp" platform_yaml;
         get_cause_config "mcause" platform_yaml;
         get_cause_config "scause" platform_yaml;
         get_mhpmevent_config "mhpmevent3" platform_yaml;
         get_mhpmevent_config "mhpmevent4" platform_yaml;
         get_mhpmevent_config "mhpmevent5" platform_yaml;
         get_mhpmevent_config "mhpmevent6" platform_yaml;
         get_mhpmevent_config "mhpmevent7" platform_yaml;
         get_mhpmevent_config "mhpmevent8" platform_yaml;
         get_mhpmevent_config "mhpmevent9" platform_yaml;
         get_mhpmevent_config "mhpmevent10" platform_yaml;
         get_mhpmevent_config "mhpmevent11" platform_yaml;
         get_mhpmevent_config "mhpmevent12" platform_yaml;
         get_mhpmevent_config "mhpmevent13" platform_yaml;
         get_mhpmevent_config "mhpmevent14" platform_yaml;
         get_mhpmevent_config "mhpmevent15" platform_yaml;
         get_mhpmevent_config "mhpmevent16" platform_yaml;
         get_mhpmevent_config "mhpmevent17" platform_yaml;
         get_mhpmevent_config "mhpmevent18" platform_yaml;
         get_mhpmevent_config "mhpmevent19" platform_yaml;
         get_mhpmevent_config "mhpmevent20" platform_yaml;
         get_mhpmevent_config "mhpmevent21" platform_yaml;
         get_mhpmevent_config "mhpmevent22" platform_yaml;
         get_mhpmevent_config "mhpmevent23" platform_yaml;
         get_mhpmevent_config "mhpmevent24" platform_yaml;
         get_mhpmevent_config "mhpmevent25" platform_yaml;
         get_mhpmevent_config "mhpmevent26" platform_yaml;
         get_mhpmevent_config "mhpmevent27" platform_yaml;
         get_mhpmevent_config "mhpmevent28" platform_yaml;
         get_mhpmevent_config "mhpmevent29" platform_yaml;
         get_mhpmevent_config "mhpmevent30" platform_yaml;
         get_mhpmevent_config "mhpmevent31" platform_yaml;
       ]
      ) in 
      let result = Bos.OS.File.write_lines Fpath.(v !opt_file_out) [
        "let isa_config : riscv_isa_config = " ^ (pp_sail_value isa_config);
        "let platform_config : riscv_platform_config = " ^ (pp_sail_value platform_config);
        "" (*final new line*)
      ] in
      match result with
      | Ok (_) -> print_endline ("OK, wrote " ^ !opt_file_out)
      | Error(`Msg s) -> (print_endline ("Failed to write " ^ !opt_file_out ^ ": " ^ s); exit 2)
  with Failure(s) -> (print_endline ("Error: " ^ s); exit 1)

let _ = main ()
