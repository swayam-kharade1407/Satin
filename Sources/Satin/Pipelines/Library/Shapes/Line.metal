float Line(float2 pos, float2 a, float2 b)
{
    float2 pa = pos - a;
    float2 ba = b - a;
    float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    float2 pt = a + t * ba;
    return length(pt - pos);
}

float Line(float3 pos, float3 a, float3 b)
{
    float3 pa = pos - a;
    float3 ba = b - a;
    float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    float3 pt = a + t * ba;
    return length(pt - pos);
}
