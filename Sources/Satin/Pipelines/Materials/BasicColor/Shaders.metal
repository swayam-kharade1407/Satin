typedef struct {
    float4 color; // color
} BasicColorUniforms;

typedef struct {
    float4 position [[position]];
} BasicColorVertexData;

vertex BasicColorVertexData basicTextureVertex(
    Vertex in [[stage_in]],
    // inject instancing args
    ushort amp_id [[amplification_id]],
    constant VertexUniforms *vertexUniforms [[buffer(VertexBufferVertexUniforms)]]) {
    BasicColorVertexData out;

#if INSTANCING
    out.position = vertexUniforms[amp_id].viewProjectionMatrix *
                   instanceUniforms[instanceID].modelMatrix * float4(in.position, 1.0);
#else
    out.position = vertexUniforms[amp_id].modelViewProjectionMatrix * float4(in.position, 1.0);
#endif

    return out;
}

fragment half4 basicColorFragment(
    BasicColorVertexData in [[stage_in]],
    constant BasicColorUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]]) {
    return half4(uniforms.color);
}
