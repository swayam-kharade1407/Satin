fragment half4 uvcolorFragment(VertexData in [[stage_in]])
{
    return half4(half2(in.texcoord), 0.0h, 1.0h);
}
