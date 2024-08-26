#include "Library/Colors.metal"
#include "Library/Gaussian.metal"
#include "Library/Gamma.metal"
#include "Library/Shapes/Circle.metal"
#include "Library/Noise3D.metal"

typedef struct {
    float time;
    float3 appResolution;
} CustomUniforms;

fragment float4 customFragment( VertexData in [[stage_in]],
                               constant CustomUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]] )
{
    float2 uv = 2.0 * in.texcoord - 1.0;
    uv.x *= uniforms.appResolution.z;
    float2 norm = normalize( uv );

    const float n = snoise( float3( uv, uniforms.time ) );
    const float radius = 0.5 + 0.175 * n;
    float result = Circle( uv, radius );
    float sdf = result;
    result /= fwidth( result );
    result = 1.0 - saturate( result );
    float rimLight = saturate( gaussian( sdf, 0.4, 0.4 ) * step( sdf, 0.1 ) );
    float3 color = mix( ( iridescence( uv.y + uv.x + n * sdf ) ), 1.0, rimLight );
    return float4( color, result );
}
