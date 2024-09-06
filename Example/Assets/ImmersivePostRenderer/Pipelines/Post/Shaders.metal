#include "Library/Tonemapping/Aces.metal"

typedef struct {
    float4 color; // color
} PostUniforms;

typedef struct {
    float4 position [[position]];
    float2 texcoord;
} CustomVertexData;

vertex CustomVertexData postVertex(Vertex in [[stage_in]],
                                   ushort amp_id [[amplification_id]],
                                   constant PostUniforms &uniforms [[buffer( VertexBufferMaterialUniforms )]],
                                   constant VertexUniforms *vertexUniforms [[buffer( VertexBufferVertexUniforms )]] )
{
    CustomVertexData out;
#if INSTANCING
    const float4 worldPosition = instanceUniforms[instanceID].modelMatrix * float4( in.position, 1.0 );
    out.position = vertexUniforms[amp_id].viewProjectionMatrix * worldPosition;
#else
    out.position = vertexUniforms[amp_id].modelViewProjectionMatrix * float4( in.position, 1.0 );
#endif
    out.texcoord = in.texcoord;
    return out;
}

half4 process(half4 sample) {
    sample.rgb = 1.0h - sample.rgb;
    sample.rgb = acesh(sample.rgb);
    return sample;
}

#if defined(LAYERED)

constexpr sampler samPixel(coord::pixel, filter::linear, address::clamp_to_edge );

fragment half4 postFragment
(
    CustomVertexData in [[stage_in]],
    ushort amp_id [[amplification_id]],
    texture2d_array<half> tex [[texture(FragmentTextureCustom0)]]
)
{
    return process(tex.sample(samPixel, in.position.xy, amp_id));
}

#else

constexpr sampler samNorm(coord::normalized, filter::linear, address::clamp_to_edge );

fragment half4 postFragment
(
    CustomVertexData in [[stage_in]],
    ushort amp_id [[amplification_id]],
    texture2d<half> tex [[texture(FragmentTextureCustom0)]]
)
{
    return process(tex.sample(samNorm, in.texcoord));
}

#endif

