#include "Rect.metal"

float Pyramid(float3 pos, float3 size)
{
    float y = (size.y * 0.5) - pos.y;
    float c = Rect(pos.xz, size.xz * (y / size.y));
    float h = abs(y) - size.y;
    return max(c, h);
}