kernel void jumpFloodInitUpdate(
                                uint2 gid [[thread_position_in_grid]],
                                texture2d<half, access::write> outTex [[texture( 0 )]],
                                texture2d<half, access::read> renderTex [[texture( 1 )]] )
{
    half4 sample = renderTex.read( gid );
    if( sample.a > 0.0h ) {
        outTex.write( half4( gid.x, gid.y, 0.0h, 1.0h ), gid );
    }
    else {
        outTex.write( half4( -1.0h, -1.0h, 0.0h, 1.0h ), gid );
    }
}
