#include "Library/Colors.metal"
#include "Library/Gamma.metal"

typedef struct {
    float4 color; // color
} DiskUniforms;

vertex VertexData diskVertex(
                             // inject instancing args
                             Vertex in [[stage_in]],
                             ushort amp_id [[amplification_id]],
                             constant VertexUniforms *vertexUniforms [[buffer( VertexBufferVertexUniforms )]],
                             constant DiskUniforms &sprite [[buffer( VertexBufferMaterialUniforms )]] )
{
    // Extract the right (x) and up (y) vectors from the view matrix, and normalize them
    const float4x4 viewMatrix = vertexUniforms[amp_id].viewMatrix;
    const float3 right = float3( viewMatrix[0][0], viewMatrix[1][0], viewMatrix[2][0] );
    const float3 up = float3( viewMatrix[0][1], viewMatrix[1][1], viewMatrix[2][1] );

    float4 position = float4( in.position, 1.0 );
    position.xyz = position.x * right + position.y * up;

#if INSTANCING
    position = instanceUniforms[instanceID].modelMatrix * position;
#else
    position = vertexUniforms[amp_id].modelMatrix * position;
#endif

    VertexData out;
    out.position = vertexUniforms[amp_id].viewProjectionMatrix * position;
    out.normal = in.normal;
    out.texcoord = in.texcoord;
    return out;
}

fragment float4 diskFragment( VertexData in [[stage_in]],
                             constant DiskUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]] )
{
    const float2 uv = in.texcoord;
    const float len = length( uv );
    if( len > 1.0 ) {
        discard_fragment();
    }

    float3 normal = normalize( float3( uv, 1.0 ) );
    float dp = dot( normal, float3( 0.0, 0.0, 1.0 ) );
    float3 color = float3( iridescence( dp * dp * dp * dp ) );
    color = gamma( color );
    color += mix( 0.0, 1.0, pow( len, 16.0 ) );
    return float4( dp * color, 1.0 );
}
