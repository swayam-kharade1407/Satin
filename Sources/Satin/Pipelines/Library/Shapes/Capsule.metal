#include "Line.metal"

float Capsule(float3 pos, float3 a, float3 b, float r)
{
    return Line(pos, a, b) - r;
}
