float Box(float3 pos, float3 size)
{
    float3 result = abs(pos) - size;
    return min(max(result.x, max(result.y, result.z)), 0.0) + length(max(result, 0.0));
}

float Box(float3 pos, float size) { return Box(pos, float3(size)); }

float Box(float3 pos, float3 size, float radius)
{
    float3 result = abs(pos) - size;
    return length(max(result, 0.0)) - radius;
}

float Box(float3 pos, float size, float radius) { return Box(pos, float3(size), radius); }
