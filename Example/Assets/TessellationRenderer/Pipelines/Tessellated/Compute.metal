// Inspired by Warren Moore: https://metalbyexample.com/tessellation/

typedef struct {
    float edgeTessellationFactor; //slider,0,16,4
    float insideTessellationFactor; //slider,0,16,4
} TessellationUniforms;

kernel void tessellationQuadUpdate
(
    device MTLQuadTessellationFactorsHalf *patchFactorsArray [[buffer(ComputeBufferTessellationFactors)]],
    constant TessellationUniforms &uniforms [[buffer(ComputeBufferUniforms)]],
    uint patchIndex [[thread_position_in_grid]]
)
{
    device MTLQuadTessellationFactorsHalf &patchFactors = patchFactorsArray[patchIndex];
    patchFactors.edgeTessellationFactor[0] = uniforms.edgeTessellationFactor;
    patchFactors.edgeTessellationFactor[1] = uniforms.edgeTessellationFactor;
    patchFactors.edgeTessellationFactor[2] = uniforms.edgeTessellationFactor;
    patchFactors.edgeTessellationFactor[3] = uniforms.edgeTessellationFactor;
    patchFactors.insideTessellationFactor[0] = uniforms.insideTessellationFactor;
    patchFactors.insideTessellationFactor[1] = uniforms.insideTessellationFactor;
}

kernel void tessellatedUpdate
(
    device MTLTriangleTessellationFactorsHalf *patchFactorsArray [[buffer(ComputeBufferTessellationFactors)]],
    constant TessellationUniforms &uniforms [[buffer(ComputeBufferUniforms)]],
    uint patchIndex [[thread_position_in_grid]]
)
{
    device MTLTriangleTessellationFactorsHalf &patchFactors = patchFactorsArray[patchIndex];
#if MOBILE
    patchFactors.edgeTessellationFactor[0] = uniforms.edgeTessellationFactor / 2;
    patchFactors.edgeTessellationFactor[1] = uniforms.edgeTessellationFactor / 2;
    patchFactors.edgeTessellationFactor[2] = uniforms.edgeTessellationFactor / 2;
    patchFactors.insideTessellationFactor = uniforms.insideTessellationFactor / 2;
#else
    patchFactors.edgeTessellationFactor[0] = uniforms.edgeTessellationFactor;
    patchFactors.edgeTessellationFactor[1] = uniforms.edgeTessellationFactor;
    patchFactors.edgeTessellationFactor[2] = uniforms.edgeTessellationFactor;
    patchFactors.insideTessellationFactor = uniforms.insideTessellationFactor;

#endif
}
