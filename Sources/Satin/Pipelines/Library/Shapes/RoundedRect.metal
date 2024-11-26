float RoundedRect(float2 pos, float2 size, float radius) {
    float2 v = max(abs(pos) - size, 0.0);
    return length(v) - radius;
}