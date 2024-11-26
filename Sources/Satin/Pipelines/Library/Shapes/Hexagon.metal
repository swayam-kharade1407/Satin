#define HEXANGLE tan(3.1415926536 / 3.0) / 2.0

float Hexagon(float3 pos, float2 size) {
    float3 apos = abs(pos);
    float z = apos.z - size.y;
    float xy = max(apos.x * HEXANGLE + apos.y * 0.5, apos.y) - size.x;
    return max(xy, z);
}

float Hexagon(float2 pos, float2 size) {
    float3 apos = abs(float3(pos, 0.0));
    float z = apos.z - size.y;
    float xy = max(apos.x * HEXANGLE + apos.y * 0.5, apos.y) - size.x;
    return max(xy, z);
}
