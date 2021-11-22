/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation, Taiwan*/

/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

/* *****************************************************************/
/* ********************* auxiliary functions ***********************/
/* *****************************************************************/

/* *****************************************************************/
val PEXT_CRAS16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_CRAS16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then (rH(rs1, 1) + rH(rs2, 0)) @ (rH(rs1, 0) - rH(rs2, 1))
    else (rH(rs1, 3) + rH(rs2, 2)) @ (rH(rs1, 2) - rH(rs2, 3)) @
         (rH(rs1, 1) + rH(rs2, 0)) @ (rH(rs1, 0) - rH(rs2, 1));
  X(rd) = result;
  true
}
/* *****************************************************************/

val PEXT_RCRAS16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_RCRAS16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then radd(rH(rs1,1), rH(rs2, 0)) @ rsub(rH(rs1, 0), rH(rs2, 1))

    else radd(rH(rs1,3), rH(rs2, 2)) @ rsub(rH(rs1, 2), rH(rs2, 3)) @
         radd(rH(rs1,1), rH(rs2, 0)) @ rsub(rH(rs1, 0), rH(rs2, 1));
  X(rd) = result;
  true
}
/* *****************************************************************/

val PEXT_URCRAS16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_URCRAS16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then uradd(rH(rs1,1), rH(rs2, 0)) @ ursub(rH(rs1, 0), rH(rs2, 1))

    else uradd(rH(rs1,3), rH(rs2, 2)) @ ursub(rH(rs1, 2), rH(rs2, 3)) @
         uradd(rH(rs1,1), rH(rs2, 0)) @ ursub(rH(rs1, 0), rH(rs2, 1));
  X(rd) = result;
  true
}


/* *****************************************************************/
val PEXT_KCRAS16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_KCRAS16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then kadd(rH(rs1,1), rH(rs2, 0)) @ ksub(rH(rs1, 0), rH(rs2, 1))
      
    else kadd(rH(rs1,3), rH(rs2, 2)) @ ksub(rH(rs1, 2), rH(rs2, 3)) @
         kadd(rH(rs1,1), rH(rs2, 0)) @ ksub(rH(rs1, 0), rH(rs2, 1));
       
  X(rd) = result;
  true
}

/* *****************************************************************/
val PEXT_UKCRAS16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_UKCRAS16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then ukadd(rH(rs1,1), rH(rs2, 0)) @ uksub(rH(rs1, 0), rH(rs2, 1))
      
    else ukadd(rH(rs1,3), rH(rs2, 2)) @ uksub(rH(rs1, 2), rH(rs2, 3)) @
         ukadd(rH(rs1,1), rH(rs2, 0)) @ uksub(rH(rs1, 0), rH(rs2, 1));
       
  X(rd) = result;
  true
}

/* *****************************************************************/
val PEXT_CRSA16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_CRSA16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then (rH(rs1, 1) - rH(rs2, 0)) @ (rH(rs1, 0) + rH(rs2, 1))
    else (rH(rs1, 3) - rH(rs2, 2)) @ (rH(rs1, 2) + rH(rs2, 3)) @
         (rH(rs1, 1) - rH(rs2, 0)) @ (rH(rs1, 0) + rH(rs2, 1));
  X(rd) = result;
  true
}

/* *****************************************************************/
val PEXT_RCRSA16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_RCRSA16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then rsub(rH(rs1,1), rH(rs2, 0)) @ radd(rH(rs1, 0), rH(rs2, 1))

    else rsub(rH(rs1,3), rH(rs2, 2)) @ radd(rH(rs1, 2), rH(rs2, 3)) @
         rsub(rH(rs1,1), rH(rs2, 0)) @ radd(rH(rs1, 0), rH(rs2, 1));
  X(rd) = result;
  true
}
/* *****************************************************************/
val PEXT_URCRSA16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_URCRSA16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then ursub(rH(rs1,1), rH(rs2, 0)) @ uradd(rH(rs1, 0), rH(rs2, 1))

    else ursub(rH(rs1,3), rH(rs2, 2)) @ uradd(rH(rs1, 2), rH(rs2, 3)) @
         ursub(rH(rs1,1), rH(rs2, 0)) @ uradd(rH(rs1, 0), rH(rs2, 1));
  X(rd) = result;
  true
}

