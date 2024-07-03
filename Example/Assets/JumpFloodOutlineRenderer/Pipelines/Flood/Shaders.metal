fragment half4 floodFragment(VertexData in [[stage_in]])
{
    return half4(half2(in.position.xy), 0.0h, 0.0h);
}
