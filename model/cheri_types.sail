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

function CapExCode(ex) : CapEx -> bits(5)=
  match ex {
    CapEx_None                          => 0b00000,
    CapEx_LengthViolation               => 0b00001,
    CapEx_TagViolation                  => 0b00010,
    CapEx_SealViolation                 => 0b00011,
    CapEx_TypeViolation                 => 0b00100,
    CapEx_CallTrap                      => 0b00101,
    CapEx_ReturnTrap                    => 0b00110,
    CapEx_TSSUnderFlow                  => 0b00111,
    CapEx_UserDefViolation              => 0b01000,
    CapEx_TLBNoStoreCap                 => 0b01001,
    CapEx_InexactBounds                 => 0b01010,
    CapEx_GlobalViolation               => 0b10000,
    CapEx_PermitExecuteViolation        => 0b10001,
    CapEx_PermitLoadViolation           => 0b10010,
    CapEx_PermitStoreViolation          => 0b10011,
    CapEx_PermitLoadCapViolation        => 0b10100,
    CapEx_PermitStoreCapViolation       => 0b10101,
    CapEx_PermitStoreLocalCapViolation  => 0b10110,
    CapEx_PermitSealViolation           => 0b10111,
    CapEx_AccessSystemRegsViolation     => 0b11000,
    CapEx_PermitCCallViolation          => 0b11001,
    CapEx_AccessCCallIDCViolation       => 0b11010,
    CapEx_PermitUnsealViolation         => 0b11011,
    CapEx_PermitSetCIDViolation         => 0b11100
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