/* *****************************************************************/
val PEXT_KCRSA16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_KCRSA16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then ksub(rH(rs1,1), rH(rs2, 0)) @ kadd(rH(rs1, 0), rH(rs2, 1))
      
    else ksub(rH(rs1,3), rH(rs2, 2)) @ kadd(rH(rs1, 2), rH(rs2, 3)) @
         ksub(rH(rs1,1), rH(rs2, 0)) @ kadd(rH(rs1, 0), rH(rs2, 1));
       
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_UKCRSA16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_UKCRSA16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then uksub(rH(rs1,1), rH(rs2, 0)) @ ukadd(rH(rs1, 0), rH(rs2, 1))
      
    else uksub(rH(rs1,3), rH(rs2, 2)) @ ukadd(rH(rs1, 2), rH(rs2, 3)) @
         uksub(rH(rs1,1), rH(rs2, 0)) @ ukadd(rH(rs1, 0), rH(rs2, 1));
       
  X(rd) = result;
  true
}

/* STAS *****************************************************************/
val PEXT_STAS16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_STAS16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then (rH(rs1,1) + rH(rs2, 1)) @ (rH(rs1, 0) - rH(rs2, 0))
      
    else (rH(rs1,3) + rH(rs2, 3)) @ (rH(rs1, 2) - rH(rs2, 2)) @
         (rH(rs1,1) + rH(rs2, 1)) @ (rH(rs1, 0) - rH(rs2, 0));
       
  X(rd) = result;
  true
}
/* *****************************************************************/
val PEXT_RSTAS16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_RSTAS16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then radd(rH(rs1,1) , rH(rs2, 1)) @ rsub(rH(rs1, 0) , rH(rs2, 0))
      
    else radd(rH(rs1,3) , rH(rs2, 3)) @ rsub(rH(rs1, 2) , rH(rs2, 2)) @
         radd(rH(rs1,1) , rH(rs2, 1)) @ rsub(rH(rs1, 0) , rH(rs2, 0));
       
  X(rd) = result;
  true
}

/* *****************************************************************/
val PEXT_URSTAS16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_URSTAS16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then uradd(rH(rs1,1) , rH(rs2, 1)) @ ursub(rH(rs1, 0) , rH(rs2, 0))
      
    else uradd(rH(rs1,3) , rH(rs2, 3)) @ ursub(rH(rs1, 2) , rH(rs2, 2)) @
         uradd(rH(rs1,1) , rH(rs2, 1)) @ ursub(rH(rs1, 0) , rH(rs2, 0));
       
  X(rd) = result;
  true
}

/* *****************************************************************/
val PEXT_KSTAS16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_KSTAS16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then kadd(rH(rs1,1) , rH(rs2, 1)) @ ksub(rH(rs1, 0) , rH(rs2, 0))
      
    else kadd(rH(rs1,3) , rH(rs2, 3)) @ ksub(rH(rs1, 2) , rH(rs2, 2)) @
         kadd(rH(rs1,1) , rH(rs2, 1)) @ ksub(rH(rs1, 0) , rH(rs2, 0));
       
  X(rd) = result;
  true
}



/* *****************************************************************/

val PEXT_UKSTAS16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_UKSTAS16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then ukadd(rH(rs1,1) , rH(rs2, 1)) @ uksub(rH(rs1, 0) , rH(rs2, 0))
      
    else ukadd(rH(rs1,3) , rH(rs2, 3)) @ uksub(rH(rs1, 2) , rH(rs2, 2)) @
         ukadd(rH(rs1,1) , rH(rs2, 1)) @ uksub(rH(rs1, 0) , rH(rs2, 0));
       
  X(rd) = result;
  true
}


/* STSA *****************************************************************/

val PEXT_STSA16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_STSA16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then (rH(rs1,1) - rH(rs2, 1)) @ (rH(rs1, 0) + rH(rs2, 0))
      
    else (rH(rs1,3) - rH(rs2, 3)) @ (rH(rs1, 2) + rH(rs2, 2)) @
         (rH(rs1,1) - rH(rs2, 1)) @ (rH(rs1, 0) + rH(rs2, 0));
       
  X(rd) = result;
  true
}


  /* *****************************************************************/
val PEXT_RSTSA16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_RSTSA16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then rsub(rH(rs1,1) , rH(rs2, 1)) @ radd(rH(rs1, 0) , rH(rs2, 0))
      
    else rsub(rH(rs1,3) , rH(rs2, 3)) @ radd(rH(rs1, 2) , rH(rs2, 2)) @
         rsub(rH(rs1,1) , rH(rs2, 1)) @ radd(rH(rs1, 0) , rH(rs2, 0));
       
  X(rd) = result;
  true
}


/* *****************************************************************/
val PEXT_URSTSA16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_URSTSA16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then ursub(rH(rs1,1) , rH(rs2, 1)) @ uradd(rH(rs1, 0) , rH(rs2, 0))
      
    else ursub(rH(rs1,3) , rH(rs2, 3)) @ uradd(rH(rs1, 2) , rH(rs2, 2)) @
         ursub(rH(rs1,1) , rH(rs2, 1)) @ uradd(rH(rs1, 0) , rH(rs2, 0));
       
  X(rd) = result;
  true
}


