#include "Library/Colors.metal"
#include "Library/CubicSmooth.metal"

typedef struct {
    float amount; // slider,0,1,0.5
} DisplacementUniforms;

constexpr sampler s( min_filter::linear, mag_filter::linear );

typedef struct {
    float4 position [[position]];
    float2 texcoord;
} CustomVertexData;

vertex CustomVertexData displacementVertex(
                                           Vertex in [[stage_in]],
                                           ushort amp_id [[amplification_id]],
                                           constant VertexUniforms *vertexUniforms [[buffer( VertexBufferVertexUniforms )]],
                                           constant DisplacementUniforms &uniforms [[buffer( VertexBufferMaterialUniforms )]],
                                           texture2d<float> waveTex [[texture( VertexTextureCustom0 )]] )
{
    CustomVertexData out;

    const float4 sample = waveTex.sample( s, in.texcoord );

    float3 position = in.position;
    position += in.normal * sample.r * uniforms.amount;

#if INSTANCING
    out.position = vertexUniforms[amp_id].viewProjectionMatrix * instanceUniforms[instanceID].modelMatrix * float4( position, 1.0 );
#else
    out.position = vertexUniforms[amp_id].modelViewProjectionMatrix * float4( position, 1.0 );
#endif

    out.texcoord = in.texcoord;
    return out;
}

fragment float4 displacementFragment(
                                     CustomVertexData in [[stage_in]],
                                     constant DisplacementUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
                                     texture2d<float> waveTex [[texture( FragmentTextureCustom0 )]] )
{
    const float4 sample = waveTex.sample( s, in.texcoord );
    return float4( turbo( cubicSmooth( abs( sample.r ) ) ), 1.0 );
}
