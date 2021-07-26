theory Riscv_lemmas
  imports
    Sail.Sail2_values_lemmas
    Sail.Sail2_state_lemmas
    Riscv
begin

abbreviation liftS ("\<lbrakk>_\<rbrakk>\<^sub>S") where "liftS \<equiv> liftState (get_regval, set_regval)"

lemmas register_defs = get_regval_def set_regval_def satp_ref_def tlb32_ref_def
  htif_payload_writes_ref_def htif_cmd_write_ref_def htif_exit_code_ref_def htif_done_ref_def
  htif_tohost_ref_def mtimecmp_ref_def fcsr_ref_def f31_ref_def f30_ref_def f29_ref_def f28_ref_def
  f27_ref_def f26_ref_def f25_ref_def f24_ref_def f23_ref_def f22_ref_def f21_ref_def f20_ref_def
  f19_ref_def f18_ref_def f17_ref_def f16_ref_def f15_ref_def f14_ref_def f13_ref_def f12_ref_def
  f11_ref_def f10_ref_def f9_ref_def f8_ref_def f7_ref_def f6_ref_def f5_ref_def f4_ref_def
  f3_ref_def f2_ref_def f1_ref_def f0_ref_def float_fflags_ref_def float_result_ref_def
  utval_ref_def ucause_ref_def uepc_ref_def uscratch_ref_def utvec_ref_def pmpaddr15_ref_def
  pmpaddr14_ref_def pmpaddr13_ref_def pmpaddr12_ref_def pmpaddr11_ref_def pmpaddr10_ref_def
  pmpaddr9_ref_def pmpaddr8_ref_def pmpaddr7_ref_def pmpaddr6_ref_def pmpaddr5_ref_def
  pmpaddr4_ref_def pmpaddr3_ref_def pmpaddr2_ref_def pmpaddr1_ref_def pmpaddr0_ref_def
  pmp15cfg_ref_def pmp14cfg_ref_def pmp13cfg_ref_def pmp12cfg_ref_def pmp11cfg_ref_def
  pmp10cfg_ref_def pmp9cfg_ref_def pmp8cfg_ref_def pmp7cfg_ref_def pmp6cfg_ref_def pmp5cfg_ref_def
  pmp4cfg_ref_def pmp3cfg_ref_def pmp2cfg_ref_def pmp1cfg_ref_def pmp0cfg_ref_def tselect_ref_def
  stval_ref_def scause_ref_def sepc_ref_def sscratch_ref_def stvec_ref_def sideleg_ref_def
  sedeleg_ref_def mhartid_ref_def marchid_ref_def mimpid_ref_def mvendorid_ref_def
  minstret_written_ref_def minstret_ref_def mtime_ref_def mcycle_ref_def mcountinhibit_ref_def
  scounteren_ref_def mcounteren_ref_def mscratch_ref_def mtval_ref_def mepc_ref_def mcause_ref_def
  mtvec_ref_def medeleg_ref_def mideleg_ref_def mie_ref_def mip_ref_def mstatus_ref_def
  mstatush_ref_def misa_ref_def cur_inst_ref_def cur_privilege_ref_def x31_ref_def x30_ref_def
  x29_ref_def x28_ref_def x27_ref_def x26_ref_def x25_ref_def x24_ref_def x23_ref_def x22_ref_def
  x21_ref_def x20_ref_def x19_ref_def x18_ref_def x17_ref_def x16_ref_def x15_ref_def x14_ref_def
  x13_ref_def x12_ref_def x11_ref_def x10_ref_def x9_ref_def x8_ref_def x7_ref_def x6_ref_def
  x5_ref_def x4_ref_def x3_ref_def x2_ref_def x1_ref_def instbits_ref_def nextPC_ref_def PC_ref_def

lemma regval_Counteren[simp]:
  "Counteren_of_regval (regval_of_Counteren v) = Some v"
  by (auto simp: regval_of_Counteren_def)

lemma regval_Counterin[simp]:
  "Counterin_of_regval (regval_of_Counterin v) = Some v"
  by (auto simp: regval_of_Counterin_def)

lemma regval_Fcsr[simp]:
  "Fcsr_of_regval (regval_of_Fcsr v) = Some v"
  by (auto simp: regval_of_Fcsr_def)

lemma regval_Mcause[simp]:
  "Mcause_of_regval (regval_of_Mcause v) = Some v"
  by (auto simp: regval_of_Mcause_def)

lemma regval_Medeleg[simp]:
  "Medeleg_of_regval (regval_of_Medeleg v) = Some v"
  by (auto simp: regval_of_Medeleg_def)

lemma regval_Minterrupts[simp]:
  "Minterrupts_of_regval (regval_of_Minterrupts v) = Some v"
  by (auto simp: regval_of_Minterrupts_def)

lemma regval_Misa[simp]:
  "Misa_of_regval (regval_of_Misa v) = Some v"
  by (auto simp: regval_of_Misa_def)

lemma regval_Mstatus[simp]:
  "Mstatus_of_regval (regval_of_Mstatus v) = Some v"
  by (auto simp: regval_of_Mstatus_def)

lemma regval_Mstatush[simp]:
  "Mstatush_of_regval (regval_of_Mstatush v) = Some v"
  by (auto simp: regval_of_Mstatush_def)

lemma regval_Mtvec[simp]:
  "Mtvec_of_regval (regval_of_Mtvec v) = Some v"
  by (auto simp: regval_of_Mtvec_def)

lemma regval_Pmpcfg_ent[simp]:
  "Pmpcfg_ent_of_regval (regval_of_Pmpcfg_ent v) = Some v"
  by (auto simp: regval_of_Pmpcfg_ent_def)

lemma regval_Privilege[simp]:
  "Privilege_of_regval (regval_of_Privilege v) = Some v"
  by (auto simp: regval_of_Privilege_def)

lemma regval_Sedeleg[simp]:
  "Sedeleg_of_regval (regval_of_Sedeleg v) = Some v"
  by (auto simp: regval_of_Sedeleg_def)

lemma regval_Sinterrupts[simp]:
  "Sinterrupts_of_regval (regval_of_Sinterrupts v) = Some v"
  by (auto simp: regval_of_Sinterrupts_def)

lemma regval_TLB_Entry_9_32_34_32[simp]:
  "TLB_Entry_9_32_34_32_of_regval (regval_of_TLB_Entry_9_32_34_32 v) = Some v"
  by (auto simp: regval_of_TLB_Entry_9_32_34_32_def)

lemma regval_bit[simp]:
  "bit_of_regval (regval_of_bit v) = Some v"
  by (auto simp: regval_of_bit_def)

