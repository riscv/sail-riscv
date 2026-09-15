// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

enum pmiscfunct7 = { CLS, ABS }

enum pshiftibfunct3 = { PSLLI_B }

enum pshiftihfunct3 = { PSLLI_H, PSSLAI_H }

enum pshiftiwfunct3_64only = { PSLLI_W, PSSLAI_W }

enum psextwfunct5_64only = { PSEXT_W_B, PSEXT_W_H }

enum psabswidth2 = { PSABS_B, PSABS_H }

enum palubscalarfunct3 = { PSLL_BS, PADD_BS }

enum paluhscalarfunct3 = { PSLL_HS, PADD_HS, PSSHL_HS, PSSHLR_HS, PSSHA_HS, PSSHAR_HS }

enum paluwscalarfunct3_32only = { SSHL, SSHLR, SSHA, SSHAR }

enum paluwscalarfunct3_64only = { PSLL_WS, PADD_WS, PSSHL_WS, PSSHLR_WS, PSSHA_WS, PSSHAR_WS }

enum paludscalarfunct3_64only = { SHL, SHLR, SHA, SHAR }

enum pshiftsatibfunct3 = { PSRLI_B, PSRAI_B }

enum pshiftsatihfunct3 = { PSRLI_H, PUSATI_H, PSRAI_H, PSRARI_H, PSATI_H }

enum pshiftsatiwfunct3_32only = { USATI, SRARI, SATI }

enum pshiftsatiwfunct3_64only = { PSRLI_W, PUSATI_W, PSRAI_W, PSRARI_W, PSATI_W }

enum pshiftbscalarfunct3 = { PSRL_BS, PSRA_BS }

enum pshifthscalarfunct3 = { PSRL_HS, PSRA_HS }

enum pshiftwscalarfunct3_64only = { PSRL_WS, PSRA_WS }

enum predsumbscalarfunct3 = { PREDSUM_BS, PREDSUMU_BS }

enum predsumhscalarfunct3 = { PREDSUM_HS, PREDSUMU_HS }

enum predsumwscalarfunct3_64only = { PREDSUM_WS, PREDSUMU_WS }

enum palubfunct4 = { PADD_B, PSADD_B, PAADD_B, PSADDU_B, PAADDU_B, PSUB_B, PABD_B, PSSUB_B, PASUB_B, PABDU_B, PSSUBU_B, PASUBU_B }

enum paluhfunct4 = { PADD_H, PSADD_H, PAADD_H, PSADDU_H, PAADDU_H, PSUB_H, PABD_H, PSSUB_H, PASUB_H, PABDU_H, PSSUBU_H, PASUBU_H }

enum paluwfunct4_32only = { SADD, AADD, SADDU, AADDU, SSUB, ASUB, SSUBU, ASUBU }

enum paluwfunct4_64only = { PADD_W, PSADD_W, PAADD_W, PSADDU_W, PAADDU_W, PSUB_W, PSSUB_W, PASUB_W, PSSUBU_W, PASUBU_W }

enum pshiftextendfunct4 = { SLX, SRX }

enum pmovemaskmergewidth2 = { MVM, MVMN, MERGE }

enum pabdsumbfunct4 = { PABDSUMU_B, PABDSUMAU_B }

enum pmulhb01funct4 = { PMUL_H_B01, PMULU_H_B01 }

enum pmulwh01funct4_64only = { PMUL_W_H01, PMACC_W_H01, PMULU_W_H01, PMACCU_W_H01 }

enum pmulwh01funct4_32only = { MUL_H01, MACC_H01, MULU_H01, MACCU_H01 }

enum pmuldw01funct4_64only = { MUL_W01, MACC_W01, MULU_W01, MACCU_W01 }

enum pshiftoneaddhfunct3 = { PSH1ADD_H, PSSH1SADD_H }

enum pshiftoneaddwfunct3_64only = { PSH1ADD_W, PSSH1SADD_W }

enum pnarrowsatbfunct3_64only = { PNCLIPUP_B, PNCLIPP_B }

enum pnarrowsathfunct3_64only = { PNCLIPUP_H, PNCLIPP_H }

enum pnarrowsatwfunct3_64only = { PNCLIPUP_W, PNCLIPP_W }

enum punzipwidth2_64only = { UNZIP8P, UNZIP16P, UNZIP8HP, UNZIP16HP }

enum pzipwidth2_64only = { ZIP8P, ZIP16P, ZIP8HP, ZIP16HP }

enum pmulhbfunct4 = { PMUL_H_B00, PMUL_H_B11, PMULU_H_B00, PMULU_H_B11, PMULSU_H_B00, PMULSU_H_B11 }

