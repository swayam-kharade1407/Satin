// https://www.shadertoy.com/view/ttcyRS
float3 oklab_mix( float3 colA, float3 colB, float h )
{
    // https://bottosson.github.io/posts/oklab
    const float3x3 kCONEtoLMS = float3x3(
        0.4121656120,
        0.2118591070,
        0.0883097947,
        0.5362752080,
        0.6807189584,
        0.2818474174,
        0.0514575653,
        0.1074065790,
        0.6302613616 );
    const float3x3 kLMStoCONE = float3x3(
        4.0767245293,
        -1.2681437731,
        -0.0041119885,
        -3.3072168827,
        2.6093323231,
        -0.7034763098,
        0.2307590544,
        -0.3411344290,
        1.7068625689 );

    // rgb to cone (arg of pow can't be negative)
    float3 lmsA = pow( kCONEtoLMS * colA, float3( 1.0 / 3.0 ) );
    float3 lmsB = pow( kCONEtoLMS * colB, float3( 1.0 / 3.0 ) );
    // lerp
    float3 lms = mix( lmsA, lmsB, h );
    // gain in the middle (no oaklab anymore, but looks better?)
    // lms *= 1.0 + 0.2 * h * ( 1.0 - h );
    // cone to rgb
    return kLMStoCONE * ( lms * lms * lms );
}

float3 oklab_brighter_mix( float3 colA, float3 colB, float h )
{
    // https://bottosson.github.io/posts/oklab
    const float3x3 kCONEtoLMS = float3x3(
        0.4121656120,
        0.2118591070,
        0.0883097947,
        0.5362752080,
        0.6807189584,
        0.2818474174,
        0.0514575653,
        0.1074065790,
        0.6302613616 );
    const float3x3 kLMStoCONE = float3x3(
        4.0767245293,
        -1.2681437731,
        -0.0041119885,
        -3.3072168827,
        2.6093323231,
        -0.7034763098,
        0.2307590544,
        -0.3411344290,
        1.7068625689 );

    // rgb to cone (arg of pow can't be negative)
    float3 lmsA = pow( kCONEtoLMS * colA, float3( 1.0 / 3.0 ) );
    float3 lmsB = pow( kCONEtoLMS * colB, float3( 1.0 / 3.0 ) );
    // lerp
    float3 lms = mix( lmsA, lmsB, h );
    // gain in the middle (no oaklab anymore, but looks better?)
    lms *= 1.0 + 0.2 * h * ( 1.0 - h );
    // cone to rgb
    return kLMStoCONE * ( lms * lms * lms );
}

// From SatinPro (hi-rez.io)

float3 oklab_mix2( float3 a, float3 b, float t )
{
    t = abs( t );
    int cell = floor( t );
    t = t - cell;
    t = mix( t, 1.0 - t, cell % 2 );

    return oklab_mix( a, b, t );
}

float3 oklab_brighter_mix2( float3 a, float3 b, float t )
{
    t = abs( t );
    int cell = floor( t );
    t = t - cell;
    t = mix( t, 1.0 - t, cell % 2 );

    return oklab_brighter_mix( a, b, t );
}

float3 oklab_mix3( float3 a, float3 b, float3 c, float t )
{
    t = abs( t );
    int cell = floor( t );
    t = t - cell;
    t = mix( t, 1.0 - t, cell % 2 );

    float3 ab = oklab_mix( a, b, saturate( t * 2 ) );
    float3 bc = oklab_mix( b, c, saturate( t * 2 - 1.0 ) );
    return t > 0.5 ? bc : ab;
}

float3 oklab_brighter_mix3( float3 a, float3 b, float3 c, float t )
{
    t = abs( t );
    int cell = floor( t );
    t = t - cell;
    t = mix( t, 1.0 - t, cell % 2 );

    float3 ab = oklab_brighter_mix( a, b, saturate( t * 2 ) );
    float3 bc = oklab_brighter_mix( b, c, saturate( t * 2 - 1.0 ) );
    return t > 0.5 ? bc : ab;
}

float3 oklab_mix4( float3 a, float3 b, float3 c, float3 d, float t )
{
    t = abs( t );
    int cell = floor( t );
    t = t - cell;
    t = mix( t, 1.0 - t, cell % 2 );

    float3 ab = oklab_mix( a, b, saturate( t * 3 ) );
    float3 bc = oklab_mix( b, c, saturate( t * 3 - 1.0 ) );
    float3 cd = oklab_mix( c, d, saturate( t * 3 - 2.0 ) );

    float3 abbc = t > 0.333333 ? bc : ab;
    float3 bccd = t > 0.666666 ? cd : bc;

    return t > 0.5 ? bccd : abbc;
}

float3 oklab_brighter_mix4( float3 a, float3 b, float3 c, float3 d, float t )
{
    t = abs( t );
    int cell = floor( t );
    t = t - cell;
    t = mix( t, 1.0 - t, cell % 2 );

    float3 ab = oklab_brighter_mix( a, b, saturate( t * 3 ) );
    float3 bc = oklab_brighter_mix( b, c, saturate( t * 3 - 1.0 ) );
    float3 cd = oklab_brighter_mix( c, d, saturate( t * 3 - 2.0 ) );

    float3 abbc = t > 0.333333 ? bc : ab;
    float3 bccd = t > 0.666666 ? cd : bc;

    return t > 0.5 ? bccd : abbc;
}

float3 oklab_mix5( float3 c0, float3 c1, float3 c2, float3 c3, float3 c4, float t )
{
    t = abs( t );
    int cell = floor( t );
    t = t - cell;
    t = mix( t, 1.0 - t, cell % 2 );

    const float3 c01 = oklab_mix( c0, c1, saturate( t * 4 ) );
    const float3 c12 = oklab_mix( c1, c2, saturate( t * 4 - 1 ) );
    const float3 c23 = oklab_mix( c2, c3, saturate( t * 4 - 2 ) );
    const float3 c34 = oklab_mix( c3, c4, saturate( t * 4 - 3 ) );

    const float3 c0112 = t > 0.25 ? c12 : c01;
    const float3 c1223 = t > 0.5 ? c23 : c12;
    const float3 c2334 = t > 0.75 ? c34 : c23;

    const float3 c01121223 = t > 0.5 ? c1223 : c0112;
    const float3 c12232334 = t > 0.5 ? c2334 : c1223;

    return t > 0.5 ? c12232334 : c01121223;
}

float3 oklab_brighter_mix5( float3 c0, float3 c1, float3 c2, float3 c3, float3 c4, float t )
{
    t = abs( t );
    int cell = floor( t );
    t = t - cell;
    t = mix( 1.0 - t, t, cell % 2 );

    const float3 c01 = oklab_brighter_mix( c0, c1, saturate( t * 4 ) );
    const float3 c12 = oklab_brighter_mix( c1, c2, saturate( t * 4 - 1 ) );
    const float3 c23 = oklab_brighter_mix( c2, c3, saturate( t * 4 - 2 ) );
    const float3 c34 = oklab_brighter_mix( c3, c4, saturate( t * 4 - 3 ) );

    const float3 c0112 = t > 0.25 ? c12 : c01;
    const float3 c1223 = t > 0.5 ? c23 : c12;
    const float3 c2334 = t > 0.75 ? c34 : c23;

    const float3 c01121223 = t > 0.5 ? c1223 : c0112;
    const float3 c12232334 = t > 0.5 ? c2334 : c1223;

    return t > 0.5 ? c12232334 : c01121223;
}
