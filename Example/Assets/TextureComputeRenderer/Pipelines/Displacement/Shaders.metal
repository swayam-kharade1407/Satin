#include "Library/Colors.metal"

typedef struct {
    float amount; // slider,0,1,0.2
} DisplacementUniforms;

constexpr sampler s( min_filter::linear, mag_filter::linear );

typedef struct {
    float4 position [[position]];
    float4 color;
} CustomVertexData;

vertex CustomVertexData displacementVertex(
                                           Vertex in [[stage_in]],
                                           ushort amp_id [[amplification_id]],
                                           constant VertexUniforms *vertexUniforms [[buffer( VertexBufferVertexUniforms )]],
                                           constant DisplacementUniforms &uniforms [[buffer( VertexBufferMaterialUniforms )]],
                                           texture2d<float> rdTex [[texture( VertexTextureCustom0 )]] )
{
    CustomVertexData out;

    const float4 sample = rdTex.sample( s, in.texcoord );

    float3 position = in.position;
    position += in.normal * sample.g * uniforms.amount;

#if INSTANCING
    out.position = vertexUniforms[amp_id].viewProjectionMatrix * instanceUniforms[instanceID].modelMatrix * float4( position, 1.0 );
#else
    out.position = vertexUniforms[amp_id].modelViewProjectionMatrix * float4( position, 1.0 );
#endif

    out.color = sample;

    // inject shadow vertex calc
    return out;
}

fragment float4 displacementFragment(
                                     CustomVertexData in [[stage_in]],
                                     constant DisplacementUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]] )
{
    return float4( scatter( in.color.g, in.color.rgb ), 1.0 );
}
