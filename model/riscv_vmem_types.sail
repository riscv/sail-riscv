// Extensions for memory Accesstype.

type ext_access_type = unit

let Data  : ext_access_type = ()

let default_write_acc : ext_access_type = Data

val accessType_to_str : AccessType(ext_access_type) -> string
function accessType_to_str (a) =
  match (a) {
    Read(_)            => "R",
    Write(_)           => "W",
    ReadWrite(_, _)    => "RW",
    Execute()          => "X"
  }

overload to_str = {accessType_to_str}
