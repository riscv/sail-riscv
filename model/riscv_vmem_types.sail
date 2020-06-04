// Extensions for memory Accesstype.

type ext_access_type_r = unit
type ext_access_type_w = unit

let RData  : ext_access_type_r = ()
let WData  : ext_access_type_w = ()

let default_write_acc : ext_access_type_w = WData

val accessType_to_str : AccessType(ext_access_type_r, ext_access_type_w) -> string
function accessType_to_str (a) =
  match (a) {
    Read(Data)           => "R",
    Write(Data)          => "W",
    ReadWrite(Data,Data) => "RW",
    Execute()            => "X"
  }

overload to_str = {accessType_to_str}
