//
//  ShaderPipelineCache.swift
//
//
//  Created by Reza Ali on 6/14/23.
//

import Foundation
import Metal

public final actor ShaderPipelineCache {
    static var pipelineCache: [ShaderConfiguration: MTLRenderPipelineState] = [:]
    static var shadowPipelineCache: [ShaderConfiguration: MTLRenderPipelineState] = [:]
    static var pipelineReflectionCache: [ShaderConfiguration: MTLRenderPipelineReflection] = [:]
    static var pipelineParametersCache: [ShaderConfiguration: ParameterGroup] = [:]

    private static let pipelineCacheQueue = DispatchQueue(label: "ShaderPipelineCacheQueue", attributes: .concurrent)
    private static let shadowPipelineCacheQueue = DispatchQueue(label: "ShaderShadowPipelineCacheQueue", attributes: .concurrent)
    
    private static let pipelineReflectionCacheQueue = DispatchQueue(label: "ShaderPipelineReflectionCacheQueue", attributes: .concurrent)
    private static let pipelineParametersCacheQueue = DispatchQueue(label: "ShaderPipelineParametersCacheQueue", attributes: .concurrent)

    public static func invalidate(configuration: ShaderConfiguration) {
        pipelineCacheQueue.sync(flags: .barrier) {
            invalidatePipeline(configuration: configuration)
        }

        shadowPipelineCacheQueue.sync(flags: .barrier) {
            invalidateShadowPipeline(configuration: configuration)
        }

        pipelineReflectionCacheQueue.sync(flags: .barrier) {
            invalidatePipelineReflection(configuration: configuration)
        }

        pipelineParametersCacheQueue.sync(flags: .barrier) {
            invalidatePipelineParameters(configuration: configuration)
        }
    }

    public static func invalidatePipeline(configuration: ShaderConfiguration) {
        _ = pipelineCacheQueue.sync(flags: .barrier) {
            pipelineCache.removeValue(forKey: configuration)
        }
    }

    public static func invalidateShadowPipeline(configuration: ShaderConfiguration) {
        _ = shadowPipelineCacheQueue.sync(flags: .barrier) {
            shadowPipelineCache.removeValue(forKey: configuration)
        }
    }

    public static func invalidatePipelineReflection(configuration: ShaderConfiguration) {
        _ = pipelineReflectionCacheQueue.sync(flags: .barrier) {
            pipelineReflectionCache.removeValue(forKey: configuration)
        }
    }

    public static func invalidatePipelineParameters(configuration: ShaderConfiguration) {
        _ = pipelineParametersCacheQueue.sync(flags: .barrier) {
            pipelineParametersCache.removeValue(forKey: configuration)
        }
    }

    public static func getPipeline(configuration: ShaderConfiguration) throws -> (pipeline: MTLRenderPipelineState?, reflection: MTLRenderPipelineReflection?) {

        var cachedPipeline: MTLRenderPipelineState?
        var cachedReflection: MTLRenderPipelineReflection?

        pipelineCacheQueue.sync {
            cachedPipeline = pipelineCache[configuration]
        }

        pipelineReflectionCacheQueue.sync {
            cachedReflection = pipelineReflectionCache[configuration]
        }

        if let cachedPipeline, let cachedReflection {
            return (cachedPipeline, cachedReflection)
        }

//        print("Creating Shader Pipeline: \(configuration)")

        guard let context = configuration.context,
              let library = try ShaderLibraryCache.getLibrary(configuration: configuration.getLibraryConfiguration(), device: context.device)
        else { return (nil, nil) }

        guard let vertexFunction = library.makeFunction(name: configuration.vertexFunctionName),
              let fragmentFunction = library.makeFunction(name: configuration.fragmentFunctionName)
        else { return (nil, nil) }

        var descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = configuration.label

        descriptor.vertexDescriptor = configuration.rendering.vertexDescriptor
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction

        setupRenderPipelineDescriptorContext(context: context, descriptor: &descriptor)
        setupRenderPipelineDescriptorBlending(blending: configuration.rendering.blending, descriptor: &descriptor)

        var pipelineReflection: MTLRenderPipelineReflection?
        let pipeline = try context.device.makeRenderPipelineState(descriptor: descriptor, options: [.argumentInfo, .bufferTypeInfo], reflection: &pipelineReflection)

        pipelineCacheQueue.sync(flags: .barrier) {
            pipelineCache[configuration] = pipeline
        }

        pipelineReflectionCacheQueue.sync(flags: .barrier) {
            pipelineReflectionCache[configuration] = pipelineReflection
        }

        return (pipeline, pipelineReflection)
    }

    public static func getShadowPipeline(configuration: ShaderConfiguration) throws -> MTLRenderPipelineState? {

        var cachedShadowPipeline: MTLRenderPipelineState?

        pipelineCacheQueue.sync {
            cachedShadowPipeline = shadowPipelineCache[configuration]
        }

        if let cachedShadowPipeline {
            return cachedShadowPipeline
        }

        guard let context = configuration.context,
              let library = try ShaderLibraryCache.getLibrary(configuration: configuration.getLibraryConfiguration(), device: context.device)
        else { return nil }

        guard let vertexFunction = library.makeFunction(name: configuration.shadowFunctionName) ?? library.makeFunction(name: configuration.vertexFunctionName) else { return nil }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = configuration.label + " Shadow"

        descriptor.vertexDescriptor = configuration.rendering.vertexDescriptor
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = nil

        descriptor.rasterSampleCount = 1
        descriptor.depthAttachmentPixelFormat = context.depthPixelFormat

        let pipeline = try context.device.makeRenderPipelineState(descriptor: descriptor)

        shadowPipelineCacheQueue.sync(flags: .barrier) {
            shadowPipelineCache[configuration] = pipeline
        }

        return pipeline
    }

    public static func getPipelineReflection(configuration: ShaderConfiguration) -> MTLRenderPipelineReflection? {
        var cachedReflection: MTLRenderPipelineReflection?

        pipelineReflectionCacheQueue.sync {
            cachedReflection = pipelineReflectionCache[configuration]
        }

        return cachedReflection
    }

    public static func getPipelineParameters(configuration: ShaderConfiguration) throws -> ParameterGroup? {
        if let parameters = pipelineParametersCache[configuration] { return parameters }

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
        else if let reflection = pipelineReflectionCache[configuration] {
            for binding in reflection.fragmentBindings {
                if binding.index == FragmentBufferIndex.MaterialUniforms.rawValue,
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
}
