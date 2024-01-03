float Rect(float2 pos, float2 size)
{
    float2 v = abs(pos) - size;
    return max(v.x, v.y);
}