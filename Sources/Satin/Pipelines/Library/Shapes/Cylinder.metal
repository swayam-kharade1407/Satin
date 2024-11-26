#include "Circle.metal"

float Cylinder(float3 pos, float radius, float height) {
    float c = Circle(pos.xy, radius);
    float h = abs(pos.z) - height;
    return max(c, h);
}
