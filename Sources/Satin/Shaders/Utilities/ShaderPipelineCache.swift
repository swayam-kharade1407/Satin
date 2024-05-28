//
//  ShaderPipelineCache.swift
//
//
//  Created by Reza Ali on 6/14/23.
//

import Foundation
import Metal

public actor ShaderPipelineCache {
    static var pipelineCache: [ShaderConfiguration: MTLRenderPipelineState] = [:]
    static var shadowPipelineCache: [ShaderConfiguration: MTLRenderPipelineState] = [:]
    static var pipelineReflectionCache: [ShaderConfiguration: MTLRenderPipelineReflection] = [:]
    static var pipelineParametersCache: [ShaderConfiguration: ParameterGroup] = [:]

    public static func invalidate(configuration: ShaderConfiguration) {
        invalidatePipeline(configuration: configuration)
        invalidatePipelineReflection(configuration: configuration)
        invalidatePipelineParameters(configuration: configuration)
        invalidateShadowPipeline(configuration: configuration)
    }

    public static func invalidatePipeline(configuration: ShaderConfiguration) {
        pipelineCache.removeValue(forKey: configuration)
    }

    public static func invalidatePipelineReflection(configuration: ShaderConfiguration) {
        pipelineReflectionCache.removeValue(forKey: configuration)
    }

    public static func invalidatePipelineParameters(configuration: ShaderConfiguration) {
        pipelineParametersCache.removeValue(forKey: configuration)
    }

    public static func invalidateShadowPipeline(configuration: ShaderConfiguration) {
        shadowPipelineCache.removeValue(forKey: configuration)
    }

    public static func getPipeline(configuration: ShaderConfiguration) throws -> MTLRenderPipelineState? {
        if let pipeline = pipelineCache[configuration] { return pipeline }

//        print("Creating Shader Pipeline: \(configuration)")

        guard let context = configuration.context,
              let library = try ShaderLibraryCache.getLibrary(configuration: configuration.getLibraryConfiguration(), device: context.device)
        else { return nil }

        guard let vertexFunction = library.makeFunction(name: configuration.vertexFunctionName),
              let fragmentFunction = library.makeFunction(name: configuration.fragmentFunctionName)
        else { return nil }

        var descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = configuration.label

        descriptor.vertexDescriptor = configuration.rendering.vertexDescriptor
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction

        setupRenderPipelineDescriptorContext(context: context, descriptor: &descriptor)
        setupRenderPipelineDescriptorBlending(blending: configuration.rendering.blending, descriptor: &descriptor)

        if configuration.libraryURL != nil {
            var pipelineReflection: MTLRenderPipelineReflection?
            let pipeline = try context.device.makeRenderPipelineState(descriptor: descriptor, options: [.argumentInfo, .bufferTypeInfo], reflection: &pipelineReflection)
            pipelineCache[configuration] = pipeline
            pipelineReflectionCache[configuration] = pipelineReflection
            return pipeline
        }
        else {
            let pipeline = try context.device.makeRenderPipelineState(descriptor: descriptor)
            pipelineCache[configuration] = pipeline
            return pipeline
        }
    }

    public static func getShadowPipeline(configuration: ShaderConfiguration) throws -> MTLRenderPipelineState? {
        if let shadowPipeline = shadowPipelineCache[configuration] { return shadowPipeline }

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
        shadowPipelineCache[configuration] = pipeline
        return pipeline
    }

    public static func getPipelineReflection(configuration: ShaderConfiguration) -> MTLRenderPipelineReflection? {
        pipelineReflectionCache[configuration]
    }

    public static func getPipelineParameters(configuration: ShaderConfiguration) throws -> ParameterGroup? {
        if let parameters = pipelineParametersCache[configuration] { return parameters }

        if let reflection = pipelineReflectionCache[configuration] {
            for binding in reflection.fragmentBindings {
                if binding.index == FragmentBufferIndex.MaterialUniforms.rawValue, 
                    let bufferBinding = binding as? MTLBufferBinding,
                    let bufferStruct = bufferBinding.bufferStructType {

                    let parameters = parseParameters(bufferStruct: bufferStruct)
                    parameters.label = configuration.label.titleCase + " Uniforms"
                    pipelineParametersCache[configuration] = parameters
                    return parameters
                }
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
}