/* *****************************************************************/
val PEXT_KSTSA16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_KSTSA16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then ksub(rH(rs1,1) , rH(rs2, 1)) @ kadd(rH(rs1, 0) , rH(rs2, 0))
      
    else ksub(rH(rs1,3) , rH(rs2, 3)) @ kadd(rH(rs1, 2) , rH(rs2, 2)) @
         ksub(rH(rs1,1) , rH(rs2, 1)) @ kadd(rH(rs1, 0) , rH(rs2, 0));
       
  X(rd) = result;
  true
}

/* *****************************************************************/
val PEXT_UKSTSA16 : (regidx, regidx, regidx) -> bool effect {escape, rreg, wreg}
function PEXT_UKSTSA16(rs2, rs1, rd) = {
  let result : xlenbits =
    if sizeof(xlen) == 32
    then uksub(rH(rs1,1) , rH(rs2, 1)) @ ukadd(rH(rs1, 0) , rH(rs2, 0))
      
    else uksub(rH(rs1,3) , rH(rs2, 3)) @ ukadd(rH(rs1, 2) , rH(rs2, 2)) @
         uksub(rH(rs1,1) , rH(rs2, 1)) @ ukadd(rH(rs1, 0) , rH(rs2, 0));
       
  X(rd) = result;
  true
}

/* *****************************************************************/

val PEXT_CRAS32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_CRAS32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    handle_illegal();
    false
    /* TODO: RETIRE_FAIL */
  } else {
    let result : xlenbits =
         (rW(rs1, 1) + rW(rs2, 0)) @ (rW(rs1, 0) - rW(rs2, 1)) ;
  X(rd) = result;
  true
  }
}
/* *****************************************************************/

val PEXT_RCRAS32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_RCRAS32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    handle_illegal();
    false
    /* TODO: RETIRE_FAIL */
  } else {
    let result : xlenbits =
         radd(rW(rs1, 1) , rW(rs2, 0)) @ rsub(rW(rs1, 0) , rW(rs2, 1)) ;
  X(rd) = result;
  true
  }
}
/* *****************************************************************/

val PEXT_URCRAS32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_URCRAS32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    handle_illegal();
    false
    /* TODO: RETIRE_FAIL */
  } else {
    let result : xlenbits =
         uradd(rW(rs1, 1) , rW(rs2, 0)) @ ursub(rW(rs1, 0) , rW(rs2, 1)) ;
  X(rd) = result;
  true
  }
}
/* *****************************************************************/

val PEXT_KCRAS32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_KCRAS32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    handle_illegal();
    false
    /* TODO: RETIRE_FAIL */
  } else {
    let result : xlenbits =
         kadd(rW(rs1, 1) , rW(rs2, 0)) @ ksub(rW(rs1, 0) , rW(rs2, 1)) ;
  X(rd) = result;
  true
  }
}
/* *****************************************************************/

val PEXT_UKCRAS32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_UKCRAS32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    handle_illegal();
    false
    /* TODO: RETIRE_FAIL */
  } else {
    let result : xlenbits =
         ukadd(rW(rs1, 1) , rW(rs2, 0)) @ uksub(rW(rs1, 0) , rW(rs2, 1)) ;
  X(rd) = result;
  true
  }
}


/************** CRSA ****************/ 

val PEXT_CRSA32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_CRSA32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    handle_illegal();
    false
    /* TODO: RETIRE_FAIL */
  } else {
    let result : xlenbits =
         (rW(rs1, 1) - rW(rs2, 0)) @ (rW(rs1, 0) + rW(rs2, 1)) ;
  X(rd) = result;
  true
  }
}
/************************/

val PEXT_RCRSA32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_RCRSA32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    handle_illegal();
    false
    /* TODO: RETIRE_FAIL */
  } else {
    let result : xlenbits =
         rsub(rW(rs1, 1) , rW(rs2, 0)) @ radd(rW(rs1, 0) , rW(rs2, 1)) ;
  X(rd) = result;
  true
  }
}
/************************/

val PEXT_URCRSA32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_URCRSA32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    handle_illegal();
    false
    /* TODO: RETIRE_FAIL */
  } else {
    let result : xlenbits =
         ursub(rW(rs1, 1) , rW(rs2, 0)) @ uradd(rW(rs1, 0) , rW(rs2, 1)) ;
  X(rd) = result;
  true
  }
}
/************************/

