//
//  ComputeShaderPipelineCache.swift
//
//
//  Created by Reza Ali on 1/8/24.
//

import Foundation
import Metal

public final actor ComputeShaderPipelineCache {
    static var resetPipelineCache: [ComputeShaderConfiguration: MTLComputePipelineState] = [:]
    static var resetPipelineReflectionCache: [ComputeShaderConfiguration: MTLComputePipelineReflection] = [:]

    static var updatePipelineCache: [ComputeShaderConfiguration: MTLComputePipelineState] = [:]
    static var updatePipelineReflectionCache: [ComputeShaderConfiguration: MTLComputePipelineReflection] = [:]

    static var pipelineParametersCache: [ComputeShaderConfiguration: ParameterGroup] = [:]
    static var pipelineBuffersCache: [ComputeShaderConfiguration: [ParameterGroup]] = [:]

    private static let resetPipelineCacheQueue = DispatchQueue(label: "ComputeShaderResetPipelineCacheQueue", attributes: .concurrent)
    private static let resetPipelineReflectionCacheQueue = DispatchQueue(label: "ComputeShaderResetReflectionCacheQueue", attributes: .concurrent)

    private static let updatePipelineCacheQueue = DispatchQueue(label: "ComputeShaderUpdatePipelineCacheQueue", attributes: .concurrent)
    private static let updatePipelineReflectionCacheQueue = DispatchQueue(label: "ComputeShaderUpdateReflectionCacheQueue", attributes: .concurrent)

    private static let pipelineParametersCacheQueue = DispatchQueue(label: "ComputeShaderPipelineParametersCacheQueue", attributes: .concurrent)
    private static let pipelineBuffersCacheQueue = DispatchQueue(label: "ComputeShaderPipelineBuffersCacheQueue", attributes: .concurrent)

    public static func invalidate(configuration: ComputeShaderConfiguration) {
        invalidateResetPipeline(configuration: configuration)
        invalidateResetPipelineReflection(configuration: configuration)

        invalidateUpdatePipeline(configuration: configuration)
        invalidateUpdatePipelineReflection(configuration: configuration)

        invalidatePipelineParameters(configuration: configuration)
        invalidatePipelineBuffers(configuration: configuration)
    }

    public static func invalidateResetPipeline(configuration: ComputeShaderConfiguration) {
        _ = resetPipelineCacheQueue.sync(flags: .barrier) {
            resetPipelineCache.removeValue(forKey: configuration)
        }
    }

    public static func invalidateResetPipelineReflection(configuration: ComputeShaderConfiguration) {
        _ = resetPipelineReflectionCacheQueue.sync(flags: .barrier) {
            resetPipelineReflectionCache.removeValue(forKey: configuration)
        }
    }

    public static func invalidateUpdatePipeline(configuration: ComputeShaderConfiguration) {
        _ = updatePipelineCacheQueue.sync(flags: .barrier) {
            updatePipelineCache.removeValue(forKey: configuration)
        }
    }

    public static func invalidateUpdatePipelineReflection(configuration: ComputeShaderConfiguration) {
        _ = updatePipelineReflectionCacheQueue.sync(flags: .barrier) {
            updatePipelineReflectionCache.removeValue(forKey: configuration)
        }
    }

    public static func invalidatePipelineParameters(configuration: ComputeShaderConfiguration) {
        _ = pipelineParametersCacheQueue.sync(flags: .barrier) {
            pipelineParametersCache.removeValue(forKey: configuration)
        }
    }

    public static func invalidatePipelineBuffers(configuration: ComputeShaderConfiguration) {
        _ = pipelineBuffersCacheQueue.sync(flags: .barrier) {
            pipelineBuffersCache.removeValue(forKey: configuration)
        }
    }

    public static func getResetPipeline(configuration: ComputeShaderConfiguration) throws -> MTLComputePipelineState? {
        try getResetPipeline(
            functionName: configuration.resetFunctionName,
            configuration: configuration
        )
    }

    public static func getUpdatePipeline(configuration: ComputeShaderConfiguration) throws -> MTLComputePipelineState? {
        try getUpdatePipeline(
            functionName: configuration.updateFunctionName,
            configuration: configuration
        )
    }

    public static func getResetPipelineReflection(configuration: ComputeShaderConfiguration) -> MTLComputePipelineReflection? {
        var reflection: MTLComputePipelineReflection?

        resetPipelineReflectionCacheQueue.sync {
            reflection = resetPipelineReflectionCache[configuration]
        }

        return reflection
    }

    public static func getUpdatePipelineReflection(configuration: ComputeShaderConfiguration) -> MTLComputePipelineReflection? {
        var reflection: MTLComputePipelineReflection?

        updatePipelineReflectionCacheQueue.sync {
            reflection = updatePipelineReflectionCache[configuration]
        }

        return reflection
    }

    public static func getPipelineParameters(configuration: ComputeShaderConfiguration) throws -> ParameterGroup? {

        var parameters: ParameterGroup?

        pipelineParametersCacheQueue.sync {
            parameters = pipelineParametersCache[configuration]
        }
        
        if let parameters  {
            return parameters
        }

        if let pipelineURL = configuration.pipelineURL,
           let shaderSource = try ShaderSourceCache.getSource(url: pipelineURL),
           let parameters = parseParameters(source: shaderSource, key: configuration.label + "Uniforms")
        {
            parameters.label = configuration.label.titleCase + " Uniforms"

            pipelineParametersCacheQueue.sync(flags: .barrier) {
                pipelineParametersCache[configuration] = parameters
            }

            return parameters
        }
        else if let reflection = updatePipelineReflectionCache[configuration] {
            for binding in reflection.bindings {
                if binding.index == ComputeBufferIndex.Uniforms.rawValue,
                   let bufferBinding = binding as? MTLBufferBinding,
                   let bufferStruct = bufferBinding.bufferStructType
                {
                    let parameters = parseParameters(bufferStruct: bufferStruct)

                    parameters.label = configuration.label.titleCase + " Uniforms"
                    
                    pipelineParametersCacheQueue.sync(flags: .barrier) {
                        pipelineParametersCache[configuration] = parameters
                    }

                    return parameters
                }
            }
        }

        return nil
    }

    public static func getPipelineBuffers(configuration: ComputeShaderConfiguration) throws -> [ParameterGroup]? {

        var parameters: [ParameterGroup]?

        pipelineBuffersCacheQueue.sync {
            parameters = pipelineBuffersCache[configuration]
        }

        if let parameters  {
            return parameters
        }

        if let pipelineURL = configuration.pipelineURL,
           let shaderSource = try ShaderSourceCache.getSource(url: pipelineURL),
           let buffer = parseStruct(source: shaderSource, key: configuration.label)
        {
            buffer.label = configuration.label.titleCase

            pipelineBuffersCacheQueue.sync(flags: .barrier) {
                pipelineBuffersCache[configuration] = [buffer]
            }

            return [buffer]
        }
        else if let reflection = updatePipelineReflectionCache[configuration] {
            var parameters = [ParameterGroup]()

            for binding in reflection.bindings {
                if binding.index != ComputeBufferIndex.Uniforms.rawValue,
                   let bufferBinding = binding as? MTLBufferBinding,
                   let bufferStruct = bufferBinding.bufferStructType
                {
                    let p = parseParameters(bufferStruct: bufferStruct)
                    p.label = "\(binding.name)"
                    parameters.append(p)
                }
            }

            pipelineBuffersCacheQueue.sync(flags: .barrier) {
                pipelineBuffersCache[configuration] = parameters
            }

            return parameters
        }

        return nil
    }

    private static func getUpdatePipeline(
        functionName: String,
        configuration: ComputeShaderConfiguration
    ) throws -> MTLComputePipelineState? {

        var pipeline: MTLComputePipelineState?

        updatePipelineCacheQueue.sync {
            pipeline = updatePipelineCache[configuration]
        }

        if let pipeline {
            return pipeline
        }

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
            let (pipeline, reflection) = try device.makeComputePipelineState(
                descriptor: descriptor,
                options: []
            )

            updatePipelineCacheQueue.sync(flags: .barrier) {
                updatePipelineCache[configuration] = pipeline
            }

            updatePipelineReflectionCacheQueue.sync(flags: .barrier) {
                updatePipelineReflectionCache[configuration] = reflection
            }

            return pipeline
        }
        else {
            let (pipeline, reflection) = try device.makeComputePipelineState(
                descriptor: descriptor,
                options: [.argumentInfo, .bufferTypeInfo]
            )

            updatePipelineCacheQueue.sync(flags: .barrier) {
                updatePipelineCache[configuration] = pipeline
            }

            updatePipelineReflectionCacheQueue.sync(flags: .barrier) {
                updatePipelineReflectionCache[configuration] = reflection
            }

            return pipeline
        }
    }

    private static func getResetPipeline(
        functionName: String,
        configuration: ComputeShaderConfiguration
    ) throws -> MTLComputePipelineState? {

        var pipeline: MTLComputePipelineState?

        resetPipelineCacheQueue.sync {
            pipeline = resetPipelineCache[configuration]
        }

        if let pipeline {
            return pipeline
        }

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
            let (pipeline, reflection) = try device.makeComputePipelineState(
                descriptor: descriptor,
                options: []
            )

            resetPipelineCacheQueue.sync(flags: .barrier) {
                resetPipelineCache[configuration] = pipeline
            }

            resetPipelineReflectionCacheQueue.sync(flags: .barrier) {
                resetPipelineReflectionCache[configuration] = reflection
            }

            return pipeline
        }
        else {
            let (pipeline, reflection) = try device.makeComputePipelineState(
                descriptor: descriptor,
                options: [.argumentInfo, .bufferTypeInfo]
            )

            resetPipelineCacheQueue.sync(flags: .barrier) {
                resetPipelineCache[configuration] = pipeline
            }

            resetPipelineReflectionCacheQueue.sync(flags: .barrier) {
                resetPipelineReflectionCache[configuration] = reflection
            }

            return pipeline
        }
    }
}
