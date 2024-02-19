//
//  ComputeShaderPipelineCache.swift
//
//
//  Created by Reza Ali on 1/8/24.
//

import Foundation
import Metal

public actor ComputeShaderPipelineCache {
    static var resetPipelineCache: [ComputeShaderConfiguration: MTLComputePipelineState] = [:]
    static var resetPipelineReflectionCache: [ComputeShaderConfiguration: MTLComputePipelineReflection] = [:]

    static var updatePipelineCache: [ComputeShaderConfiguration: MTLComputePipelineState] = [:]
    static var updatePipelineReflectionCache: [ComputeShaderConfiguration: MTLComputePipelineReflection] = [:]

    static var pipelineParametersCache: [ComputeShaderConfiguration: ParameterGroup] = [:]
    static var pipelineBuffersCache: [ComputeShaderConfiguration: [ParameterGroup]] = [:]

    public static func invalidate(configuration: ComputeShaderConfiguration) {
        invalidateResetPipeline(configuration: configuration)
        invalidateResetPipelineReflection(configuration: configuration)

        invalidateUpdatePipeline(configuration: configuration)
        invalidateUpdatePipelineReflection(configuration: configuration)

        invalidatePipelineParameters(configuration: configuration)
        invalidatePipelineBuffers(configuration: configuration)
    }

    public static func invalidateResetPipeline(configuration: ComputeShaderConfiguration) {
        resetPipelineCache.removeValue(forKey: configuration)
    }

    public static func invalidateResetPipelineReflection(configuration: ComputeShaderConfiguration) {
        resetPipelineReflectionCache.removeValue(forKey: configuration)
    }

    public static func invalidateUpdatePipeline(configuration: ComputeShaderConfiguration) {
        updatePipelineCache.removeValue(forKey: configuration)
    }

    public static func invalidateUpdatePipelineReflection(configuration: ComputeShaderConfiguration) {
        updatePipelineReflectionCache.removeValue(forKey: configuration)
    }

    public static func invalidatePipelineParameters(configuration: ComputeShaderConfiguration) {
        pipelineParametersCache.removeValue(forKey: configuration)
    }

    public static func invalidatePipelineBuffers(configuration: ComputeShaderConfiguration) {
        pipelineBuffersCache.removeValue(forKey: configuration)
    }

    public static func getResetPipeline(configuration: ComputeShaderConfiguration) throws -> MTLComputePipelineState? {
        if let pipeline = resetPipelineCache[configuration] { return pipeline }
        else {
            return try getPipeline(
                functionName: configuration.resetFunctionName,
                configuration: configuration,
                pipelineCache: &resetPipelineCache,
                pipelineReflectionCache: &resetPipelineReflectionCache
            )
        }
    }

    public static func getUpdatePipeline(configuration: ComputeShaderConfiguration) throws -> MTLComputePipelineState? {
        if let pipeline = updatePipelineCache[configuration] { return pipeline }
        else {
            return try getPipeline(
                functionName: configuration.updateFunctionName,
                configuration: configuration,
                pipelineCache: &updatePipelineCache,
                pipelineReflectionCache: &updatePipelineReflectionCache
            )
        }
    }

    public static func getResetPipelineReflection(configuration: ComputeShaderConfiguration) -> MTLComputePipelineReflection? {
        resetPipelineReflectionCache[configuration]
    }

    public static func getUpdatePipelineReflection(configuration: ComputeShaderConfiguration) -> MTLComputePipelineReflection? {
        updatePipelineReflectionCache[configuration]
    }

    public static func getPipelineParameters(configuration: ComputeShaderConfiguration) throws -> ParameterGroup? {
        if let parameters = pipelineParametersCache[configuration] { return parameters }

        if let reflection = updatePipelineReflectionCache[configuration] {
            let args = reflection.arguments[ComputeBufferIndex.Uniforms.rawValue]
            if let bufferStruct = args.bufferStructType {
                let parameters = parseParameters(bufferStruct: bufferStruct)
                parameters.label = configuration.label.titleCase + " Uniforms"
                pipelineParametersCache[configuration] = parameters
                return parameters
            }
        }
        else if let pipelineURL = configuration.pipelineURL,
                let shaderSource = try ShaderSourceCache.getSource(url: pipelineURL),
                let parameters = parseParameters(source: shaderSource, key: configuration.label + "Uniforms")
        {
            parameters.label = configuration.label.titleCase + " Uniforms"
            pipelineParametersCache[configuration] = parameters
            return parameters
        }

        return nil
    }

    public static func getPipelineBuffers(configuration: ComputeShaderConfiguration) throws -> [ParameterGroup]? {
        if let parameters = pipelineBuffersCache[configuration] { return parameters }

        if let reflection = updatePipelineReflectionCache[configuration] {
            var parameters = [ParameterGroup]()
            for arg in reflection.arguments {
                if arg.index != ComputeBufferIndex.Uniforms.rawValue,
                   let bufferStruct = arg.bufferStructType
                {
                    let p = parseParameters(bufferStruct: bufferStruct)
                    p.label = "\(arg.name)"
                    parameters.append(p)
                }
            }
            pipelineBuffersCache[configuration] = parameters
            return parameters
        }
        else if let pipelineURL = configuration.pipelineURL,
                let shaderSource = try ShaderSourceCache.getSource(url: pipelineURL),
                let buffer = parseStruct(source: shaderSource, key: configuration.label.titleCase)
        {
            buffer.label = configuration.label.titleCase
            pipelineBuffersCache[configuration] = [buffer]
            return [buffer]
        }

        return nil
    }

    private static func getPipeline(
        functionName: String,
        configuration: ComputeShaderConfiguration,
        pipelineCache: inout [ComputeShaderConfiguration: MTLComputePipelineState],
        pipelineReflectionCache: inout [ComputeShaderConfiguration: MTLComputePipelineReflection]
    ) throws -> MTLComputePipelineState? {
        if let pipeline = pipelineCache[configuration] { return pipeline }

//        print("Creating Compute Shader Pipeline: \(configuration.label): \(functionName)")

        guard let device = configuration.device,
              let library = try ComputeShaderLibraryCache.getLibrary(
                  configuration: configuration.getLibraryConfiguration(),
                  device: device
              )
        else { return nil }

        guard let computeFunction = library.makeFunction(name: functionName) else { return nil }

        let descriptor = MTLComputePipelineDescriptor()
        descriptor.label = "\(configuration.label) \(functionName)"
        descriptor.computeFunction = computeFunction
        descriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = configuration.compute.threadGroupSizeIsMultipleOfThreadExecutionWidth

        if configuration.libraryURL != nil {
            var pipelineReflection: MTLComputePipelineReflection?
            let pipeline = try device.makeComputePipelineState(descriptor: descriptor, options: [.argumentInfo, .bufferTypeInfo], reflection: &pipelineReflection)
            pipelineCache[configuration] = pipeline
            pipelineReflectionCache[configuration] = pipelineReflection
            return pipeline
        }
        else {
            let (pipeline, reflection) = try device.makeComputePipelineState(descriptor: descriptor, options: [])
            pipelineCache[configuration] = pipeline
            pipelineReflectionCache[configuration] = reflection
            return pipeline
        }
    }
}