enum pmulwhfunct4_32only = { MUL_H00, MACC_H00, MUL_H11, MACC_H11, MULU_H00, MACCU_H00, MULU_H11, MACCU_H11, MULSU_H00, MACCSU_H00, MULSU_H11, MACCSU_H11 }

enum pmulwhfunct4_64only = { PMUL_W_H00, PMUL_W_H11, PMULU_W_H00, PMULU_W_H11, PMULSU_W_H00, PMULSU_W_H11, PMACC_W_H00, PMACC_W_H11, PMACCU_W_H00, PMACCU_W_H11, PMACCSU_W_H00, PMACCSU_W_H11 }

enum pmuldwfunct4_64only = { MUL_W00, MACC_W00, MUL_W11, MACC_W11, MULU_W00, MACCU_W00, MULU_W11, MACCU_W11, MULSU_W00, MACCSU_W00, MULSU_W11, MACCSU_W11 }

enum ppairbfunct3 = { PPAIRE_B, PPAIREO_B, PPAIROE_B, PPAIRO_B }

enum ppairhfunct3 = { PPAIREO_H, PPAIROE_H, PPAIRO_H }

enum ppairwfunct3_64only = { PPAIREO_W, PPAIROE_W, PPAIRO_W }

enum pmul2hfunct4 = { PM2ADD_H, PM2ADDA_H, PM2ADD_HX, PM2ADDA_HX, PM2ADDU_H, PM2ADDAU_H, PMQ2ADD_H, PMQ2ADDA_H, PM2SUB_H, PM2SUBA_H, PM2SUB_HX, PM2SUBA_HX, PM2ADDSU_H, PM2ADDASU_H }

enum pmul2hcontdfunct4 = { PMQR2ADD_H, PMQR2ADDA_H, PM2SADD_H, PM2SADD_HX }

enum pmul4bfunct4 = { PM4ADD_B, PM4ADDA_B, PM4ADDU_B, PM4ADDAU_B, PM4ADDSU_B, PM4ADDASU_B }

enum pmul2wfunct4_64only = { PM2ADD_W, PM2ADDA_W, PM2ADD_WX, PM2ADDA_WX, PM2ADDU_W, PM2ADDAU_W, PMQ2ADD_W, PMQ2ADDA_W, PM2SUB_W, PM2SUBA_W, PM2SUB_WX, PM2SUBA_WX, PM2ADDSU_W, PM2ADDASU_W }

enum pmul2wcontdfunct4_64only = { PMQR2ADD_W, PMQR2ADDA_W }

enum pmul4hfunct4_64only = { PM4ADD_H, PM4ADDA_H, PM4ADDU_H, PM4ADDAU_H, PM4ADDSU_H, PM4ADDASU_H }

enum pmulwh01contdwidth2_32only = { MQACC_H01, MQRACC_H01 }

enum pmulwh01contdwidth2_64only = { PMQACC_W_H01, PMQRACC_W_H01 }

enum pmuldw01contdwidth2_64only = { MQACC_W01, MQRACC_W01 }

enum paddsubhfunct4 = { PAS_HX, PSAS_HX, PAAS_HX }

enum psubaddhfunct4 = { PSA_HX, PSSA_HX, PASA_HX }

enum paddsubwfunct4_64only = { PAS_WX, PSAS_WX, PAAS_WX }

enum psubaddwfunct4_64only = { PSA_WX, PSSA_WX, PASA_WX }

enum pcomparebfunct4 = { PMSEQ_B, PMSLT_B, PMSLTU_B, PMIN_B, PMINU_B, PMAX_B, PMAXU_B }

enum pcomparehfunct4 = { PMSEQ_H, PMSLT_H, PMSLTU_H, PMIN_H, PMINU_H, PMAX_H, PMAXU_H }

enum pcomparewfunct4_64only = { PMSEQ_W, PMSLT_W, PMSLTU_W, PMIN_W, PMINU_W, PMAX_W, PMAXU_W }

enum pmulhfunct4 = { PMULH_H, PMHACC_H, PMULHU_H, PMHACCU_H, PMULHSU_H, PMHACCSU_H, PMULQ_H }

enum pmulhcontdfunct4 = { PMULHR_H, PMHRACC_H, PMULHRU_H, PMHRACCU_H, PMULHRSU_H, PMHRACCSU_H, PMULQR_H }

enum pmulhbsignedfunct4 = { PMULH_H_B0, PMHACC_H_B0, PMULH_H_B1, PMHACC_H_B1 }

enum pmulhbunsignedfunct4 = { PMULHSU_H_B0, PMHACCSU_H_B0, PMULHSU_H_B1, PMHACCSU_H_B1 }

