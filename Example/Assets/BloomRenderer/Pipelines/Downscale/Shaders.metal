#include "Library/Luminance.metal"

typedef struct {
    int2 size;
    bool first;
} DownscaleUniforms;

constexpr sampler sam = sampler( coord::normalized, address::clamp_to_edge, filter::linear );

float luma( float3 c )
{
    return luminance3( c );
}

kernel void downscaleUpdate( uint2 gid [[thread_position_in_grid]],
                            texture2d<float, access::write> outTex [[texture( ComputeTextureCustom0 )]],
                            texture2d<float, access::sample> renderTex [[texture( ComputeTextureCustom1 )]],
                            constant DownscaleUniforms &uniforms [[buffer( ComputeBufferUniforms )]] )
{
    const uint2 size = uint2( uniforms.size );

    if( gid.x >= size.x || gid.y >= size.y ) {
        return;
    }

    const float2 sizef = float2( size );

    const uint2 renderSize = uint2( size * 2 );
    const float2 renderSizef = float2( renderSize );
    const float2 renderTexelSize = 1.0 / renderSizef;

    const float2 uv = ( float2( gid ) + 0.5 ) / sizef;

    const float dx = renderTexelSize.x;
    const float dy = renderTexelSize.y;
    const float dx2 = 2.0 * dx;
    const float dy2 = 2.0 * dy;

    const float3 a = renderTex.sample( sam, float2( uv.x - dx2, uv.y + dy2 ) ).rgb;
    const float aW = 1.0 / ( 1.0 + luma( a ) );

    const float3 b = renderTex.sample( sam, float2( uv.x, uv.y + dy2 ) ).rgb;
    const float bW = 1.0 / ( 1.0 + luma( b ) );

    const float3 c = renderTex.sample( sam, float2( uv.x + dx2, uv.y + dy2 ) ).rgb;
    const float cW = 1.0 / ( 1.0 + luma( c ) );

    const float3 j = renderTex.sample( sam, float2( uv.x - dx, uv.y + dy ) ).rgb;
    const float jW = 1.0 / ( 1.0 + luma( j ) );

    const float3 k = renderTex.sample( sam, float2( uv.x + dx, uv.y + dy ) ).rgb;
    const float kW = 1.0 / ( 1.0 + luma( k ) );

    const float3 d = renderTex.sample( sam, float2( uv.x - dx2, uv.y ) ).rgb;
    const float dW = 1.0 / ( 1.0 + luma( d ) );

    const float3 e = renderTex.sample( sam, uv ).rgb;
    const float eW = 1.0 / ( 1.0 + luma( e ) );

    const float3 f = renderTex.sample( sam, float2( uv.x + dx2, uv.y ) ).rgb;
    const float fW = 1.0 / ( 1.0 + luma( f ) );

    const float3 l = renderTex.sample( sam, float2( uv.x - dx, uv.y - dy ) ).rgb;
    const float lW = 1.0 / ( 1.0 + luma( l ) );

    const float3 m = renderTex.sample( sam, float2( uv.x + dx, uv.y - dy ) ).rgb;
    const float mW = 1.0 / ( 1.0 + luma( m ) );

    const float3 g = renderTex.sample( sam, float2( uv.x - dx2, uv.y - dy2 ) ).rgb;
    const float gW = 1.0 / ( 1.0 + luma( g ) );

    const float3 h = renderTex.sample( sam, float2( uv.x, uv.y - dy2 ) ).rgb;
    const float hW = 1.0 / ( 1.0 + luma( h ) );

    const float3 i = renderTex.sample( sam, float2( uv.x + dx2, uv.y - dy2 ) ).rgb;
    const float iW = 1.0 / ( 1.0 + luma( i ) );

    // center weight
    const float3 centerWeight = ( jW * j + kW * k + lW * l + mW * m ) * 0.25;

    // top left weight
    const float3 topLeftWeight = ( aW * a + bW * b + dW * d + eW * e ) * 0.25;

    // top right weight
    const float3 topRightWeight = ( bW * b + cW * c + eW * e + fW * f ) * 0.25;

    // bottom left weight
    const float3 bottomLeftWeight = ( dW * d + eW * e + gW * g + hW * h ) * 0.25;

    // bottom right weight
    const float3 bottomRightWeight = ( eW * e + fW * f + hW * h + iW * i ) * 0.25;

    float3 out = 0.0;
    if( uniforms.first ) {
        // out += e * eW * 0.5;
        out += centerWeight * 0.5;
        out += topLeftWeight * 0.125;
        out += topRightWeight * 0.125;
        out += bottomLeftWeight * 0.125;
        out += bottomRightWeight * 0.125;
        // out = pow( luma( out ), 1.0 );
    }
    else {
        out += e * 0.125;
        out += ( a + c + g + i ) * 0.03125;
        out += ( b + d + f + h ) * 0.0625;
        out += ( j + k + l + m ) * 0.125;
    }

    // float3 out = 0.0;

    // out += e * 0.125;d
    // out += ( a + c + g + i ) * 0.03125;
    // out += ( b + d + f + h ) * 0.0625;
    // out += ( j + k + l + m ) * 0.125;

    outTex.write( float4( out, 1.0 ), gid );
}