val PEXT_KCRSA32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_KCRSA32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    handle_illegal();
    false
    /* TODO: RETIRE_FAIL */
  } else {
    let result : xlenbits =
         ksub(rW(rs1, 1) , rW(rs2, 0)) @ kadd(rW(rs1, 0) , rW(rs2, 1)) ;
  X(rd) = result;
  true
  }
}
/************************/

val PEXT_UKCRSA32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_UKCRSA32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    handle_illegal();
    false
    /* TODO: RETIRE_FAIL */
  } else {
    let result : xlenbits =
         uksub(rW(rs1, 1) , rW(rs2, 0)) @ ukadd(rW(rs1, 0) , rW(rs2, 1)) ;
  X(rd) = result;
  true
  }
}

/************** STAS  **********/


val PEXT_STAS32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_STAS32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    handle_illegal();
    false
    /* TODO: RETIRE_FAIL */
  } else {
    let result : xlenbits =
         (rW(rs1, 1) + rW(rs2, 1)) @ (rW(rs1, 0) - rW(rs2, 0)) ;
  X(rd) = result;
  true
  }
}
/************************/

val PEXT_RSTAS32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_RSTAS32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    handle_illegal();
    false
    /* TODO: RETIRE_FAIL */
  } else {
    let result : xlenbits =
         radd(rW(rs1, 1) , rW(rs2, 1)) @ rsub(rW(rs1, 0) , rW(rs2, 0)) ;
  X(rd) = result;
  true
  }
}
/************************/

val PEXT_URSTAS32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_URSTAS32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    handle_illegal();
    false
    /* TODO: RETIRE_FAIL */
  } else {
    let result : xlenbits =
         uradd(rW(rs1, 1) , rW(rs2, 1)) @ ursub(rW(rs1, 0) , rW(rs2, 0)) ;
  X(rd) = result;
  true
  }
}
/************************/

val PEXT_KSTAS32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_KSTAS32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    handle_illegal();
    false
    /* TODO: RETIRE_FAIL */
  } else {
    let result : xlenbits =
         kadd(rW(rs1, 1) , rW(rs2, 1)) @ ksub(rW(rs1, 0) , rW(rs2, 0)) ;
  X(rd) = result;
  true
  }
}
/************************/

val PEXT_UKSTAS32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_UKSTAS32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    handle_illegal();
    false
    /* TODO: RETIRE_FAIL */
  } else {
    let result : xlenbits =
         ukadd(rW(rs1, 1) , rW(rs2, 1)) @ uksub(rW(rs1, 0) , rW(rs2, 0)) ;
  X(rd) = result;
  true
  }
}

/*********** STSA *************/

val PEXT_STSA32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_STSA32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    handle_illegal();
    false
    /* TODO: RETIRE_FAIL */
  } else {
    let result : xlenbits =
         (rW(rs1, 1) - rW(rs2, 1)) @ (rW(rs1, 0) + rW(rs2, 0)) ;
  X(rd) = result;
  true
  }
}
/************************/

val PEXT_RSTSA32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_RSTSA32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    handle_illegal();
    false
    /* TODO: RETIRE_FAIL */
  } else {
    let result : xlenbits =
         rsub(rW(rs1, 1) , rW(rs2, 1)) @ radd(rW(rs1, 0) , rW(rs2, 0)) ;
  X(rd) = result;
  true
  }
}
/************************/

val PEXT_URSTSA32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_URSTSA32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    handle_illegal();
    false
    /* TODO: RETIRE_FAIL */
  } else {
    let result : xlenbits =
         ursub(rW(rs1, 1) , rW(rs2, 1)) @ uradd(rW(rs1, 0) , rW(rs2, 0)) ;
  X(rd) = result;
  true
  }
}
/************************/

val PEXT_KSTSA32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_KSTSA32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    handle_illegal();
    false
    /* TODO: RETIRE_FAIL */
  } else {
    let result : xlenbits =
         ksub(rW(rs1, 1) , rW(rs2, 1)) @ kadd(rW(rs1, 0) , rW(rs2, 0)) ;
  X(rd) = result;
  true
  }
}
/************************/

val PEXT_UKSTSA32 : (regidx, regidx, regidx) -> bool
  effect {escape, rreg, wreg}
function PEXT_UKSTSA32 (rs2, rs1, rd) = {
  if sizeof (xlen) == 32 then {
    handle_illegal();
    false
    /* TODO: RETIRE_FAIL */
  } else {
    let result : xlenbits =
         uksub(rW(rs1, 1) , rW(rs2, 1)) @ ukadd(rW(rs1, 0) , rW(rs2, 0)) ;
  X(rd) = result;
  true
  }
}