enum pmulwfunct4_32only = { MHACC, MHACCU, MHACCSU, MULQ }

enum pmulwfunct4_64only = { PMULH_W, PMHACC_W, PMULHU_W, PMHACCU_W, PMULHSU_W, PMHACCSU_W, PMULQ_W }

enum pmulwcontdfunct4_32only = { MULHR, MHRACC, MULHRU, MHRACCU, MULHRSU, MHRACCSU, MULQR }

enum pmulwcontdfunct4_64only = { PMULHR_W, PMHRACC_W, PMULHRU_W, PMHRACCU_W, PMULHRSU_W, PMHRACCSU_W, PMULQR_W }

enum pmulwhsignedfunct4_32only = { MULH_H0, MHACC_H0, MULH_H1, MHACC_H1 }

enum pmulwhsignedfunct4_64only = { PMULH_W_H0, PMHACC_W_H0, PMULH_W_H1, PMHACC_W_H1 }

enum pmulwhunsignedfunct4_32only = { MULHSU_H0, MHACCSU_H0, MULHSU_H1, MHACCSU_H1 }

enum pmulwhunsignedfunct4_64only = { PMULHSU_W_H0, PMHACCSU_W_H0, PMULHSU_W_H1, PMHACCSU_W_H1 }

enum pmulwhcontdfunct4_32only = { MQACC_H00, MQACC_H11 }

enum pmulwhcontd2funct4_32only = { MQRACC_H00, MQRACC_H11 }

enum pmulwhcontdfunct4_64only = { PMQACC_W_H00, PMQACC_W_H11 }

enum pmulwhcontd2funct4_64only = { PMQRACC_W_H00, PMQRACC_W_H11 }

enum pmuldwcontdfunct4_64only = { MQACC_W00, MQACC_W11 }

enum pmuldwcontd2funct4_64only = { MQRACC_W00, MQRACC_W11 }

enum pwshiftibfunct3_32only = { PWSLLI_B, PWSLAI_B }

enum pwshiftihfunct3_32only = { PWSLLI_H, PWSLAI_H }

enum pwshiftiwfunct3_32only = { WSLLI, WSLAI }

enum plidhfunct5_32only = { PLI_DH, PLUI_DH }

enum pwshiftbsfunct3_32only = { PWSLL_BS, PWSLA_BS }

enum pwshifthsfunct3_32only = { PWSLL_HS, PWSLA_HS }

enum pwshiftwsfunct3_32only = { WSLL, WSLA }

enum pwzipwidth2_32only = { WZIP8P, WZIP16P }

enum pwalubfunct4_32only = { PWADD_B, PWADDA_B, PWADDU_B, PWADDAU_B, PWMUL_B, PWMULU_B, PWSUB_B, PWSUBA_B, PWSUBU_B, PWSUBAU_B, PWMULSU_B }

enum pwaluhfunct4_32only = { PWADD_H, PWADDA_H, PWADDU_H, PWADDAU_H, PWMUL_H, PWMACC_H, PWMULU_H, PWMACCU_H, PWSUB_H, PWSUBA_H, PWSUBU_H, PWSUBAU_H, PWMULSU_H, PWMACCSU_H }

enum pwaluwfunct4_32only = { WADD, WADDA, WADDU, WADDAU, WMUL, WMACC, WMULU, WMACCU, WSUB, WSUBA, WSUBU, WSUBAU, WMULSU, WMACCSU }

enum pwmul2hfunct4_32only = { PM2WADD_H, PM2WADDA_H, PM2WADD_HX, PM2WADDA_HX, PM2WADDU_H, PM2WADDAU_H, PM2WSUB_H, PM2WSUBA_H, PM2WSUB_HX, PM2WSUBA_HX, PM2WADDSU_H, PM2WADDASU_H }

enum pwmulhwidth2_32only = { PMQWACC_H, PMQRWACC_H }

enum pwmulwwidth2_32only = { MQWACC, MQRWACC }

enum predsumdbscalarfunct3_32only = { PREDSUM_DBS, PREDSUMU_DBS }

enum predsumdhscalarfunct3_32only = { PREDSUM_DHS, PREDSUMU_DHS }

enum pnarrowsatibfunct3_32only = { PNSRLI_B, PNCLIPIU_B, PNCLIPRIU_B, PNSRAI_B, PNSRARI_B, PNCLIPI_B, PNCLIPRI_B }

enum pnarrowsatihfunct3_32only = { PNSRLI_H, PNCLIPIU_H, PNCLIPRIU_H, PNSRAI_H, PNSRARI_H, PNCLIPI_H, PNCLIPRI_H }

