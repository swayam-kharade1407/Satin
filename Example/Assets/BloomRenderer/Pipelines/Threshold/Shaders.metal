#include "Library/Luminance.metal"

typedef struct {
    int2 size;
} ThresholdUniforms;

constexpr sampler sam = sampler( address::clamp_to_edge, filter::linear, coord::pixel );

kernel void thresholdUpdate( uint2 gid [[thread_position_in_grid]],
                            texture2d<float, access::write> outTex [[texture( ComputeTextureCustom0 )]],
                            texture2d<float, access::sample> renderTex [[texture( ComputeTextureCustom1 )]],
                            constant ThresholdUniforms &uniforms [[buffer( ComputeBufferUniforms )]] )
{
    const uint2 size = uint2( uniforms.size );

    if( gid.x >= size.x || gid.y >= size.y ) {
        return;
    }

    const float4 out = renderTex.sample( sam, float2( gid ) );
    outTex.write( out * step( 0.8, luminance3( out.rgb ) ), gid );
}
