typedef struct {
    float4 color; //color
} CustomUniforms;

vertex VertexData customVertex
(
    Vertex in [[stage_in]],
    // inject instancing args
    // inject shadow vertex args
    constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]]
)
{
    const float4 position = float4(in.position.xyz, 1.0);

    VertexData out;
#if INSTANCING
    out.position = vertexUniforms.viewProjectionMatrix * instanceUniforms[instanceID].modelMatrix * position;
    out.normal = instanceUniforms[instanceID].normalMatrix * in.normal;
#else
    out.position = vertexUniforms.modelViewProjectionMatrix * position;
    out.normal = vertexUniforms.normalMatrix * in.normal;
#endif
    out.texcoord = in.texcoord;
    // inject shadow vertex calc
    return out;
}

fragment float4 customFragment
(
    VertexData in [[stage_in]],
    // inject shadow fragment args
    constant CustomUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]]
)
{
    float4 outColor = uniforms.color;
    // inject shadow fragment calc
    return outColor;
}
