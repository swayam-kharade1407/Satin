typedef struct {
    float4 color; // color
} TextUniforms;

typedef struct {
    float4 position [[position]];
    float2 texcoord;
} CustomVertexData;

vertex CustomVertexData textVertex
(
    Vertex in [[stage_in]],
    ushort amp_id [[amplification_id]],
    constant VertexUniforms *vertexUniforms [[buffer(VertexBufferVertexUniforms)]]
)
{
    CustomVertexData out;

#if INSTANCING
    out.position = vertexUniforms[amp_id].viewProjectionMatrix * instanceUniforms[instanceID].modelMatrix * float4(in.position, 1.0);
#else
    out.position = vertexUniforms[amp_id].modelViewProjectionMatrix * float4(in.position, 1.0);
#endif

    out.texcoord = in.texcoord;

    return out;
}

fragment float4 textFragment(
    CustomVertexData in [[stage_in]],
    constant TextUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]],
    texture2d<float> fontTexture [[texture(FragmentTextureCustom0)]])
{
    constexpr sampler s = sampler(min_filter::linear, mag_filter::linear);

    float sample = fontTexture.sample(s, in.texcoord).r;
    float sigDist = sample - 0.5;
    float fsigDist = fwidth(sigDist);
    float alpha = saturate(smoothstep(-fsigDist, fsigDist, sigDist));

    //    if (alpha < 0.05) { discard_fragment(); }

    float4 color = uniforms.color;
    color.a *= alpha;

    return color;
}
