#include "Library/Pi.metal"
#include "Library/Repeat.metal"
#include "Library/Csg.metal"
#include "Library/Shapes.metal"

typedef struct {
    float4 color; // color
} GridUniforms;

typedef struct {
    float4 position [[position]];
    float4 worldPosition;
    float3 normal;
} CustomVertexData;

vertex CustomVertexData gridVertex( Vertex in [[stage_in]],
                                   ushort amp_id [[amplification_id]],
                                   constant GridUniforms &uniforms [[buffer( VertexBufferMaterialUniforms )]],
                                   constant VertexUniforms *vertexUniforms [[buffer( VertexBufferVertexUniforms )]] )
{
    CustomVertexData out;
    const float4 position = float4( in.position, 1.0 );
#if INSTANCING
    const float4 worldPosition = instanceUniforms[instanceID].modelMatrix * position;
#else
    const float4 worldPosition = vertexUniforms[amp_id].modelMatrix * position;
#endif
    out.position = vertexUniforms[amp_id].viewProjectionMatrix * worldPosition;
    out.worldPosition = worldPosition;
    out.normal = abs( in.normal );
    return out;
}

fragment float4 gridFragment( CustomVertexData in [[stage_in]] )
{
    float3 uv = in.worldPosition.xyz;
    repeat( uv, 10.0 );

    const float lw = 0.01;
    float sdfX = Plane( uv, float3( 1, 0, 0 ), 0 ) - lw;
    float sdfY = Plane( uv, float3( 0, 1, 0 ), 0 ) - lw;
    float sdfZ = Plane( uv, float3( 0, 0, 1 ), 0 ) - lw;

    float sdfXY = unionHard( sdfX, sdfY ) * dot( in.normal, float3( 0, 0, 1 ) );
    sdfXY = 1.0 - saturate( sdfXY / fwidth( sdfXY ) );

    float sdfYZ = unionHard( sdfY, sdfZ ) * dot( in.normal, float3( 1, 0, 0 ) );
    sdfYZ = 1.0 - saturate( sdfYZ / fwidth( sdfYZ ) );

    float sdfXZ = unionHard( sdfX, sdfZ ) * dot( in.normal, float3( 0, 1, 0 ) );
    sdfXZ = 1.0 - saturate( sdfXZ / fwidth( sdfXZ ) );

    return float4( min( min( sdfXY, sdfYZ ), sdfXZ ) );
}
