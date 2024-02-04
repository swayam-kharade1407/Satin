typedef struct {
    float4 color; //color
} AmplificationUniforms;

vertex VertexData amplificationVertex
(
    ushort amp_id [[amplification_id]],
    ushort amp_count [[amplification_count]],
    Vertex in [[stage_in]],
    constant VertexUniforms *uniforms [[buffer( VertexBufferVertexUniforms )]]
)
{
    float4 position = float4(in.position, 1.0);

    VertexData out;
    out.position = uniforms[amp_id].modelViewProjectionMatrix * position;
    out.normal = uniforms[amp_id].normalMatrix * in.normal;
    out.texcoord = in.texcoord;
    return out;
}

fragment float4 amplificationFragment
(
    VertexData in [[stage_in]],
    constant AmplificationUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]]
)
{
    return uniforms.color * float4(in.texcoord, 1.0, 1.0);
}
