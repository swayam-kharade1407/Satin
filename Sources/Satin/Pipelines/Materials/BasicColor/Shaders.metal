typedef struct {
    float4 color; // color
} BasicColorUniforms;

fragment half4 basicColorFragment(VertexData in [[stage_in]], constant BasicColorUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]])
{
    return half4(uniforms.color);
}
