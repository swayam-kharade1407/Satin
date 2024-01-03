#include "Box.metal"
#include "Plane.metal"

#define sabs(p) sqrt((p) * (p) + 2e-3)
#define smin(a, b) (a + b - sabs(a - b)) * .5
#define smax(a, b) (a + b + sabs(a - b)) * .5

float Octahedron(float3 pos, float size)
{
    float s = size * 0.5;
    float3 r = abs(pos) - float3(s);
    return r.x + r.y + r.z;
}

float Tetrahedron(float3 pos, float size)
{
    float hs = size;
    float result = Box(pos, size);
    result = max(result, -Plane(pos, float3(1, 1, 1), hs));
    result = max(result, -Plane(pos, float3(1, -1, -1), hs));
    result = max(result, -Plane(pos, float3(-1, 1, -1), hs));
    result = max(result, -Plane(pos, float3(-1, -1, 1), hs));
    return result;
}

float Dodecahedron(float3 pos, float r)
{
    const float G = sqrt(5.) * .5 + .5;
    const float3 n = normalize(float3(G, 1, 0));
    float d = 0.0;
    pos = sabs(pos);
    d = smax(d, dot(pos, n));
    d = smax(d, dot(pos, n.yzx));
    d = smax(d, dot(pos, n.zxy));
    return d - r;
}

float Icosahedron(float3 pos, float r)
{
    const float G = sqrt(5.) * .5 + .5;
    const float3 n = normalize(float3(G, 1. / G, 0));
    float d = 0.;
    pos = sabs(pos);
    d = smax(d, dot(pos, n));
    d = smax(d, dot(pos, n.yzx));
    d = smax(d, dot(pos, n.zxy));
    d = smax(d, dot(pos, normalize(float3(1.0))));
    return d - r;
}