lemma regval_bitvector_32_dec[simp]:
  "bitvector_32_dec_of_regval (regval_of_bitvector_32_dec v) = Some v"
  by (auto simp: regval_of_bitvector_32_dec_def)

lemma regval_bitvector_4_dec[simp]:
  "bitvector_4_dec_of_regval (regval_of_bitvector_4_dec v) = Some v"
  by (auto simp: regval_of_bitvector_4_dec_def)

lemma regval_bitvector_64_dec[simp]:
  "bitvector_64_dec_of_regval (regval_of_bitvector_64_dec v) = Some v"
  by (auto simp: regval_of_bitvector_64_dec_def)

lemma regval_bool[simp]:
  "bool_of_regval (regval_of_bool v) = Some v"
  by (auto simp: regval_of_bool_def)

lemma vector_of_rv_rv_of_vector[simp]:
  assumes "\<And>v. of_rv (rv_of v) = Some v"
  shows "vector_of_regval of_rv (regval_of_vector rv_of v) = Some v"
proof -
  from assms have "of_rv \<circ> rv_of = Some" by auto
  then show ?thesis by (auto simp: vector_of_regval_def regval_of_vector_def)
qed

lemma option_of_rv_rv_of_option[simp]:
  assumes "\<And>v. of_rv (rv_of v) = Some v"
  shows "option_of_regval of_rv (regval_of_option rv_of v) = Some v"
  using assms by (cases v) (auto simp: option_of_regval_def regval_of_option_def)

lemma list_of_rv_rv_of_list[simp]:
  assumes "\<And>v. of_rv (rv_of v) = Some v"
  shows "list_of_regval of_rv (regval_of_list rv_of v) = Some v"
proof -
  from assms have "of_rv \<circ> rv_of = Some" by auto
  with assms show ?thesis by (induction v) (auto simp: list_of_regval_def regval_of_list_def)
qed