enum pnarrowsatiwfunct3_32only = { NSRLI, NCLIPIU, NCLIPRIU, NSRAI, NSRARI, NCLIPI, NCLIPRI }

enum pnarrowsatbscalarfunct3_32only = { PNSRL_BS, PNCLIPU_BS, PNCLIPRU_BS, PNSRA_BS, PNSRAR_BS, PNCLIP_BS, PNCLIPR_BS }

enum pnarrowsathscalarfunct3_32only = { PNSRL_HS, PNCLIPU_HS, PNCLIPRU_HS, PNSRA_HS, PNSRAR_HS, PNCLIP_HS, PNCLIPR_HS }

enum pnarrowsatwscalarfunct3_32only = { NSRL, NCLIPU, NCLIPRU, NSRA, NSRAR, NCLIP, NCLIPR }

enum pshiftidbfunct3_32only = { PSLLI_DB }

enum pshiftidhfunct3_32only = { PSLLI_DH, PSSLAI_DH }

enum pshiftidwfunct3_32only = { PSLLI_DW, PSSLAI_DW }

enum psabsdwidth2_32only = { PSABS_DB, PSABS_DH }

enum paludbscalarfunct3_32only = { PSLL_DBS, PADD_DBS }

enum paludhscalarfunct3_32only = { PSLL_DHS, PADD_DHS, PSSHL_DHS, PSSHLR_DHS, PSSHA_DHS, PSSHAR_DHS }

enum paludwscalarfunct3_32only = { PSLL_DWS, PADD_DWS, PSSHL_DWS, PSSHLR_DWS, PSSHA_DWS, PSSHAR_DWS }

enum pshiftsatidbfunct3_32only = { PSRLI_DB, PSRAI_DB }

enum pshiftsatidhfunct3_32only = { PSRLI_DH, PUSATI_DH, PSRAI_DH, PSRARI_DH, PSATI_DH }

enum pshiftsatidwfunct3_32only = { PSRLI_DW, PUSATI_DW, PSRAI_DW, PSRARI_DW, PSATI_DW }

enum pshiftdbscalarfunct3_32only = { PSRL_DBS, PSRA_DBS }

enum pshiftdhscalarfunct3_32only = { PSRL_DHS, PSRA_DHS }

enum pshiftdwscalarfunct3_32only = { PSRL_DWS, PSRA_DWS }

enum pcomparewfunct4_32only = { MSEQ, MSLT, MSLTU }

enum paludbfunct4_32only = { PADD_DB, PSADD_DB, PAADD_DB, PSADDU_DB, PAADDU_DB, PSUB_DB, PABD_DB, PSSUB_DB, PASUB_DB, PABDU_DB, PSSUBU_DB, PASUBU_DB }

enum paludhfunct4_32only = { PADD_DH, PSADD_DH, PAADD_DH, PSADDU_DH, PAADDU_DH, PSUB_DH, PABD_DH, PSSUB_DH, PASUB_DH, PABDU_DH, PSSUBU_DH, PASUBU_DH }

enum paludwfunct4_32only = { PADD_DW, PSADD_DW, PAADD_DW, PSADDU_DW, PAADDU_DW, PSUB_DW, PSSUB_DW, PASUB_DW, PSSUBU_DW, PASUBU_DW }

enum paluddfunct4_32only = { ADDD, SUBD }

enum pshiftoneadddhfunct3_32only = { PSH1ADD_DH, PSSH1SADD_DH }

enum pshiftoneadddwfunct3_32only = { PSH1ADD_DW, PSSH1SADD_DW }

enum ppairdbfunct3_32only = { PPAIRE_DB, PPAIREO_DB, PPAIROE_DB, PPAIRO_DB }

enum ppairdhfunct3_32only = { PPAIRE_DH, PPAIREO_DH, PPAIROE_DH, PPAIRO_DH }

enum paddsubdhfunct4_32only = { PAS_DHX, PSAS_DHX, PAAS_DHX }

enum psubadddhfunct4_32only = { PSA_DHX, PSSA_DHX, PASA_DHX }

enum pcomparedbfunct4_32only = { PMSEQ_DB, PMSLT_DB, PMSLTU_DB, PMIN_DB, PMINU_DB, PMAX_DB, PMAXU_DB }

enum pcomparedhfunct4_32only = { PMSEQ_DH, PMSLT_DH, PMSLTU_DH, PMIN_DH, PMINU_DH, PMAX_DH, PMAXU_DH }

enum pcomparedwfunct4_32only = { PMSEQ_DW, PMSLT_DW, PMSLTU_DW, PMIN_DW, PMINU_DW, PMAX_DW, PMAXU_DW }
