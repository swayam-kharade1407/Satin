typedef struct {
    float4 position [[position]];
    // inject shadow coords
    float3 normal;
    float2 texcoord [[shared]];
} VertexData;
