#include "Library/Random.metal"

typedef struct {
    float grainAmount; //slider,0,1,0.5
    float bloomAmount; //slider,0,4,0.66
    float grainIntensity;
    float time;
} BloomUniforms;

static constexpr sampler s = sampler( min_filter::linear, mag_filter::linear );

float4 getGrain(texture3d<float> grainTex, float2 fragPos, float2 uv, float grainIntensity, float time) {
    const float2 grainSize = float2(grainTex.get_width(), grainTex.get_height());

    const float2 grainUV = fmod(fragPos, grainSize) / grainSize;
    const int2 grainCell = int2(fragPos / grainSize);

    const float3 noiseUV = float3(grainUV, time);
    const float2 noiseOffset = float2(random(noiseUV, 123 + grainCell.x), random(noiseUV, 234 + grainCell.y));

    const float3 guv = float3(fract(grainUV + noiseOffset), grainIntensity);

    return grainTex.sample(s, guv);
}

fragment float4 bloomFragment
(
    VertexData in [[stage_in]],
    constant BloomUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
    texture2d<float, access::sample> bloomTex [[texture( FragmentTextureCustom0 )]],
    texture3d<float> grainTex [[texture( FragmentTextureCustom1 )]]
)
{
    const float4 bloomSample = bloomTex.sample( s, in.texcoord );
    const float4 grainSample = getGrain(grainTex, in.position.xy, in.texcoord, uniforms.grainIntensity, uniforms.time);

    float4 color = float4(0.0, 0.0, 0.0, 1.0);
    color.rgb = mix(0.0, grainSample.rgb * grainSample.a, uniforms.grainAmount);
    color.rgb += bloomSample.a * bloomSample.rgb * uniforms.bloomAmount;
    return color;
}





