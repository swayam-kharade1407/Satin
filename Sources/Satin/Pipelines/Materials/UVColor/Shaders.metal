fragment float4 uvcolorFragment(VertexData in [[stage_in]])
{
    return float4(in.texcoord, 0.0, 1.0);
}
