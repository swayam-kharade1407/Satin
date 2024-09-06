typedef struct {
    int2 size;
} UpscaleUniforms;

constexpr sampler sam = sampler(
                                address::clamp_to_edge,
                                filter::linear );

/*
 E' = E
 D' = D + blur(E', b4)
 C' = C + blur(D', b3)
 B' = B + blur(C', b2)
 A' = A + blur(B', b1)
 Fullres = mix(FullRes, A', bloomStrength)
 */

kernel void upscaleUpdate( uint2 gid [[thread_position_in_grid]],
                          texture2d<float, access::write> outTex [[texture( ComputeTextureCustom0 )]],
                          texture2d<float, access::sample> prevTex [[texture( ComputeTextureCustom1 )]],
                          texture2d<float, access::sample> downTex [[texture( ComputeTextureCustom2 )]],
                          constant UpscaleUniforms &uniforms [[buffer( ComputeBufferUniforms )]] )
{
    const uint2 size = uint2( uniforms.size );

    if( gid.x >= size.x || gid.y >= size.y ) {
        return;
    }

    const float2 sizef = float2( size );

    const uint2 prevSize = size / 2;
    const float2 prevSizef = float2( prevSize );

    const float2 prevTexelSize = 1.0 / ( prevSizef );
    float2 uv = ( float2( gid ) + 0.5 ) / ( sizef );

    // The filter kernel is applied with a radius, specified in texture
    // coordinates, so that the radius will vary across mip resolutions.
    const float dx = prevTexelSize.x;
    const float dy = prevTexelSize.y;

    // Take 9 samples around current texel:
    // a - b - c
    // d - e - f
    // g - h - i
    // === ('e' is the current texel) ===

    const float3 a = prevTex.sample( sam, float2( uv.x - dx, uv.y + dy ) ).rgb;
    const float3 b = prevTex.sample( sam, float2( uv.x, uv.y + dy ) ).rgb;
    const float3 c = prevTex.sample( sam, float2( uv.x + dx, uv.y + dy ) ).rgb;

    const float3 d = prevTex.sample( sam, float2( uv.x - dx, uv.y ) ).rgb;
    const float3 e = prevTex.sample( sam, uv ).rgb;
    const float3 f = prevTex.sample( sam, float2( uv.x + dx, uv.y ) ).rgb;

    const float3 g = prevTex.sample( sam, float2( uv.x - dx, uv.y - dy ) ).rgb;
    const float3 h = prevTex.sample( sam, float2( uv.x, uv.y - dy ) ).rgb;
    const float3 i = prevTex.sample( sam, float2( uv.x + dx, uv.y - dy ) ).rgb;

    // Apply weighted distribution, by using a 3x3 tent filter:
    //  1   | 1 2 1 |
    // -- * | 2 4 2 |
    // 16   | 1 2 1 |

    float3 out = e * 4.0;
    out += ( b + d + f + h ) * 2.0;
    out += ( a + c + g + i );
    out *= 1.0 / 16.0;

    float3 down = downTex.sample( sam, uv ).rgb;
    outTex.write( float4( down + out, 1.0 ), gid );
}
