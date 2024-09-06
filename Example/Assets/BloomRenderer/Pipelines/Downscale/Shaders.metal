typedef struct {
    int2 size;
} DownscaleUniforms;

constexpr sampler sam = sampler( address::clamp_to_edge,
                                filter::linear );

kernel void downscaleUpdate( uint2 gid [[thread_position_in_grid]],
                            texture2d<float, access::write> outTex [[texture( ComputeTextureCustom0 )]],
                            texture2d<float, access::sample> renderTex [[texture( ComputeTextureCustom1 )]],
                            constant DownscaleUniforms &uniforms [[buffer( ComputeBufferUniforms )]] )
{
    const uint2 size = uint2( uniforms.size );

    if( gid.x >= size.x || gid.y >= size.y ) {
        return;
    }

    const float2 sizef = float2( size );

    const uint2 renderSize = uint2( size * 2 );
    const float2 renderSizef = float2( renderSize );

    const float2 renderTexelSize = 1.0 / renderSizef;
    const float2 uv = ( float2( gid ) + 0.5 ) / sizef;

    const float dx = renderTexelSize.x;
    const float dy = renderTexelSize.y;
    const float dx2 = 2.0 * dx;
    const float dy2 = 2.0 * dy;

    // 13 samples around current texel:
    // a - b - c
    // - j - k -
    // d - e - f
    // - l - m -
    // g - h - i
    // === ('e' is the current texel) ===

    const float3 a = renderTex.sample( sam, float2( uv.x - dx2, uv.y + dy2 ) ).rgb;
    const float3 b = renderTex.sample( sam, float2( uv.x, uv.y + dy2 ) ).rgb;
    const float3 c = renderTex.sample( sam, float2( uv.x + dx2, uv.y + dy2 ) ).rgb;

    const float3 j = renderTex.sample( sam, float2( uv.x - dx, uv.y + dy ) ).rgb;
    const float3 k = renderTex.sample( sam, float2( uv.x + dx, uv.y + dy ) ).rgb;

    const float3 d = renderTex.sample( sam, float2( uv.x - dx2, uv.y ) ).rgb;
    const float3 e = renderTex.sample( sam, uv ).rgb;
    const float3 f = renderTex.sample( sam, float2( uv.x + dx2, uv.y ) ).rgb;

    const float3 l = renderTex.sample( sam, float2( uv.x - dx, uv.y - dy ) ).rgb;
    const float3 m = renderTex.sample( sam, float2( uv.x + dx, uv.y - dy ) ).rgb;

    const float3 g = renderTex.sample( sam, float2( uv.x - dx2, uv.y - dy2 ) ).rgb;
    const float3 h = renderTex.sample( sam, float2( uv.x, uv.y - dy2 ) ).rgb;
    const float3 i = renderTex.sample( sam, float2( uv.x + dx2, uv.y - dy2 ) ).rgb;

    float3 out = e * 0.125;
    out += ( a + c + g + i ) * 0.03125;
    out += ( b + d + f + h ) * 0.0625;
    out += ( j + k + l + m ) * 0.125;

    outTex.write( float4( out, 1.0 ), gid );
}
