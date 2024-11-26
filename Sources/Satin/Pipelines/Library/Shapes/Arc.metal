// https://www.shadertoy.com/view/tlSGzG (sdfArc2) // 6.28318530717958648 = TWO_PI
float Arc(float2 uv, float startAngle, float endAngle, float radius) {
    float a = fmod(atan2(uv.y, uv.x), 6.28318530717958648);

    float ap = a - startAngle;
    if (ap < 0.0) { ap += 6.28318530717958648; }

    float a1p = endAngle - startAngle;
    if (a1p < 0.0) { a1p += 6.28318530717958648; }

    // is a outside [a0, a1]?
    // https://math.stackexchange.com/questions/1044905/simple-angle-between-two-angles-of-circle
    if (ap >= a1p) {
        // snap to the closest of the two endpoints
        float2 q0 = float2(radius * cos(startAngle), radius * sin(startAngle));
        float2 q1 = float2(radius * cos(endAngle), radius * sin(endAngle));
        return min(length(uv - q0), length(uv - q1));
    }

    return abs(length(uv) - radius);
}
