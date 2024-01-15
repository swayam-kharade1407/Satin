typedef struct {
    float4 color; // color
} SDFontUniforms;

typedef struct {
    float4 position [[position]];
    float2 texcoord;
} CustomVertexData;

vertex CustomVertexData sdfontVertex
(
    Vertex in [[stage_in]],
    constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]]
)
{
    CustomVertexData out;

#if INSTANCING
    out.position = vertexUniforms.viewProjectionMatrix * instanceUniforms[instanceID].modelMatrix * float4(in.position, 1.0);
#else
    out.position = vertexUniforms.modelViewProjectionMatrix * float4(in.position, 1.0);
#endif

    out.texcoord = in.texcoord;

    return out;
}

fragment float4 sdfontFragment
(
    CustomVertexData in [[stage_in]],
    constant SDFontUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
    texture2d<float> fontTexture [[texture( FragmentTextureCustom0 )]] )
{
    constexpr sampler s = sampler( min_filter::linear, mag_filter::linear );

    float sample = fontTexture.sample( s, in.texcoord ).r;
    float sigDist = sample - 0.5;
    float fsigDist = fwidth( sigDist );
    float alpha = saturate( smoothstep( -fsigDist, fsigDist, sigDist ) );

    float4 color = uniforms.color;
    color.a *= alpha;

    return color;
}
