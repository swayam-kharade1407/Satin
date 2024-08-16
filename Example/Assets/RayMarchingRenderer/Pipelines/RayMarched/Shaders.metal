// See https://www.iquilezles.org/www/articles/raypolys/raypolys.htm

#include "../Library/Shapes.metal"
#include "../Library/Csg.metal"

#define MAX_STEPS 64
#define MIN_DIST 0.0
#define MAX_DIST 400.0
#define SURF_DIST 0.0001
#define EPSILON 0.001

typedef struct {
    float4 color; // color
} RayMarchedUniforms;

typedef struct {
    float4 position [[position]];
    float4 far;
    float3 cameraPosition [[flat]];
} RayMarchedData;

struct FragOut {
    float4 color [[color( 0 )]];
    float depth [[depth( any )]];
};

float scene( float3 p )
{
    const float lw = 0.1;
    float line = Line( abs( p ), 1.0, float3( 1.0, 1.0, -1.0 ) ) - lw;
    line = unionHard( line, Line( abs( p ), 1.0, float3( 1.0, -1.0, 1.0 ) ) - lw );
    line = unionHard( line, Line( abs( p ), 1.0, float3( -1.0, 1.0, 1.0 ) ) - lw );
    return line;
    // return Box( p, float3( 1.0, 1.0, 1.0 ) );
}

float3 getNormal( float3 p )
{
    const float d = scene( p );
    const float3 e = float3( EPSILON, 0.0, 0.0 );
    const float3 gradient = d - float3( scene( p - e.xyy ), scene( p - e.yxy ), scene( p - e.yyx ) );
    return normalize( gradient );
}

float render( float3 ro, float3 rd )
{
    float d = 0.0;
    for( int i = 0; i < MAX_STEPS; i++ ) {
        const float3 p = ro + rd * d;
        const float dist = scene( p );
        d += dist;
        if( dist > MAX_DIST || abs( dist ) < SURF_DIST ) {
            break;
        }
    }
    return d;
}

vertex RayMarchedData rayMarchedVertex(
                                       Vertex in [[stage_in]],
                                       ushort amp_id [[amplification_id]],
                                       constant VertexUniforms *vertexUniforms [[buffer( VertexBufferVertexUniforms )]] )
{
    const float4x4 inverseModelViewProjectionMatrix = vertexUniforms[amp_id].inverseModelViewProjectionMatrix;

    RayMarchedData out;
    out.position = float4( in.position, 1.0 );
    out.far = inverseModelViewProjectionMatrix * float4( out.position.xy, 0.5, 1.0 );
    out.cameraPosition = vertexUniforms[amp_id].worldCameraPosition;
    return out;
}

fragment FragOut rayMarchedFragment(
                                    RayMarchedData in [[stage_in]],
                                    ushort amp_id [[amplification_id]],
                                    constant RayMarchedUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
                                    constant VertexUniforms *vertexUniforms [[buffer( FragmentBufferVertexUniforms )]] )
{
    const float3 ro = in.cameraPosition;
    const float3 rd = normalize( in.far.xyz / in.far.w - ro );

    // float2 uv = 2.0 * in.texcoord - 1.0;
    // uv.y *= -1.0;
    // const float3 rd = normalize( uniforms.cameraRight * uv.x + uniforms.cameraUp * uv.y + uniforms.cameraForward );

    const float d = render( ro, rd );

    if( d >= MAX_DIST ) {
        discard_fragment();
    }

    const float3 p = ro + rd * d;
    const float3 normal = getNormal( p );

    FragOut out;

    const float4 ep = vertexUniforms[amp_id].viewProjectionMatrix * float4( p, 1.0 );
    out.depth = ep.z / ep.w;

    if( out.depth >= 1 || out.depth <= 0 ) {
        discard_fragment();
    }

    out.color = float4( normal, 1.0 );
    return out;
}
