// Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
// https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
float3 aces(float3 x)
{
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

half3 acesh(half3 x)
{
    const half a = 2.51h;
    const half b = 0.03h;
    const half c = 2.43h;
    const half d = 0.59h;
    const half e = 0.14h;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0h, 1.0h);
}

float aces(float x)
{
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}
