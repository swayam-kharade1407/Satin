import Foundation
import Satin

let arguments = ProcessInfo().arguments

if arguments.count < 3 {
    print("missing args: input, output")
    exit(1)
}

let label = arguments[1]
let inputShaderPath = arguments[2]
let outputShaderPath = arguments[3]
let outputShaderParametersPath = arguments[4]

print("inputShaderPath: \(inputShaderPath)")
print("outputShaderPath: \(outputShaderPath)")

do {
    let inputShaderURL = URL(fileURLWithPath: inputShaderPath)
    let compiledShaderSource = try MetalFileCompiler(watch: false).parse(inputShaderURL)
    let instancing = compiledShaderSource.contains("// inject instancing args")
    let lighting = compiledShaderSource.contains("// inject lighting args")

    if var source = RenderIncludeSource.get() {
        //    injectDefines(source: &source, defines: defines)
        //    injectConstants(source: &source, constants: constants)

        //    injectShadowData(source: &source, receiveShadow: receiveShadow, shadowCount: shadowCount)
        //    injectShadowBuffer(source: &source, receiveShadow: receiveShadow, shadowCount: shadowCount)
        //    injectShadowFunction(source: &source, receiveShadow: receiveShadow, shadowCount: shadowCount)

        injectVertex(source: &source, vertexDescriptor: SatinVertexDescriptor())

        source += compiledShaderSource

        injectPassThroughVertex(label: label, source: &source)

//        if castShadow { injectPassThroughShadowVertex(label: label, source: &source) }

        injectInstancingArgs(source: &source, instancing: instancing)

//        injectShadowCoords(source: &source, receiveShadow: receiveShadow, shadowCount: shadowCount)
//        injectShadowVertexArgs(source: &source, receiveShadow: receiveShadow)
//        injectShadowVertexCalc(source: &source, receiveShadow: receiveShadow, shadowCount: shadowCount)
//
//        injectShadowFragmentArgs(source: &source, receiveShadow: receiveShadow, shadowCount: shadowCount)
//        injectShadowFragmentCalc(source: &source, receiveShadow: receiveShadow, shadowCount: shadowCount)
//
        injectLightingArgs(source: &source, lighting: lighting)

//        // user hook to modify shader if needed
//        modifyShaderSource(source: &source)
//
//        shaderSource = compiledShaderSource

        parseParameters(source: compiledShaderSource, key: label + "Uniforms")?.save(URL(fileURLWithPath: outputShaderParametersPath))
        try source.write(toFile: outputShaderPath, atomically: true, encoding: .utf8)

        exit(0)
    }
}
catch {
    print(error.localizedDescription)
    exit(1)
}
