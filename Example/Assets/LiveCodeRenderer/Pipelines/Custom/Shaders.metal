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

    const float time = 0.5 * uniforms.time;
    float n = snoise( float3( uv, time ) );

    const float radius = 0.5 + 0.125 * n;

    float result = Circle( uv, radius );
    float sdf = result;
    result /= fwidth( result );
    result = 1.0 - saturate( result );
    float cosTheta;
    float sinTheta = sincos( time, cosTheta );

    float rimLight = saturate( gaussian( sdf, 0.4, 0.4 ) * step( sdf, 0.1 ) );
    float3 color = mix( ( iridescence( 2.0 * uv.y * sinTheta * sdf + 2.0 * uv.x * cosTheta * sdf + n * sdf + time ) ), 1.0, rimLight );
    return float4( color, result );
}
