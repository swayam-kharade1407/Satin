typedef struct {
    int2 size;
} JumpFloodUniforms;


kernel void jumpFloodUpdate
(
    uint2 gid [[thread_position_in_grid]],
    texture2d<half, access::read> inTex [[texture( 0 )]],
    texture2d<half, access::write> outTex [[texture( 1 )]],
    texture2d<half, access::read> renderTex [[texture( 2 )]],
    constant int &spacing [[buffer( ComputeBufferCustom0 )]],
    constant JumpFloodUniforms &uniforms [[buffer( ComputeBufferUniforms )]]
)
{
    const half4 render = renderTex.read( gid );
    const int2 size = uniforms.size;

    int2 id = int2( gid );
    half2 center = half2( gid );
    half minDistance = 65504.0h;

    int2 xy;
    half4 jfSample;
    half2 delta;
    half dist;

    half4 sample = inTex.read( gid );

    if( render.a < 0.01h ) {
        for( int y = -1; y <= 1; y++ ) {
            for( int x = -1; x <= 1; x++ ) {
                xy = id + int2( x, y ) * spacing;

                if(xy.x >= 0 && xy.x < size.x && xy.y >= 0 && xy.y < size.y) {
                    jfSample = inTex.read( uint2( xy ) );
                    if( jfSample.x > -1.0h ) {
                        delta = center - jfSample.xy;
                        dist = abs( dot( delta, delta ) );
                        if( dist <= minDistance ) {
                            minDistance = dist;
                            sample = jfSample;
                        }
                    }
                }
            }
        }
    }

    return outTex.write( sample, gid );
}
