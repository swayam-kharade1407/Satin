#include "Library/Pi.metal"
#include "Library/Shapes.metal"

typedef struct {
    int2 size;
} RadianceCascadesUniforms;

#define base 4
#define basef 4.0

float scene(float2 pos) { return Circle(pos, 150.0); }

float4 rayMarch(float2 origin, float2 direction, float maxLength) {
    float2 pos = origin;
    float t = 0;
    for (int i = 0; i < 128; i++) {
        float dist = scene(pos);
        t += abs(dist);

        if (t >= maxLength) { return 0.0; }

        if (dist < 1) { return 1.0; }

        pos = origin + direction * t;
        return 0.0;
    }
}

kernel void radianceCascadesUpdate(
    uint2 gid [[thread_position_in_grid]],
    constant RadianceCascadesUniforms &uniforms [[buffer(ComputeBufferUniforms)]],
    texture2d_array<float, access::write> textures [[texture(ComputeTextureCustom0)]]) {

    const uint2 resolution = uint2(textures.get_width(), textures.get_height());
    const float2 sceneResolution = float2(resolution) * 2.0;
    const uint cascades = textures.get_array_size();

    if (gid.x >= resolution.x || gid.y >= resolution.y) { return; }

    float intervalStart = 0.0;
    // 0, 1, 2, 3, 4, 5 (cascadeIndex)
    for (uint cascadeIndex = 0; cascadeIndex < cascades; cascadeIndex++) {
        // 1, 4, 16, 64, 256, 1024 (intervalLength)
        float intervalLength = pow(basef, cascadeIndex);

        // 2, 4, 8, 16, 32, 64 (probeSize)
        uint2 probeSize = uint2(2.0 * pow(2.0, cascadeIndex));
        uint2 probeCount = resolution / probeSize;

        uint2 cell = gid / probeSize;
        float2 cellf = float2(cell);
        uint2 c = gid % probeSize;
        uint index = c.y * probeSize.x + c.x;

        // Ray Cast Intervals (start > end)

        // 0: 0 > 1       (+4)
        // 1: 1 > 5       (+16)
        // 2: 5 > 21      (+64)
        // 3: 21 > 85     (+256)
        // 4: 85 > 341    (+1024)
        // 5: 341 > 1,365

        // 4, 16, 64, 1024, 4098 (rayCount)
        uint rayCount = pow(basef, float(cascadeIndex) + 1);
        float2 probeSizef = float2(probeSize);

        float2 probeOrigin = cellf * probeSizef + probeSizef * 0.5;
        // probeOrigin /= float2(probeCount * probeSize);

        float indexNormalized = float(index) / float(rayCount);
        float angle = TWO_PI * indexNormalized + HALF_PI * 0.5;
        float2 rayDirection = float2(cos(angle), sin(angle));
        float2 rayOrigin = probeOrigin + rayDirection * intervalStart;

        float4 sceneSample = rayMarch(rayOrigin, rayDirection, intervalLength);

        float4 sample = float4(float2(c) / float2(probeSize), 0.0, 1.0);

        sample.xy = rayDirection.xy;
        sample.z = indexNormalized;
        sample.xyz += sceneSample.x;

        // textures.write(sceneSample, gid, cascadeIndex);
        textures.write(sample, gid, cascadeIndex);

        // 1, 5, 21, 85, 341 (intervalStart)
        intervalStart += intervalLength;
    }
}
