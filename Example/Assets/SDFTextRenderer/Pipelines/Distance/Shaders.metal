typedef struct {
    float4 color; // color
} DistanceUniforms;

fragment float4 distanceFragment(
                             VertexData in [[stage_in]],
                             constant DistanceUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
                             texture2d<float> sdfTexture [[texture( FragmentTextureCustom0 )]] )
{
    constexpr sampler s = sampler( min_filter::linear, mag_filter::linear );

    float sample = sdfTexture.sample( s, in.texcoord ).r;
    float sigDist = sample - 0.5;
    float fsigDist = fwidth( sigDist );
    float alpha = saturate( smoothstep( -fsigDist, fsigDist, sigDist ) );

    float4 color = uniforms.color;
    color.a *= alpha;

    return color;
}
