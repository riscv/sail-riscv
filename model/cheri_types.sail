/*========================================================================*/
/*                                                                        */
/*  Copyright (c) 2015-2019 Robert M. Norton                              */
/*  Copyright (c) 2015-2017 Kathyrn Gray                                  */
/*  All rights reserved.                                                  */
/*                                                                        */
/*  This software was developed by the University of Cambridge Computer   */
/*  Laboratory as part of the Rigorous Engineering of Mainstream Systems  */
/*  (REMS) project, funded by EPSRC grant EP/K008528/1.                   */
/*                                                                        */
/*  Redistribution and use in source and binary forms, with or without    */
/*  modification, are permitted provided that the following conditions    */
/*  are met:                                                              */
/*  1. Redistributions of source code must retain the above copyright     */
/*     notice, this list of conditions and the following disclaimer.      */
/*  2. Redistributions in binary form must reproduce the above copyright  */
/*     notice, this list of conditions and the following disclaimer in    */
/*     the documentation and/or other materials provided with the         */
/*     distribution.                                                      */
/*                                                                        */
/*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''    */
/*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED     */
/*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A       */
/*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR   */
/*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,          */
/*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT      */
/*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF      */
/*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND   */
/*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,    */
/*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT    */
/*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF    */
/*  SUCH DAMAGE.                                                          */
/*========================================================================*/

type CapLen = range(0, 2 ^ 65)
type uint64 = range(0, (2 ^ 64) - 1)

enum CPtrCmpOp = {
  CEQ,
  CNE,
  CLT,
  CLE,
  CLTU,
  CLEU,
  CEXEQ,
  CNEXEQ
}

enum ClearRegSet = {
GPRegs,
FPRegs
}

let MAX_U64=MAX(64)

enum CapEx = {
  CapEx_None, 
  CapEx_LengthViolation,
  CapEx_TagViolation,
  CapEx_SealViolation,
  CapEx_TypeViolation,
  CapEx_CallTrap,
  CapEx_ReturnTrap,
  CapEx_TSSUnderFlow,
  CapEx_UserDefViolation,
  CapEx_TLBNoStoreCap,
  CapEx_InexactBounds,
  CapEx_GlobalViolation,
  CapEx_PermitExecuteViolation,
  CapEx_PermitLoadViolation,
  CapEx_PermitStoreViolation,
  CapEx_PermitLoadCapViolation,
  CapEx_PermitStoreCapViolation,
  CapEx_PermitStoreLocalCapViolation,
  CapEx_PermitSealViolation,
  CapEx_AccessSystemRegsViolation,
  CapEx_PermitCCallViolation,
  CapEx_AccessCCallIDCViolation,
  CapEx_PermitUnsealViolation,
  CapEx_PermitSetCIDViolation
}

function CapExCode(ex) : CapEx -> bits(8)=
  match ex {
    CapEx_None                          => 0x00,
    CapEx_LengthViolation               => 0x01,
    CapEx_TagViolation                  => 0x02,
    CapEx_SealViolation                 => 0x03,
    CapEx_TypeViolation                 => 0x04,
    CapEx_CallTrap                      => 0x05,
    CapEx_ReturnTrap                    => 0x06,
    CapEx_TSSUnderFlow                  => 0x07,
    CapEx_UserDefViolation              => 0x08,
    CapEx_TLBNoStoreCap                 => 0x09,
    CapEx_InexactBounds                 => 0x0a,
    CapEx_GlobalViolation               => 0x10,
    CapEx_PermitExecuteViolation        => 0x11,
    CapEx_PermitLoadViolation           => 0x12,
    CapEx_PermitStoreViolation          => 0x13,
    CapEx_PermitLoadCapViolation        => 0x14,
    CapEx_PermitStoreCapViolation       => 0x15,
    CapEx_PermitStoreLocalCapViolation  => 0x16,
    CapEx_PermitSealViolation           => 0x17,
    CapEx_AccessSystemRegsViolation     => 0x18,
    CapEx_PermitCCallViolation          => 0x19,
    CapEx_AccessCCallIDCViolation       => 0x1a,
    CapEx_PermitUnsealViolation         => 0x1b,
    CapEx_PermitSetCIDViolation         => 0x1c
  }

function string_of_capex (ex) : CapEx -> string = 
  match ex {
    CapEx_None                          => "None"                        ,
    CapEx_LengthViolation               => "LengthViolation"             ,
    CapEx_TagViolation                  => "TagViolation"                ,
    CapEx_SealViolation                 => "SealViolation"               ,
    CapEx_TypeViolation                 => "TypeViolation"               ,
    CapEx_CallTrap                      => "CallTrap"                    ,
    CapEx_ReturnTrap                    => "ReturnTrap"                  ,
    CapEx_TSSUnderFlow                  => "TSSUnderFlow"                ,
    CapEx_UserDefViolation              => "UserDefViolation"            ,
    CapEx_TLBNoStoreCap                 => "TLBNoStoreCap"               ,
    CapEx_InexactBounds                 => "InexactBounds"               ,
    CapEx_GlobalViolation               => "GlobalViolation"             ,
    CapEx_PermitExecuteViolation        => "PermitExecuteViolation"      ,
    CapEx_PermitLoadViolation           => "PermitLoadViolation"         ,
    CapEx_PermitStoreViolation          => "PermitStoreViolation"        ,
    CapEx_PermitLoadCapViolation        => "PermitLoadCapViolation"      ,
    CapEx_PermitStoreCapViolation       => "PermitStoreCapViolation"     ,
    CapEx_PermitStoreLocalCapViolation  => "PermitStoreLocalCapViolation",
    CapEx_PermitSealViolation           => "PermitSealViolation"         ,
    CapEx_AccessSystemRegsViolation     => "AccessSystemRegsViolation"   ,
    CapEx_PermitCCallViolation          => "PermitCCallViolation"        ,
    CapEx_AccessCCallIDCViolation       => "AccessCCallIDCViolation"     ,
    CapEx_PermitUnsealViolation         => "PermitUnsealViolation"       ,
    CapEx_PermitSetCIDViolation         => "PermitSetCIDViolation"
  }
