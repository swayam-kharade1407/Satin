//
//  SignedDistanceFunctions.mm
//  Satin
//
//  Created by Reza Ali on 10/27/24.
//

#include "SignedDistanceFunctions.h"

#include <simd/simd.h>

float lineSDF(simd_float3 pos, simd_float3 a, simd_float3 b)
{
    const simd_float3 pa = pos - a;
    const simd_float3 ba = b - a;
    const float t = simd_clamp(simd_dot(pa, ba) / simd_dot(ba, ba), 0.0f, 1.0f);
    const simd_float3 pt = a + t * ba;
    return simd_length(pt - pos);
}
