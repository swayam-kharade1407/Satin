float Torus(float3 pos, float2 size)
{
    float2 c2 = float2(length(pos.xy) - size.x, pos.z);
    return length(c2) - size.y;
}