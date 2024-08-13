#include "Library/Gaussian.metal"
#include "Library/Random.metal"
#include "Library/Map.metal"

typedef struct {
    float speed; // slider,0,4,2
    float decay; // slider,0,1,0.999
    float deltaTime; // slider,0,1,1.0
    float time;
    int2 size;
} WaveUniforms;

kernel void waveReset( uint2 gid [[thread_position_in_grid]],
                      texture2d<float, access::read> inTex [[texture( ComputeTextureCustom0 )]],
                      texture2d<float, access::write> outTex [[texture( ComputeTextureCustom1 )]],
                      constant WaveUniforms &uniforms [[buffer( ComputeBufferUniforms )]] )
{
    const uint2 size = uint2( uniforms.size );

    if( gid.x < size.x && gid.y < size.y ) {
        float2 uv = float2( gid ) / float2( size - 1 );
        uv = 2.0 * uv - 1.0;
        const float src = gaussian( length( uv ), 0.125, 0.75 ) * 0.25;
        outTex.write( float4( src, src * 0.9, 0.0, 1.0 ), gid );
        // outTex.write( float4( 0, 0, 0.0, 1.0 ), gid );
    }
}

kernel void waveUpdate( uint2 gid [[thread_position_in_grid]],
                       texture2d<float, access::read> inTex [[texture( ComputeTextureCustom0 )]],
                       texture2d<float, access::write> outTex [[texture( ComputeTextureCustom1 )]],
                       constant WaveUniforms &uniforms [[buffer( ComputeBufferUniforms )]] )
{
    const uint2 size = uint2( uniforms.size );
    if( gid.x >= size.x || gid.y >= size.y ) {
        return;
    }
    const float deltaTime = uniforms.deltaTime;
    const float speed = uniforms.speed;
    const float decay = uniforms.decay;

    const int x = gid.x;
    const int y = gid.y;

    const int right = ( x + 1 ) % size.x;
    const int left = ( x - 1 ) < 0 ? ( size.x - 1 ) : ( x - 1 );

    const int top = ( y + 1 ) % size.y;
    const int bottom = ( y - 1 ) < 0 ? ( size.y - 1 ) : ( y - 1 );

    const float2 value = inTex.read( gid ).rg;

    const float valueCenter = -1.0 * value.r;
    const float valueTop = 0.2 * inTex.read( uint2( x, top ) ).r;
    const float valueLeft = 0.2 * inTex.read( uint2( left, y ) ).r;
    const float valueRight = 0.2 * inTex.read( uint2( right, y ) ).r;
    const float valueBottom = 0.2 * inTex.read( uint2( x, bottom ) ).r;

    const float valueLeftTop = 0.05 * inTex.read( uint2( left, top ) ).r;
    const float valueRightTop = 0.05 * inTex.read( uint2( right, top ) ).r;
    const float valueLeftBottom = 0.05 * inTex.read( uint2( left, bottom ) ).r;
    const float valueRightBottom = 0.05 * inTex.read( uint2( right, bottom ) ).r;

    // const float laplacian = -1.0 * valueCenter.r + 0.2 * valueTop + 0.2 * valueLeft + 0.2 * valueRight + 0.2 * valueBottom;

    const float laplacian = valueCenter + valueTop + valueLeft + valueRight + valueBottom + valueLeftTop + valueRightTop + valueLeftBottom + valueRightBottom;

    const float previousValue = value.g; // previous value
    const float currentValue = value.r; // current value

    float newValue = 2.0 * currentValue - previousValue + speed * laplacian * deltaTime;
    newValue *= decay;
    // float acc = speed * laplacian.r;
    // acc -= damping * b;

    // b += dt * acc;
    // a += dt * b;

    // a *= decay;

    // const float2 uv = float2( gid ) / float2( size - 1 );
    // const float time = uniforms.time;
    // float dist = length( 2.0 * uv - 1.0 - 0.75 * float2( sin( time ), cos( time ) ) );

    // if( dist < 0.05 ) {
    //     const float src = gaussian( dist, 0.35, 0.25 ) * dist;
    //     newValue += 0.2 * src * sin( time * 2.0 );
    // }

     if( gid.x == 0 || ( gid.x + 1 ) == size.x || gid.y == 0 || ( gid.y + 1 ) == size.y ) {
         newValue = 0;
     }

    outTex.write( float4( newValue, currentValue, 0.0, 1.0 ), gid );
}
