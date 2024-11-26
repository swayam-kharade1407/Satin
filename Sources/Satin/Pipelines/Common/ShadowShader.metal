vertex float4 satinShadowVertex(
    Vertex in [[stage_in]],
    // inject instancing args
    constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]]) {
    const float4 position = float4(in.position, 1.0);
#if INSTANCING
    return vertexUniforms.viewProjectionMatrix * instanceUniforms[instanceID].modelMatrix *
           position;
#else
    return vertexUniforms.modelViewProjectionMatrix * position;
#endif
}
