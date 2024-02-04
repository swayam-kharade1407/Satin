typedef struct {
} ViewportUniforms;

fragment float4 viewportFragment
(
    VertexData in [[stage_in]],
    constant ViewportUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
    texture2d_array<float, access::sample> colorTex [[texture( FragmentTextureCustom0 )]]
)
{
    constexpr sampler colorSampler = sampler(filter::linear);

    float2 uv = in.texcoord;
    uv.x *= 2.0;

    float index = 0;
    uv.x = modf(uv.x, index);

    float4 color = colorTex.sample(colorSampler, uv, ushort(index));
    return color;
}
