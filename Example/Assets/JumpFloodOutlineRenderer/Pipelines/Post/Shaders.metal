static constexpr sampler s( mag_filter::linear, min_filter::linear );

fragment half4 postFragment(
	VertexData in [[stage_in]],
	texture2d<half> pass [[texture( FragmentTextureCustom0 )]],
	texture2d<half> jf [[texture( FragmentTextureCustom1 )]] )
{
	const float2 uv = in.texcoord;
	const float2 size = float2( pass.get_width(), pass.get_height() ) - 1.0;
	const half2 pos = half2( uv * size );

	// return half4( pos / half2( size ), 0.0, 1.0 );
	const half4 render = pass.sample( s, uv );
	const half4 sample = jf.sample( s, uv );

	half dist = 1.0h - saturate( length( sample.xy - pos ) / 64.0h );
	// half dist = length( sample.xy - pos );
	// dist = smoothstep( 12.0h, 10.0h, dist );

	// return mix( 1.0h, 0.0h, dist );
	return mix( half4( 1.0h, 0.0h, 0.0h, dist * sample.a ), render, render.a );
}