lemma liftS_read_reg_satp[liftState_simp]:
  "\<lbrakk>read_reg satp_ref\<rbrakk>\<^sub>S = read_regS satp_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_satp[liftState_simp]:
  "\<lbrakk>write_reg satp_ref v\<rbrakk>\<^sub>S = write_regS satp_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_tlb32[liftState_simp]:
  "\<lbrakk>read_reg tlb32_ref\<rbrakk>\<^sub>S = read_regS tlb32_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_tlb32[liftState_simp]:
  "\<lbrakk>write_reg tlb32_ref v\<rbrakk>\<^sub>S = write_regS tlb32_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_htif_payload_writes[liftState_simp]:
  "\<lbrakk>read_reg htif_payload_writes_ref\<rbrakk>\<^sub>S = read_regS htif_payload_writes_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_htif_payload_writes[liftState_simp]:
  "\<lbrakk>write_reg htif_payload_writes_ref v\<rbrakk>\<^sub>S = write_regS htif_payload_writes_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_htif_cmd_write[liftState_simp]:
  "\<lbrakk>read_reg htif_cmd_write_ref\<rbrakk>\<^sub>S = read_regS htif_cmd_write_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_htif_cmd_write[liftState_simp]:
  "\<lbrakk>write_reg htif_cmd_write_ref v\<rbrakk>\<^sub>S = write_regS htif_cmd_write_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_htif_exit_code[liftState_simp]:
  "\<lbrakk>read_reg htif_exit_code_ref\<rbrakk>\<^sub>S = read_regS htif_exit_code_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_htif_exit_code[liftState_simp]:
  "\<lbrakk>write_reg htif_exit_code_ref v\<rbrakk>\<^sub>S = write_regS htif_exit_code_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_htif_done[liftState_simp]:
  "\<lbrakk>read_reg htif_done_ref\<rbrakk>\<^sub>S = read_regS htif_done_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_htif_done[liftState_simp]:
  "\<lbrakk>write_reg htif_done_ref v\<rbrakk>\<^sub>S = write_regS htif_done_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_htif_tohost[liftState_simp]:
  "\<lbrakk>read_reg htif_tohost_ref\<rbrakk>\<^sub>S = read_regS htif_tohost_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_htif_tohost[liftState_simp]:
  "\<lbrakk>write_reg htif_tohost_ref v\<rbrakk>\<^sub>S = write_regS htif_tohost_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_mtimecmp[liftState_simp]:
  "\<lbrakk>read_reg mtimecmp_ref\<rbrakk>\<^sub>S = read_regS mtimecmp_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_mtimecmp[liftState_simp]:
  "\<lbrakk>write_reg mtimecmp_ref v\<rbrakk>\<^sub>S = write_regS mtimecmp_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_fcsr[liftState_simp]:
  "\<lbrakk>read_reg fcsr_ref\<rbrakk>\<^sub>S = read_regS fcsr_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_fcsr[liftState_simp]:
  "\<lbrakk>write_reg fcsr_ref v\<rbrakk>\<^sub>S = write_regS fcsr_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f31[liftState_simp]:
  "\<lbrakk>read_reg f31_ref\<rbrakk>\<^sub>S = read_regS f31_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f31[liftState_simp]:
  "\<lbrakk>write_reg f31_ref v\<rbrakk>\<^sub>S = write_regS f31_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f30[liftState_simp]:
  "\<lbrakk>read_reg f30_ref\<rbrakk>\<^sub>S = read_regS f30_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f30[liftState_simp]:
  "\<lbrakk>write_reg f30_ref v\<rbrakk>\<^sub>S = write_regS f30_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f29[liftState_simp]:
  "\<lbrakk>read_reg f29_ref\<rbrakk>\<^sub>S = read_regS f29_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f29[liftState_simp]:
  "\<lbrakk>write_reg f29_ref v\<rbrakk>\<^sub>S = write_regS f29_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f28[liftState_simp]:
  "\<lbrakk>read_reg f28_ref\<rbrakk>\<^sub>S = read_regS f28_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f28[liftState_simp]:
  "\<lbrakk>write_reg f28_ref v\<rbrakk>\<^sub>S = write_regS f28_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f27[liftState_simp]:
  "\<lbrakk>read_reg f27_ref\<rbrakk>\<^sub>S = read_regS f27_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f27[liftState_simp]:
  "\<lbrakk>write_reg f27_ref v\<rbrakk>\<^sub>S = write_regS f27_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f26[liftState_simp]:
  "\<lbrakk>read_reg f26_ref\<rbrakk>\<^sub>S = read_regS f26_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f26[liftState_simp]:
  "\<lbrakk>write_reg f26_ref v\<rbrakk>\<^sub>S = write_regS f26_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f25[liftState_simp]:
  "\<lbrakk>read_reg f25_ref\<rbrakk>\<^sub>S = read_regS f25_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f25[liftState_simp]:
  "\<lbrakk>write_reg f25_ref v\<rbrakk>\<^sub>S = write_regS f25_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f24[liftState_simp]:
  "\<lbrakk>read_reg f24_ref\<rbrakk>\<^sub>S = read_regS f24_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f24[liftState_simp]:
  "\<lbrakk>write_reg f24_ref v\<rbrakk>\<^sub>S = write_regS f24_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f23[liftState_simp]:
  "\<lbrakk>read_reg f23_ref\<rbrakk>\<^sub>S = read_regS f23_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f23[liftState_simp]:
  "\<lbrakk>write_reg f23_ref v\<rbrakk>\<^sub>S = write_regS f23_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f22[liftState_simp]:
  "\<lbrakk>read_reg f22_ref\<rbrakk>\<^sub>S = read_regS f22_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f22[liftState_simp]:
  "\<lbrakk>write_reg f22_ref v\<rbrakk>\<^sub>S = write_regS f22_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f21[liftState_simp]:
  "\<lbrakk>read_reg f21_ref\<rbrakk>\<^sub>S = read_regS f21_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f21[liftState_simp]:
  "\<lbrakk>write_reg f21_ref v\<rbrakk>\<^sub>S = write_regS f21_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f20[liftState_simp]:
  "\<lbrakk>read_reg f20_ref\<rbrakk>\<^sub>S = read_regS f20_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f20[liftState_simp]:
  "\<lbrakk>write_reg f20_ref v\<rbrakk>\<^sub>S = write_regS f20_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f19[liftState_simp]:
  "\<lbrakk>read_reg f19_ref\<rbrakk>\<^sub>S = read_regS f19_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f19[liftState_simp]:
  "\<lbrakk>write_reg f19_ref v\<rbrakk>\<^sub>S = write_regS f19_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f18[liftState_simp]:
  "\<lbrakk>read_reg f18_ref\<rbrakk>\<^sub>S = read_regS f18_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f18[liftState_simp]:
  "\<lbrakk>write_reg f18_ref v\<rbrakk>\<^sub>S = write_regS f18_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f17[liftState_simp]:
  "\<lbrakk>read_reg f17_ref\<rbrakk>\<^sub>S = read_regS f17_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f17[liftState_simp]:
  "\<lbrakk>write_reg f17_ref v\<rbrakk>\<^sub>S = write_regS f17_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f16[liftState_simp]:
  "\<lbrakk>read_reg f16_ref\<rbrakk>\<^sub>S = read_regS f16_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f16[liftState_simp]:
  "\<lbrakk>write_reg f16_ref v\<rbrakk>\<^sub>S = write_regS f16_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f15[liftState_simp]:
  "\<lbrakk>read_reg f15_ref\<rbrakk>\<^sub>S = read_regS f15_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f15[liftState_simp]:
  "\<lbrakk>write_reg f15_ref v\<rbrakk>\<^sub>S = write_regS f15_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f14[liftState_simp]:
  "\<lbrakk>read_reg f14_ref\<rbrakk>\<^sub>S = read_regS f14_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f14[liftState_simp]:
  "\<lbrakk>write_reg f14_ref v\<rbrakk>\<^sub>S = write_regS f14_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f13[liftState_simp]:
  "\<lbrakk>read_reg f13_ref\<rbrakk>\<^sub>S = read_regS f13_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f13[liftState_simp]:
  "\<lbrakk>write_reg f13_ref v\<rbrakk>\<^sub>S = write_regS f13_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f12[liftState_simp]:
  "\<lbrakk>read_reg f12_ref\<rbrakk>\<^sub>S = read_regS f12_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f12[liftState_simp]:
  "\<lbrakk>write_reg f12_ref v\<rbrakk>\<^sub>S = write_regS f12_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f11[liftState_simp]:
  "\<lbrakk>read_reg f11_ref\<rbrakk>\<^sub>S = read_regS f11_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f11[liftState_simp]:
  "\<lbrakk>write_reg f11_ref v\<rbrakk>\<^sub>S = write_regS f11_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f10[liftState_simp]:
  "\<lbrakk>read_reg f10_ref\<rbrakk>\<^sub>S = read_regS f10_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f10[liftState_simp]:
  "\<lbrakk>write_reg f10_ref v\<rbrakk>\<^sub>S = write_regS f10_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f9[liftState_simp]:
  "\<lbrakk>read_reg f9_ref\<rbrakk>\<^sub>S = read_regS f9_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f9[liftState_simp]:
  "\<lbrakk>write_reg f9_ref v\<rbrakk>\<^sub>S = write_regS f9_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f8[liftState_simp]:
  "\<lbrakk>read_reg f8_ref\<rbrakk>\<^sub>S = read_regS f8_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f8[liftState_simp]:
  "\<lbrakk>write_reg f8_ref v\<rbrakk>\<^sub>S = write_regS f8_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f7[liftState_simp]:
  "\<lbrakk>read_reg f7_ref\<rbrakk>\<^sub>S = read_regS f7_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f7[liftState_simp]:
  "\<lbrakk>write_reg f7_ref v\<rbrakk>\<^sub>S = write_regS f7_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f6[liftState_simp]:
  "\<lbrakk>read_reg f6_ref\<rbrakk>\<^sub>S = read_regS f6_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f6[liftState_simp]:
  "\<lbrakk>write_reg f6_ref v\<rbrakk>\<^sub>S = write_regS f6_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f5[liftState_simp]:
  "\<lbrakk>read_reg f5_ref\<rbrakk>\<^sub>S = read_regS f5_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f5[liftState_simp]:
  "\<lbrakk>write_reg f5_ref v\<rbrakk>\<^sub>S = write_regS f5_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f4[liftState_simp]:
  "\<lbrakk>read_reg f4_ref\<rbrakk>\<^sub>S = read_regS f4_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f4[liftState_simp]:
  "\<lbrakk>write_reg f4_ref v\<rbrakk>\<^sub>S = write_regS f4_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f3[liftState_simp]:
  "\<lbrakk>read_reg f3_ref\<rbrakk>\<^sub>S = read_regS f3_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f3[liftState_simp]:
  "\<lbrakk>write_reg f3_ref v\<rbrakk>\<^sub>S = write_regS f3_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f2[liftState_simp]:
  "\<lbrakk>read_reg f2_ref\<rbrakk>\<^sub>S = read_regS f2_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f2[liftState_simp]:
  "\<lbrakk>write_reg f2_ref v\<rbrakk>\<^sub>S = write_regS f2_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f1[liftState_simp]:
  "\<lbrakk>read_reg f1_ref\<rbrakk>\<^sub>S = read_regS f1_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f1[liftState_simp]:
  "\<lbrakk>write_reg f1_ref v\<rbrakk>\<^sub>S = write_regS f1_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_f0[liftState_simp]:
  "\<lbrakk>read_reg f0_ref\<rbrakk>\<^sub>S = read_regS f0_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_f0[liftState_simp]:
  "\<lbrakk>write_reg f0_ref v\<rbrakk>\<^sub>S = write_regS f0_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_float_fflags[liftState_simp]:
  "\<lbrakk>read_reg float_fflags_ref\<rbrakk>\<^sub>S = read_regS float_fflags_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_float_fflags[liftState_simp]:
  "\<lbrakk>write_reg float_fflags_ref v\<rbrakk>\<^sub>S = write_regS float_fflags_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_float_result[liftState_simp]:
  "\<lbrakk>read_reg float_result_ref\<rbrakk>\<^sub>S = read_regS float_result_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_float_result[liftState_simp]:
  "\<lbrakk>write_reg float_result_ref v\<rbrakk>\<^sub>S = write_regS float_result_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_utval[liftState_simp]:
  "\<lbrakk>read_reg utval_ref\<rbrakk>\<^sub>S = read_regS utval_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_utval[liftState_simp]:
  "\<lbrakk>write_reg utval_ref v\<rbrakk>\<^sub>S = write_regS utval_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_ucause[liftState_simp]:
  "\<lbrakk>read_reg ucause_ref\<rbrakk>\<^sub>S = read_regS ucause_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_ucause[liftState_simp]:
  "\<lbrakk>write_reg ucause_ref v\<rbrakk>\<^sub>S = write_regS ucause_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_uepc[liftState_simp]:
  "\<lbrakk>read_reg uepc_ref\<rbrakk>\<^sub>S = read_regS uepc_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_uepc[liftState_simp]:
  "\<lbrakk>write_reg uepc_ref v\<rbrakk>\<^sub>S = write_regS uepc_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_uscratch[liftState_simp]:
  "\<lbrakk>read_reg uscratch_ref\<rbrakk>\<^sub>S = read_regS uscratch_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_uscratch[liftState_simp]:
  "\<lbrakk>write_reg uscratch_ref v\<rbrakk>\<^sub>S = write_regS uscratch_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_utvec[liftState_simp]:
  "\<lbrakk>read_reg utvec_ref\<rbrakk>\<^sub>S = read_regS utvec_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_utvec[liftState_simp]:
  "\<lbrakk>write_reg utvec_ref v\<rbrakk>\<^sub>S = write_regS utvec_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmpaddr15[liftState_simp]:
  "\<lbrakk>read_reg pmpaddr15_ref\<rbrakk>\<^sub>S = read_regS pmpaddr15_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmpaddr15[liftState_simp]:
  "\<lbrakk>write_reg pmpaddr15_ref v\<rbrakk>\<^sub>S = write_regS pmpaddr15_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmpaddr14[liftState_simp]:
  "\<lbrakk>read_reg pmpaddr14_ref\<rbrakk>\<^sub>S = read_regS pmpaddr14_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmpaddr14[liftState_simp]:
  "\<lbrakk>write_reg pmpaddr14_ref v\<rbrakk>\<^sub>S = write_regS pmpaddr14_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmpaddr13[liftState_simp]:
  "\<lbrakk>read_reg pmpaddr13_ref\<rbrakk>\<^sub>S = read_regS pmpaddr13_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmpaddr13[liftState_simp]:
  "\<lbrakk>write_reg pmpaddr13_ref v\<rbrakk>\<^sub>S = write_regS pmpaddr13_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmpaddr12[liftState_simp]:
  "\<lbrakk>read_reg pmpaddr12_ref\<rbrakk>\<^sub>S = read_regS pmpaddr12_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmpaddr12[liftState_simp]:
  "\<lbrakk>write_reg pmpaddr12_ref v\<rbrakk>\<^sub>S = write_regS pmpaddr12_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmpaddr11[liftState_simp]:
  "\<lbrakk>read_reg pmpaddr11_ref\<rbrakk>\<^sub>S = read_regS pmpaddr11_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmpaddr11[liftState_simp]:
  "\<lbrakk>write_reg pmpaddr11_ref v\<rbrakk>\<^sub>S = write_regS pmpaddr11_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmpaddr10[liftState_simp]:
  "\<lbrakk>read_reg pmpaddr10_ref\<rbrakk>\<^sub>S = read_regS pmpaddr10_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmpaddr10[liftState_simp]:
  "\<lbrakk>write_reg pmpaddr10_ref v\<rbrakk>\<^sub>S = write_regS pmpaddr10_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmpaddr9[liftState_simp]:
  "\<lbrakk>read_reg pmpaddr9_ref\<rbrakk>\<^sub>S = read_regS pmpaddr9_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmpaddr9[liftState_simp]:
  "\<lbrakk>write_reg pmpaddr9_ref v\<rbrakk>\<^sub>S = write_regS pmpaddr9_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmpaddr8[liftState_simp]:
  "\<lbrakk>read_reg pmpaddr8_ref\<rbrakk>\<^sub>S = read_regS pmpaddr8_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmpaddr8[liftState_simp]:
  "\<lbrakk>write_reg pmpaddr8_ref v\<rbrakk>\<^sub>S = write_regS pmpaddr8_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmpaddr7[liftState_simp]:
  "\<lbrakk>read_reg pmpaddr7_ref\<rbrakk>\<^sub>S = read_regS pmpaddr7_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmpaddr7[liftState_simp]:
  "\<lbrakk>write_reg pmpaddr7_ref v\<rbrakk>\<^sub>S = write_regS pmpaddr7_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmpaddr6[liftState_simp]:
  "\<lbrakk>read_reg pmpaddr6_ref\<rbrakk>\<^sub>S = read_regS pmpaddr6_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmpaddr6[liftState_simp]:
  "\<lbrakk>write_reg pmpaddr6_ref v\<rbrakk>\<^sub>S = write_regS pmpaddr6_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmpaddr5[liftState_simp]:
  "\<lbrakk>read_reg pmpaddr5_ref\<rbrakk>\<^sub>S = read_regS pmpaddr5_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmpaddr5[liftState_simp]:
  "\<lbrakk>write_reg pmpaddr5_ref v\<rbrakk>\<^sub>S = write_regS pmpaddr5_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmpaddr4[liftState_simp]:
  "\<lbrakk>read_reg pmpaddr4_ref\<rbrakk>\<^sub>S = read_regS pmpaddr4_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmpaddr4[liftState_simp]:
  "\<lbrakk>write_reg pmpaddr4_ref v\<rbrakk>\<^sub>S = write_regS pmpaddr4_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmpaddr3[liftState_simp]:
  "\<lbrakk>read_reg pmpaddr3_ref\<rbrakk>\<^sub>S = read_regS pmpaddr3_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmpaddr3[liftState_simp]:
  "\<lbrakk>write_reg pmpaddr3_ref v\<rbrakk>\<^sub>S = write_regS pmpaddr3_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmpaddr2[liftState_simp]:
  "\<lbrakk>read_reg pmpaddr2_ref\<rbrakk>\<^sub>S = read_regS pmpaddr2_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmpaddr2[liftState_simp]:
  "\<lbrakk>write_reg pmpaddr2_ref v\<rbrakk>\<^sub>S = write_regS pmpaddr2_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmpaddr1[liftState_simp]:
  "\<lbrakk>read_reg pmpaddr1_ref\<rbrakk>\<^sub>S = read_regS pmpaddr1_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmpaddr1[liftState_simp]:
  "\<lbrakk>write_reg pmpaddr1_ref v\<rbrakk>\<^sub>S = write_regS pmpaddr1_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmpaddr0[liftState_simp]:
  "\<lbrakk>read_reg pmpaddr0_ref\<rbrakk>\<^sub>S = read_regS pmpaddr0_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmpaddr0[liftState_simp]:
  "\<lbrakk>write_reg pmpaddr0_ref v\<rbrakk>\<^sub>S = write_regS pmpaddr0_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmp15cfg[liftState_simp]:
  "\<lbrakk>read_reg pmp15cfg_ref\<rbrakk>\<^sub>S = read_regS pmp15cfg_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmp15cfg[liftState_simp]:
  "\<lbrakk>write_reg pmp15cfg_ref v\<rbrakk>\<^sub>S = write_regS pmp15cfg_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmp14cfg[liftState_simp]:
  "\<lbrakk>read_reg pmp14cfg_ref\<rbrakk>\<^sub>S = read_regS pmp14cfg_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmp14cfg[liftState_simp]:
  "\<lbrakk>write_reg pmp14cfg_ref v\<rbrakk>\<^sub>S = write_regS pmp14cfg_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmp13cfg[liftState_simp]:
  "\<lbrakk>read_reg pmp13cfg_ref\<rbrakk>\<^sub>S = read_regS pmp13cfg_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmp13cfg[liftState_simp]:
  "\<lbrakk>write_reg pmp13cfg_ref v\<rbrakk>\<^sub>S = write_regS pmp13cfg_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmp12cfg[liftState_simp]:
  "\<lbrakk>read_reg pmp12cfg_ref\<rbrakk>\<^sub>S = read_regS pmp12cfg_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmp12cfg[liftState_simp]:
  "\<lbrakk>write_reg pmp12cfg_ref v\<rbrakk>\<^sub>S = write_regS pmp12cfg_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmp11cfg[liftState_simp]:
  "\<lbrakk>read_reg pmp11cfg_ref\<rbrakk>\<^sub>S = read_regS pmp11cfg_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmp11cfg[liftState_simp]:
  "\<lbrakk>write_reg pmp11cfg_ref v\<rbrakk>\<^sub>S = write_regS pmp11cfg_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmp10cfg[liftState_simp]:
  "\<lbrakk>read_reg pmp10cfg_ref\<rbrakk>\<^sub>S = read_regS pmp10cfg_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmp10cfg[liftState_simp]:
  "\<lbrakk>write_reg pmp10cfg_ref v\<rbrakk>\<^sub>S = write_regS pmp10cfg_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmp9cfg[liftState_simp]:
  "\<lbrakk>read_reg pmp9cfg_ref\<rbrakk>\<^sub>S = read_regS pmp9cfg_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmp9cfg[liftState_simp]:
  "\<lbrakk>write_reg pmp9cfg_ref v\<rbrakk>\<^sub>S = write_regS pmp9cfg_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmp8cfg[liftState_simp]:
  "\<lbrakk>read_reg pmp8cfg_ref\<rbrakk>\<^sub>S = read_regS pmp8cfg_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmp8cfg[liftState_simp]:
  "\<lbrakk>write_reg pmp8cfg_ref v\<rbrakk>\<^sub>S = write_regS pmp8cfg_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmp7cfg[liftState_simp]:
  "\<lbrakk>read_reg pmp7cfg_ref\<rbrakk>\<^sub>S = read_regS pmp7cfg_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmp7cfg[liftState_simp]:
  "\<lbrakk>write_reg pmp7cfg_ref v\<rbrakk>\<^sub>S = write_regS pmp7cfg_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmp6cfg[liftState_simp]:
  "\<lbrakk>read_reg pmp6cfg_ref\<rbrakk>\<^sub>S = read_regS pmp6cfg_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmp6cfg[liftState_simp]:
  "\<lbrakk>write_reg pmp6cfg_ref v\<rbrakk>\<^sub>S = write_regS pmp6cfg_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmp5cfg[liftState_simp]:
  "\<lbrakk>read_reg pmp5cfg_ref\<rbrakk>\<^sub>S = read_regS pmp5cfg_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmp5cfg[liftState_simp]:
  "\<lbrakk>write_reg pmp5cfg_ref v\<rbrakk>\<^sub>S = write_regS pmp5cfg_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmp4cfg[liftState_simp]:
  "\<lbrakk>read_reg pmp4cfg_ref\<rbrakk>\<^sub>S = read_regS pmp4cfg_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmp4cfg[liftState_simp]:
  "\<lbrakk>write_reg pmp4cfg_ref v\<rbrakk>\<^sub>S = write_regS pmp4cfg_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmp3cfg[liftState_simp]:
  "\<lbrakk>read_reg pmp3cfg_ref\<rbrakk>\<^sub>S = read_regS pmp3cfg_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmp3cfg[liftState_simp]:
  "\<lbrakk>write_reg pmp3cfg_ref v\<rbrakk>\<^sub>S = write_regS pmp3cfg_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmp2cfg[liftState_simp]:
  "\<lbrakk>read_reg pmp2cfg_ref\<rbrakk>\<^sub>S = read_regS pmp2cfg_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmp2cfg[liftState_simp]:
  "\<lbrakk>write_reg pmp2cfg_ref v\<rbrakk>\<^sub>S = write_regS pmp2cfg_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmp1cfg[liftState_simp]:
  "\<lbrakk>read_reg pmp1cfg_ref\<rbrakk>\<^sub>S = read_regS pmp1cfg_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmp1cfg[liftState_simp]:
  "\<lbrakk>write_reg pmp1cfg_ref v\<rbrakk>\<^sub>S = write_regS pmp1cfg_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_pmp0cfg[liftState_simp]:
  "\<lbrakk>read_reg pmp0cfg_ref\<rbrakk>\<^sub>S = read_regS pmp0cfg_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_pmp0cfg[liftState_simp]:
  "\<lbrakk>write_reg pmp0cfg_ref v\<rbrakk>\<^sub>S = write_regS pmp0cfg_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_tselect[liftState_simp]:
  "\<lbrakk>read_reg tselect_ref\<rbrakk>\<^sub>S = read_regS tselect_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_tselect[liftState_simp]:
  "\<lbrakk>write_reg tselect_ref v\<rbrakk>\<^sub>S = write_regS tselect_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_stval[liftState_simp]:
  "\<lbrakk>read_reg stval_ref\<rbrakk>\<^sub>S = read_regS stval_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_stval[liftState_simp]:
  "\<lbrakk>write_reg stval_ref v\<rbrakk>\<^sub>S = write_regS stval_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_scause[liftState_simp]:
  "\<lbrakk>read_reg scause_ref\<rbrakk>\<^sub>S = read_regS scause_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_scause[liftState_simp]:
  "\<lbrakk>write_reg scause_ref v\<rbrakk>\<^sub>S = write_regS scause_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_sepc[liftState_simp]:
  "\<lbrakk>read_reg sepc_ref\<rbrakk>\<^sub>S = read_regS sepc_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_sepc[liftState_simp]:
  "\<lbrakk>write_reg sepc_ref v\<rbrakk>\<^sub>S = write_regS sepc_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_sscratch[liftState_simp]:
  "\<lbrakk>read_reg sscratch_ref\<rbrakk>\<^sub>S = read_regS sscratch_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_sscratch[liftState_simp]:
  "\<lbrakk>write_reg sscratch_ref v\<rbrakk>\<^sub>S = write_regS sscratch_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_stvec[liftState_simp]:
  "\<lbrakk>read_reg stvec_ref\<rbrakk>\<^sub>S = read_regS stvec_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_stvec[liftState_simp]:
  "\<lbrakk>write_reg stvec_ref v\<rbrakk>\<^sub>S = write_regS stvec_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_sideleg[liftState_simp]:
  "\<lbrakk>read_reg sideleg_ref\<rbrakk>\<^sub>S = read_regS sideleg_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_sideleg[liftState_simp]:
  "\<lbrakk>write_reg sideleg_ref v\<rbrakk>\<^sub>S = write_regS sideleg_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_sedeleg[liftState_simp]:
  "\<lbrakk>read_reg sedeleg_ref\<rbrakk>\<^sub>S = read_regS sedeleg_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_sedeleg[liftState_simp]:
  "\<lbrakk>write_reg sedeleg_ref v\<rbrakk>\<^sub>S = write_regS sedeleg_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_mhartid[liftState_simp]:
  "\<lbrakk>read_reg mhartid_ref\<rbrakk>\<^sub>S = read_regS mhartid_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_mhartid[liftState_simp]:
  "\<lbrakk>write_reg mhartid_ref v\<rbrakk>\<^sub>S = write_regS mhartid_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_marchid[liftState_simp]:
  "\<lbrakk>read_reg marchid_ref\<rbrakk>\<^sub>S = read_regS marchid_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_marchid[liftState_simp]:
  "\<lbrakk>write_reg marchid_ref v\<rbrakk>\<^sub>S = write_regS marchid_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_mimpid[liftState_simp]:
  "\<lbrakk>read_reg mimpid_ref\<rbrakk>\<^sub>S = read_regS mimpid_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_mimpid[liftState_simp]:
  "\<lbrakk>write_reg mimpid_ref v\<rbrakk>\<^sub>S = write_regS mimpid_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_mvendorid[liftState_simp]:
  "\<lbrakk>read_reg mvendorid_ref\<rbrakk>\<^sub>S = read_regS mvendorid_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_mvendorid[liftState_simp]:
  "\<lbrakk>write_reg mvendorid_ref v\<rbrakk>\<^sub>S = write_regS mvendorid_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_minstret_written[liftState_simp]:
  "\<lbrakk>read_reg minstret_written_ref\<rbrakk>\<^sub>S = read_regS minstret_written_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_minstret_written[liftState_simp]:
  "\<lbrakk>write_reg minstret_written_ref v\<rbrakk>\<^sub>S = write_regS minstret_written_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_minstret[liftState_simp]:
  "\<lbrakk>read_reg minstret_ref\<rbrakk>\<^sub>S = read_regS minstret_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_minstret[liftState_simp]:
  "\<lbrakk>write_reg minstret_ref v\<rbrakk>\<^sub>S = write_regS minstret_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_mtime[liftState_simp]:
  "\<lbrakk>read_reg mtime_ref\<rbrakk>\<^sub>S = read_regS mtime_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_mtime[liftState_simp]:
  "\<lbrakk>write_reg mtime_ref v\<rbrakk>\<^sub>S = write_regS mtime_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_mcycle[liftState_simp]:
  "\<lbrakk>read_reg mcycle_ref\<rbrakk>\<^sub>S = read_regS mcycle_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_mcycle[liftState_simp]:
  "\<lbrakk>write_reg mcycle_ref v\<rbrakk>\<^sub>S = write_regS mcycle_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_mcountinhibit[liftState_simp]:
  "\<lbrakk>read_reg mcountinhibit_ref\<rbrakk>\<^sub>S = read_regS mcountinhibit_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_mcountinhibit[liftState_simp]:
  "\<lbrakk>write_reg mcountinhibit_ref v\<rbrakk>\<^sub>S = write_regS mcountinhibit_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_scounteren[liftState_simp]:
  "\<lbrakk>read_reg scounteren_ref\<rbrakk>\<^sub>S = read_regS scounteren_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_scounteren[liftState_simp]:
  "\<lbrakk>write_reg scounteren_ref v\<rbrakk>\<^sub>S = write_regS scounteren_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_mcounteren[liftState_simp]:
  "\<lbrakk>read_reg mcounteren_ref\<rbrakk>\<^sub>S = read_regS mcounteren_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_mcounteren[liftState_simp]:
  "\<lbrakk>write_reg mcounteren_ref v\<rbrakk>\<^sub>S = write_regS mcounteren_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_mscratch[liftState_simp]:
  "\<lbrakk>read_reg mscratch_ref\<rbrakk>\<^sub>S = read_regS mscratch_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_mscratch[liftState_simp]:
  "\<lbrakk>write_reg mscratch_ref v\<rbrakk>\<^sub>S = write_regS mscratch_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_mtval[liftState_simp]:
  "\<lbrakk>read_reg mtval_ref\<rbrakk>\<^sub>S = read_regS mtval_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_mtval[liftState_simp]:
  "\<lbrakk>write_reg mtval_ref v\<rbrakk>\<^sub>S = write_regS mtval_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_mepc[liftState_simp]:
  "\<lbrakk>read_reg mepc_ref\<rbrakk>\<^sub>S = read_regS mepc_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_mepc[liftState_simp]:
  "\<lbrakk>write_reg mepc_ref v\<rbrakk>\<^sub>S = write_regS mepc_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_mcause[liftState_simp]:
  "\<lbrakk>read_reg mcause_ref\<rbrakk>\<^sub>S = read_regS mcause_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_mcause[liftState_simp]:
  "\<lbrakk>write_reg mcause_ref v\<rbrakk>\<^sub>S = write_regS mcause_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_mtvec[liftState_simp]:
  "\<lbrakk>read_reg mtvec_ref\<rbrakk>\<^sub>S = read_regS mtvec_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_mtvec[liftState_simp]:
  "\<lbrakk>write_reg mtvec_ref v\<rbrakk>\<^sub>S = write_regS mtvec_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_medeleg[liftState_simp]:
  "\<lbrakk>read_reg medeleg_ref\<rbrakk>\<^sub>S = read_regS medeleg_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_medeleg[liftState_simp]:
  "\<lbrakk>write_reg medeleg_ref v\<rbrakk>\<^sub>S = write_regS medeleg_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_mideleg[liftState_simp]:
  "\<lbrakk>read_reg mideleg_ref\<rbrakk>\<^sub>S = read_regS mideleg_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_mideleg[liftState_simp]:
  "\<lbrakk>write_reg mideleg_ref v\<rbrakk>\<^sub>S = write_regS mideleg_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_mie[liftState_simp]:
  "\<lbrakk>read_reg mie_ref\<rbrakk>\<^sub>S = read_regS mie_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_mie[liftState_simp]:
  "\<lbrakk>write_reg mie_ref v\<rbrakk>\<^sub>S = write_regS mie_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_mip[liftState_simp]:
  "\<lbrakk>read_reg mip_ref\<rbrakk>\<^sub>S = read_regS mip_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_mip[liftState_simp]:
  "\<lbrakk>write_reg mip_ref v\<rbrakk>\<^sub>S = write_regS mip_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_mstatus[liftState_simp]:
  "\<lbrakk>read_reg mstatus_ref\<rbrakk>\<^sub>S = read_regS mstatus_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_mstatus[liftState_simp]:
  "\<lbrakk>write_reg mstatus_ref v\<rbrakk>\<^sub>S = write_regS mstatus_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_mstatush[liftState_simp]:
  "\<lbrakk>read_reg mstatush_ref\<rbrakk>\<^sub>S = read_regS mstatush_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_mstatush[liftState_simp]:
  "\<lbrakk>write_reg mstatush_ref v\<rbrakk>\<^sub>S = write_regS mstatush_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_misa[liftState_simp]:
  "\<lbrakk>read_reg misa_ref\<rbrakk>\<^sub>S = read_regS misa_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_misa[liftState_simp]:
  "\<lbrakk>write_reg misa_ref v\<rbrakk>\<^sub>S = write_regS misa_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_cur_inst[liftState_simp]:
  "\<lbrakk>read_reg cur_inst_ref\<rbrakk>\<^sub>S = read_regS cur_inst_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_cur_inst[liftState_simp]:
  "\<lbrakk>write_reg cur_inst_ref v\<rbrakk>\<^sub>S = write_regS cur_inst_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_cur_privilege[liftState_simp]:
  "\<lbrakk>read_reg cur_privilege_ref\<rbrakk>\<^sub>S = read_regS cur_privilege_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_cur_privilege[liftState_simp]:
  "\<lbrakk>write_reg cur_privilege_ref v\<rbrakk>\<^sub>S = write_regS cur_privilege_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x31[liftState_simp]:
  "\<lbrakk>read_reg x31_ref\<rbrakk>\<^sub>S = read_regS x31_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x31[liftState_simp]:
  "\<lbrakk>write_reg x31_ref v\<rbrakk>\<^sub>S = write_regS x31_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x30[liftState_simp]:
  "\<lbrakk>read_reg x30_ref\<rbrakk>\<^sub>S = read_regS x30_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x30[liftState_simp]:
  "\<lbrakk>write_reg x30_ref v\<rbrakk>\<^sub>S = write_regS x30_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x29[liftState_simp]:
  "\<lbrakk>read_reg x29_ref\<rbrakk>\<^sub>S = read_regS x29_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x29[liftState_simp]:
  "\<lbrakk>write_reg x29_ref v\<rbrakk>\<^sub>S = write_regS x29_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x28[liftState_simp]:
  "\<lbrakk>read_reg x28_ref\<rbrakk>\<^sub>S = read_regS x28_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x28[liftState_simp]:
  "\<lbrakk>write_reg x28_ref v\<rbrakk>\<^sub>S = write_regS x28_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x27[liftState_simp]:
  "\<lbrakk>read_reg x27_ref\<rbrakk>\<^sub>S = read_regS x27_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x27[liftState_simp]:
  "\<lbrakk>write_reg x27_ref v\<rbrakk>\<^sub>S = write_regS x27_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x26[liftState_simp]:
  "\<lbrakk>read_reg x26_ref\<rbrakk>\<^sub>S = read_regS x26_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x26[liftState_simp]:
  "\<lbrakk>write_reg x26_ref v\<rbrakk>\<^sub>S = write_regS x26_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x25[liftState_simp]:
  "\<lbrakk>read_reg x25_ref\<rbrakk>\<^sub>S = read_regS x25_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x25[liftState_simp]:
  "\<lbrakk>write_reg x25_ref v\<rbrakk>\<^sub>S = write_regS x25_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x24[liftState_simp]:
  "\<lbrakk>read_reg x24_ref\<rbrakk>\<^sub>S = read_regS x24_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x24[liftState_simp]:
  "\<lbrakk>write_reg x24_ref v\<rbrakk>\<^sub>S = write_regS x24_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x23[liftState_simp]:
  "\<lbrakk>read_reg x23_ref\<rbrakk>\<^sub>S = read_regS x23_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x23[liftState_simp]:
  "\<lbrakk>write_reg x23_ref v\<rbrakk>\<^sub>S = write_regS x23_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x22[liftState_simp]:
  "\<lbrakk>read_reg x22_ref\<rbrakk>\<^sub>S = read_regS x22_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x22[liftState_simp]:
  "\<lbrakk>write_reg x22_ref v\<rbrakk>\<^sub>S = write_regS x22_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x21[liftState_simp]:
  "\<lbrakk>read_reg x21_ref\<rbrakk>\<^sub>S = read_regS x21_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x21[liftState_simp]:
  "\<lbrakk>write_reg x21_ref v\<rbrakk>\<^sub>S = write_regS x21_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x20[liftState_simp]:
  "\<lbrakk>read_reg x20_ref\<rbrakk>\<^sub>S = read_regS x20_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x20[liftState_simp]:
  "\<lbrakk>write_reg x20_ref v\<rbrakk>\<^sub>S = write_regS x20_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x19[liftState_simp]:
  "\<lbrakk>read_reg x19_ref\<rbrakk>\<^sub>S = read_regS x19_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x19[liftState_simp]:
  "\<lbrakk>write_reg x19_ref v\<rbrakk>\<^sub>S = write_regS x19_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x18[liftState_simp]:
  "\<lbrakk>read_reg x18_ref\<rbrakk>\<^sub>S = read_regS x18_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x18[liftState_simp]:
  "\<lbrakk>write_reg x18_ref v\<rbrakk>\<^sub>S = write_regS x18_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x17[liftState_simp]:
  "\<lbrakk>read_reg x17_ref\<rbrakk>\<^sub>S = read_regS x17_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x17[liftState_simp]:
  "\<lbrakk>write_reg x17_ref v\<rbrakk>\<^sub>S = write_regS x17_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x16[liftState_simp]:
  "\<lbrakk>read_reg x16_ref\<rbrakk>\<^sub>S = read_regS x16_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x16[liftState_simp]:
  "\<lbrakk>write_reg x16_ref v\<rbrakk>\<^sub>S = write_regS x16_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x15[liftState_simp]:
  "\<lbrakk>read_reg x15_ref\<rbrakk>\<^sub>S = read_regS x15_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x15[liftState_simp]:
  "\<lbrakk>write_reg x15_ref v\<rbrakk>\<^sub>S = write_regS x15_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x14[liftState_simp]:
  "\<lbrakk>read_reg x14_ref\<rbrakk>\<^sub>S = read_regS x14_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x14[liftState_simp]:
  "\<lbrakk>write_reg x14_ref v\<rbrakk>\<^sub>S = write_regS x14_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x13[liftState_simp]:
  "\<lbrakk>read_reg x13_ref\<rbrakk>\<^sub>S = read_regS x13_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x13[liftState_simp]:
  "\<lbrakk>write_reg x13_ref v\<rbrakk>\<^sub>S = write_regS x13_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x12[liftState_simp]:
  "\<lbrakk>read_reg x12_ref\<rbrakk>\<^sub>S = read_regS x12_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x12[liftState_simp]:
  "\<lbrakk>write_reg x12_ref v\<rbrakk>\<^sub>S = write_regS x12_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x11[liftState_simp]:
  "\<lbrakk>read_reg x11_ref\<rbrakk>\<^sub>S = read_regS x11_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x11[liftState_simp]:
  "\<lbrakk>write_reg x11_ref v\<rbrakk>\<^sub>S = write_regS x11_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x10[liftState_simp]:
  "\<lbrakk>read_reg x10_ref\<rbrakk>\<^sub>S = read_regS x10_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x10[liftState_simp]:
  "\<lbrakk>write_reg x10_ref v\<rbrakk>\<^sub>S = write_regS x10_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x9[liftState_simp]:
  "\<lbrakk>read_reg x9_ref\<rbrakk>\<^sub>S = read_regS x9_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x9[liftState_simp]:
  "\<lbrakk>write_reg x9_ref v\<rbrakk>\<^sub>S = write_regS x9_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x8[liftState_simp]:
  "\<lbrakk>read_reg x8_ref\<rbrakk>\<^sub>S = read_regS x8_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x8[liftState_simp]:
  "\<lbrakk>write_reg x8_ref v\<rbrakk>\<^sub>S = write_regS x8_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x7[liftState_simp]:
  "\<lbrakk>read_reg x7_ref\<rbrakk>\<^sub>S = read_regS x7_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x7[liftState_simp]:
  "\<lbrakk>write_reg x7_ref v\<rbrakk>\<^sub>S = write_regS x7_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x6[liftState_simp]:
  "\<lbrakk>read_reg x6_ref\<rbrakk>\<^sub>S = read_regS x6_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x6[liftState_simp]:
  "\<lbrakk>write_reg x6_ref v\<rbrakk>\<^sub>S = write_regS x6_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x5[liftState_simp]:
  "\<lbrakk>read_reg x5_ref\<rbrakk>\<^sub>S = read_regS x5_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x5[liftState_simp]:
  "\<lbrakk>write_reg x5_ref v\<rbrakk>\<^sub>S = write_regS x5_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x4[liftState_simp]:
  "\<lbrakk>read_reg x4_ref\<rbrakk>\<^sub>S = read_regS x4_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x4[liftState_simp]:
  "\<lbrakk>write_reg x4_ref v\<rbrakk>\<^sub>S = write_regS x4_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x3[liftState_simp]:
  "\<lbrakk>read_reg x3_ref\<rbrakk>\<^sub>S = read_regS x3_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x3[liftState_simp]:
  "\<lbrakk>write_reg x3_ref v\<rbrakk>\<^sub>S = write_regS x3_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x2[liftState_simp]:
  "\<lbrakk>read_reg x2_ref\<rbrakk>\<^sub>S = read_regS x2_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x2[liftState_simp]:
  "\<lbrakk>write_reg x2_ref v\<rbrakk>\<^sub>S = write_regS x2_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_x1[liftState_simp]:
  "\<lbrakk>read_reg x1_ref\<rbrakk>\<^sub>S = read_regS x1_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_x1[liftState_simp]:
  "\<lbrakk>write_reg x1_ref v\<rbrakk>\<^sub>S = write_regS x1_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_instbits[liftState_simp]:
  "\<lbrakk>read_reg instbits_ref\<rbrakk>\<^sub>S = read_regS instbits_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_instbits[liftState_simp]:
  "\<lbrakk>write_reg instbits_ref v\<rbrakk>\<^sub>S = write_regS instbits_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_nextPC[liftState_simp]:
  "\<lbrakk>read_reg nextPC_ref\<rbrakk>\<^sub>S = read_regS nextPC_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_nextPC[liftState_simp]:
  "\<lbrakk>write_reg nextPC_ref v\<rbrakk>\<^sub>S = write_regS nextPC_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

lemma liftS_read_reg_PC[liftState_simp]:
  "\<lbrakk>read_reg PC_ref\<rbrakk>\<^sub>S = read_regS PC_ref"
  by (intro liftState_read_reg) (auto simp: register_defs)

lemma liftS_write_reg_PC[liftState_simp]:
  "\<lbrakk>write_reg PC_ref v\<rbrakk>\<^sub>S = write_regS PC_ref v"
  by (intro liftState_write_reg) (auto simp: register_defs)

end
