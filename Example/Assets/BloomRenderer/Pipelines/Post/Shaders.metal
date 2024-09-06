typedef struct {
    float bloom; // slider,0,4,1.0
} PostUniforms;

constexpr sampler s = sampler( filter::linear, mip_filter::nearest );

fragment float4 postFragment( VertexData in [[stage_in]],
                             constant PostUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
                             texture2d<float> renderTex [[texture( FragmentTextureCustom0 )]],
                             texture2d<float> bloomTex [[texture( FragmentTextureCustom1 )]] )
{
    const float2 uv = in.texcoord;

    float4 color = renderTex.sample( s, uv );
    color.rgb += bloomTex.sample( s, uv ).rgb * uniforms.bloom;
    return color;
}
