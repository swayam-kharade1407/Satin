typedef struct {
    float4 color; //color
} CustomUniforms;

typedef struct {
    float4 position [[position]];
    float3 normal;
    float2 texcoord;
#if defined(HAS_TANGENT)
    float3 tangent;
#endif
#if defined(HAS_BITANGENT)
    float3 bitangent;
#endif
} CustomVertexData;

vertex CustomVertexData customVertex(
    Vertex in [[stage_in]],
    constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]])
{
    const float4 position = float4(in.position, 1.0);

    CustomVertexData out;
    out.position = vertexUniforms.modelViewProjectionMatrix * position;
    out.normal = normalize(vertexUniforms.normalMatrix * in.normal);
#if defined(HAS_TEXCOORD)
    out.texcoord = in.texcoord;
#endif
    
#if defined(HAS_TANGENT)
    out.tangent = in.tangent;
#endif

#if defined(HAS_BITANGENT)
    out.bitangent = in.bitangent;
#endif

    return out;
}

fragment float4 customFragment(
    CustomVertexData in [[stage_in]],
    constant CustomUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]])
{
#if defined(HAS_BITANGENT)
    return float4(normalize(in.bitangent), 1.0);
#else
    return float4(normalize(in.normal), 1.0);
#endif
}
