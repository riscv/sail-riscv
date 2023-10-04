
/*============================================================================

This C source file is part of the SoftFloat IEEE Floating-Point Arithmetic
Package, Release 3d, by John R. Hauser.

Copyright 2011, 2012, 2013, 2014, 2015, 2017 The Regents of the University of
California.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice,
    this list of conditions, and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions, and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

 3. Neither the name of the University nor the names of its contributors may
    be used to endorse or promote products derived from this software without
    specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS "AS IS", AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, ARE
DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=============================================================================
 * 
 * @file s_roundPackToBF16.c
 * @brief Rounding from IEEE-754 32-bit floating point number to bf16 floating 
 * point number
 *
 * @author Jai Madisetty
 * 
=============================================================================*/

#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "softfloat.h"

bfloat16_t
 softfloat_roundPackToBF16( bool sign, int_fast16_t exp, uint_fast16_t sig )
{
    // Comments added by P. Tang 09/21/2023:
    // Unlike the usual softfloat style, this function assumes it is called
    // by f32_to_bf16, not possibly from other originating formats 
    // input f32 infinities and NaNs are already handled in f32_to_bf16
    // so the exp is never all ONES on input 
    uint_fast8_t roundingMode;
    uint_fast16_t uiZ;
    union ui16_bf16 uZ;
    bool L, G, R, S, inc, incExp, isTiny, isInexact;
    bool LL, inc_tmp, no_carry;

    /*------------------------------------------------------------------------
    *------------------------------------------------------------------------*/
    roundingMode = softfloat_roundingMode;
    L = (bool)(sig & 0x8);
    G = (bool)(sig & 0x4);
    R = (bool)(sig & 0x2);
    S = (bool)(sig & 0x1);

    // isInexact is needed later on to set the underflow flag correctly
    isInexact = (G != 0) || (R != 0) || (S !=0);
    if (isInexact) {
        // this will set the inexact flag correctly once and for all
        // no need to revisit this anywhere below
        softfloat_raiseFlags(softfloat_flag_inexact);
    }


#ifdef SOFTFLOAT_ROUND_ODD
        if (roundingMode == softfloat_round_odd) {
            // round_odd means that if there are bits to be rounded
            // then always make the lsb of the rounded result to be 1.
            // But if there is nothing to round, then leave the lsb unchanged
            sig >>= 3;
            sig |= (uint_fast16_t) isInexact;
            goto packReturn;
        }
#endif
    if (roundingMode == softfloat_round_near_even) {
        inc = (G && (R || S)) || (L && G);
    } else if (roundingMode == softfloat_round_minMag) {
        inc = false;
    } else if (roundingMode == softfloat_round_min) {
        inc = (sign && G) || (sign && R) || (sign && S);
    } else if (roundingMode == softfloat_round_max) {
        inc = ((!sign) && G) || ((!sign) && R) || ((!sign) && S);
    } else {    // (roundingMode == softfloat_round_near_maxMag)
        inc = G;
    }
    // At this point, adding inc to the lsb "L" of sig would give the
    // corrected rounded return result. But we will defer on performing
    // this rounding and first decide whether we have "tininess".

    // To set underflow correctly, we need to know if the value
    // is tiny. A slight complication is that IEEE allows a vendor
    // to detect tininess either before or after rounding.
    // And in the case of tininess after rounding (which is what Rivos does)
    // we actually need to perform a test rounding as if the exponent range 
    // is unlimited. This means we may possibly have to first normalize
    // the sig, thus changing the value of L, G, R, S.
    // We can eliminate the expensive arbitrary length normalization
    // by observing that if exp == 0 and the msb of sig is also 0, 
    // the result will always be tiny after rounding. Thus the only
    // tricky case is when exp == 0 and msb of sig is 1, then we need
    // to see if rounding at the "G" position (not at the "L" position)
    // would result in a carry, in which case, it is NOT tiny after rounding.

    // isTiny is True if it is tiny now and we define tiny "before rounding"
    isTiny = ((exp == 0) && 
              (softfloat_detectTininess == softfloat_tininess_beforeRounding));
    // isTiny is also True if exp == 0 and msb of sig is also 0
    isTiny = isTiny || ((exp == 0) && ((sig & 0x200) == 0));
    if ((exp == 0) && ((sig & 0x200) > 0)) {
        // the 10 bits of sig now corresponds to 1 explicit bit, 7 mantissa bit, Round and sticky
        // so the "lsb" is actually G
        LL = G;
        if (roundingMode == softfloat_round_near_even) {
            inc_tmp = (R && S) || (LL && R);
        } else if (roundingMode == softfloat_round_minMag) {
            inc_tmp = false;
        } else if (roundingMode == softfloat_round_min) {
            inc_tmp = (sign && R) || (sign && S);
        } else if (roundingMode == softfloat_round_max) {
            inc_tmp = ((!sign) && R) || ((!sign) && S);
        } else {    // (roundingMode == softfloat_round_near_maxMag)
            inc_tmp = R;
        }        
        // isTiny is True in this case when rounding does not cause a carry
        no_carry = ((sig >> 2) + (uint_fast16_t) inc_tmp) < 0x100;
        isTiny = isTiny || no_carry;
    }
    if ((isInexact) && (isTiny)) softfloat_raiseFlags(softfloat_flag_underflow);

    // Now that underflow flag is handled, we continued with rounding
    // of sig using "inc" that was computed earlier
    sig >>= 3;
    sig += ((uint_fast16_t)inc);
    incExp = (bool)(sig & 0x80);
    exp += ((uint_fast16_t)incExp);
    
    if (exp == 0xFF) {
        softfloat_raiseFlags(softfloat_flag_overflow);
    }
    sig &= 0x7F;

    /*------------------------------------------------------------------------
    *------------------------------------------------------------------------*/
 packReturn:
    uiZ = packToBF16UI( sign, exp, sig );
    uZ.ui = uiZ;
    return uZ.f;

}
