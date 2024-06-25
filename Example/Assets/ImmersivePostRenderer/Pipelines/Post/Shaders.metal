constexpr sampler s = sampler( min_filter::linear, mag_filter::linear );

fragment half4 postFragment
(
    VertexData in [[stage_in]],
    ushort amp_id [[amplification_id]],
//    constant rasterization_rate_map_data &data [[buffer(FragmentBufferCustom0)]],
    texture2d_array<half> tex [[texture(FragmentTextureCustom0)]]
)
{
//    constexpr sampler sp(coord::pixel, address::clamp_to_edge, filter::linear);
//
//    rasterization_rate_map_decoder map(data);
//    float2 physCoords = map.map_screen_to_physical_coordinates(in.position.xy);
//
//    return half4(tex.sample(sp, physCoords, amp_id));

    half4 sample = tex.sample(s, in.texcoord, amp_id);
    sample.rgb = 1.0h - sample.rgb;
    return sample;
}
