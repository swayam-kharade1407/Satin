#include "Library/Pi.metal"
#include "Library/Rotate.metal"

static constant float4 rotations[6] = {
    float4(0.0, 1.0, 0.0, HALF_PI), float4(0.0, 1.0, 0.0, -HALF_PI), float4(1.0, 0.0, 0.0, -HALF_PI), float4(1.0, 0.0, 0.0, HALF_PI), float4(0.0, 0.0, 1.0, 0.0), float4(0.0, 1.0, 0.0, PI)
};

#define WORLD_UP float3(0.0, 1.0, 0.0)
#define WORLD_FORWARD float3(0.0, 0.0, 1.0)
#define DELTA_PHI (TWO_PI / 180.0)
#define DELTA_THETA (HALF_PI / 45.0)

typedef struct {
    int2 size;
} DiffuseIBLUniforms;

constexpr sampler cubeSampler(mag_filter::linear, min_filter::linear);

kernel void diffuseIBLUpdate(
    uint2 gid [[thread_position_in_grid]],
    texturecube<float, access::write> tex [[texture(ComputeTextureCustom0)]],
    texturecube<float, access::sample> ref [[texture(ComputeTextureCustom1)]],
    constant DiffuseIBLUniforms &uniforms [[buffer(ComputeBufferUniforms)]],
    constant uint &face [[buffer(ComputeBufferCustom0)]]) {
    const uint size = uint(tex.get_width());

    if (gid.x >= size || gid.y >= size) { return; }

    const float2 uv = (float2(gid) + 0.5) / float2(size);
    float2 ruv = 2.0 * uv - 1.0;
    ruv.y *= -1.0;

    float3 irradiance = 0.0;

    const float4 rotation = rotations[face];
    const float3 N = normalize(float3(ruv, 1.0) * rotateAxisAngle(rotation.xyz, rotation.w));

    float3 UP = abs(N.z) < 0.999 ? WORLD_FORWARD : WORLD_UP;
    const float3 RIGHT = normalize(cross(UP, N));
    UP = cross(N, RIGHT);

    uint sampleCount = 0u;

    for (float phi = 0.0; phi < TWO_PI; phi += DELTA_PHI) {

        float cosPhi;
        const float sinPhi = sincos(phi, cosPhi);

        for (float theta = 0.0; theta < HALF_PI; theta += DELTA_THETA) {
            // spherical to cartesian (in tangent space)
            float cosTheta;
            const float sinTheta = sincos(theta, cosTheta);

            const float3 tempVec = cosPhi * RIGHT + sinPhi * UP;
            const float3 sampleVector = cosTheta * N + sinTheta * tempVec;

            irradiance += ref.sample(cubeSampler, sampleVector).rgb * cosTheta * sinTheta;
            sampleCount++;
        }
    }

    irradiance = PI * irradiance / float(sampleCount);
    tex.write(float4(irradiance, 1.0), gid, face);
}
