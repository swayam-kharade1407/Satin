#include "Library/Gaussian.metal"
#include "Library/Map.metal"

typedef struct {
    float diffusionA; // slider,0.0,1.0,1.0
    float diffusionB; // slider,0.0,1.0,0.573
    float feed; // slider,0.01,0.1,0.028
    float kill; // slider,0.045,0.07,0.057
    float deltaTime; //slider,0,1,1
    int2 size;
} ReactionDiffusionUniforms;

kernel void reactionDiffusionReset( uint2 gid [[thread_position_in_grid]],
                                   texture2d<float, access::read> inTex [[texture( ComputeTextureCustom0 )]],
                                   texture2d<float, access::write> outTex [[texture( ComputeTextureCustom1 )]],
                                   constant ReactionDiffusionUniforms &uniforms [[buffer( ComputeBufferUniforms )]] )
{
    const uint2 size = uint2( uniforms.size );

    if( gid.x < size.x && gid.y < size.y ) {
        float2 uv = float2( gid ) / float2( size - 1 );

        uv = 2.0 * uv - 1.0;

        const float src = saturate( gaussian( length( uv ), 0.35, 0.25 ) );

        outTex.write( float4( 1.0, src, 0.0, 1.0 ), gid );
    }
}

// constant float3x3 weights = float3x3(
//     0.05, 0.2, 0.05, 0.2, -1.0, 0.2, 0.05, 0.2, 0.05 );
constant float3x3 weights = float3x3(0.05, 0.2, 0.05, 0.2, -1.0, 0.2, 0.05, 0.2, 0.05);

kernel void reactionDiffusionUpdate( uint2 gid [[thread_position_in_grid]],
                        texture2d<float, access::read> inTex [[texture( ComputeTextureCustom0 )]],
                        texture2d<float, access::write> outTex [[texture( ComputeTextureCustom1 )]],
                        constant ReactionDiffusionUniforms &uniforms [[buffer( ComputeBufferUniforms )]] )
{
    const uint2 size = uint2( uniforms.size );
    if( gid.x < size.x && gid.y < size.y ) {
        const float2 diffusion = float2( uniforms.diffusionA, uniforms.diffusionB );
        const float feed = uniforms.feed;
        const float kill = uniforms.kill;
        const float dt = uniforms.deltaTime;

        // const float input = gaussian( length( 2.0 * uv - 1.0 ), 0.35, 0.25 );
        // outTex.write( float4( input, input, input, 1.0 ), gid );

        const int x = gid.x;
        const int y = gid.y;

        const int right = ( x + 1 ) % size.x;
        const int left = ( x - 1 ) < 0 ? ( size.x - 1 ) : ( x - 1 );

        const int top = ( y + 1 ) % size.y;
        const int bottom = ( y - 1 ) < 0 ? ( size.y - 1 ) : ( y - 1 );

        const float2 valueCenter = inTex.read( gid ).rg;

        const float2 valueTop = inTex.read( uint2( x, top ) ).rg;
        const float2 valueLeft = inTex.read( uint2( left, y ) ).rg;
        const float2 valueRight = inTex.read( uint2( right, y ) ).rg;
        const float2 valueBottom = inTex.read( uint2( x, bottom ) ).rg;

        const float2 valueLeftTop = inTex.read( uint2( left, top ) ).rg;
        const float2 valueRightTop = inTex.read( uint2( right, top ) ).rg;
        const float2 valueLeftBottom = inTex.read( uint2( left, bottom ) ).rg;
        const float2 valueRightBottom = inTex.read( uint2( right, bottom ) ).rg;

        const float2 laplacian = -1.0 * valueCenter + 0.2 * valueTop + 0.2 * valueLeft + 0.2 * valueRight + 0.2 * valueBottom + 0.05 * valueLeftTop + 0.05 * valueRightTop + 0.05 * valueLeftBottom + 0.05 * valueRightBottom;

        float a = valueCenter.r;
        float b = valueCenter.g;
        const float abb = a * b * b;

        // // Diffusion
        // a += laplacian.r * a * dt;
        // b += laplacian.g * b * dt;

        // Reaction Diffusion
        a += ( diffusion.r * laplacian.r - abb + feed * ( 1.0 - a ) ) * dt;
        b += ( diffusion.g * laplacian.g + abb - ( feed + kill ) * b ) * dt;

        // a = clamp( a, 0.0, 1.0 );
        // b = clamp( b, 0.0, 1.0 );

        outTex.write( float4( a, b, 0.0, 1.0 ), gid );
    }
}
