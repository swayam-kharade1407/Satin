#include "Library/Pi.metal"
#include "Library/Shapes.metal"

typedef struct {
} PostUniforms;

constexpr sampler s(filter::nearest);

typedef struct {
    float4 position [[position]];
    float2 texcoord [[shared]];
    uint instance;
} CustomVertexData;

vertex CustomVertexData postVertex(
    Vertex in [[stage_in]],
    ushort amp_id [[amplification_id]],
    uint instance_id [[instance_id]],
    constant PostUniforms &uniforms [[buffer(VertexBufferMaterialUniforms)]],
    constant VertexUniforms *vertexUniforms [[buffer(VertexBufferVertexUniforms)]]) {
    CustomVertexData out;
    float4 position = float4(in.position, 1.0);
    position.x += instance_id * 2.01;
#if INSTANCING
    const float4 worldPosition = instanceUniforms[instanceID].modelMatrix * position;
#else
    const float4 worldPosition = vertexUniforms[amp_id].modelMatrix * position;
#endif
    out.position = vertexUniforms[amp_id].viewProjectionMatrix * worldPosition;
    out.texcoord = in.texcoord;
    out.instance = instance_id;
    return out;
}

float scene(float2 pos) { return Circle(pos, 0.25); }

float4 rayMarch(float2 origin, float2 direction, float maxLength) {
    float2 pos = origin;
    float dist = 10000000.0;
    for (int i = 0; i <= maxLength; i++) {
        dist = scene(pos);
        if (dist < 0.00001) { return 1.0; }
        pos = origin + direction * dist * 0.25;
    }
    return 0.0;
}

fragment float4 postFragment(
    CustomVertexData in [[stage_in]],
    constant PostUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]],
    texture2d_array<float> radianceCascades [[texture(FragmentTextureCustom0)]]) {

    // float2 uv = in.texcoord * 2.0 - 1.0;
    // float4 color = 0.0;
    // for (int i = 0; i < 16; i++) {
    //     float angle = i * TWO_PI / 16.0;
    //     color += rayMarch(uv, float2(cos(angle), sin(angle)), 32);
    // }
    // color /= 16.0;
    // return color;

    return radianceCascades.sample(s, in.texcoord, in.instance);
}
