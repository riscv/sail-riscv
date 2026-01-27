// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================


// vector dot product instruction types

enum vvd_funct6 = { VVD_VDOT4A, VVD_VDOT4AU, VVD_VDOT4SU }

enum vxd_funct6 = { VXD_VDOT4A, VXD_VDOT4AU, VXD_VDOT4SU, VXD_VDOT4US }