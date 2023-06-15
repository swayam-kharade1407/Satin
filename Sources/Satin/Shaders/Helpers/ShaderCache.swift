//
//  ShaderCache.swift
//
//
//  Created by Reza Ali on 6/14/23.
//

import Foundation
import Metal

final class ShaderCache {
    static var pipelineCache: [ShaderConfiguration: MTLRenderPipelineState] = [:]
    static var shadowPipelineCache: [ShaderConfiguration: MTLRenderPipelineState] = [:]
    static var pipelineReflectionCache: [ShaderConfiguration: MTLRenderPipelineReflection] = [:]
    static var pipelineParametersCache: [ShaderConfiguration: ParameterGroup] = [:]

    class func invalidate(configuration: ShaderConfiguration) {
        invalidatePipeline(configuration: configuration)
        invalidatePipelineReflection(configuration: configuration)
        invalidatePipelineParameters(configuration: configuration)
        invalidateShadowPipeline(configuration: configuration)
    }

    class func invalidatePipeline(configuration: ShaderConfiguration) {
        pipelineCache.removeValue(forKey: configuration)
    }

    class func invalidatePipelineReflection(configuration: ShaderConfiguration) {
        pipelineReflectionCache.removeValue(forKey: configuration)
    }

    class func invalidatePipelineParameters(configuration: ShaderConfiguration) {
        pipelineParametersCache.removeValue(forKey: configuration)
    }

    class func invalidateShadowPipeline(configuration: ShaderConfiguration) {
        shadowPipelineCache.removeValue(forKey: configuration)
    }

    class func getPipeline(configuration: ShaderConfiguration) throws -> MTLRenderPipelineState? {
        if let pipeline = pipelineCache[configuration] { return pipeline }

        print("Creating Shader Pipeline: \(configuration.description)")

        guard let context = configuration.context,
              let library = try ShaderLibraryCache.getLibrary(configuration: configuration.getLibraryConfiguration())
        else { return nil }

        guard let vertexFunction = library.makeFunction(name: configuration.vertexFunctionName),
              let fragmentFunction = library.makeFunction(name: configuration.fragmentFunctionName)
        else { return nil }

        var descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = configuration.label

        descriptor.vertexDescriptor = configuration.rendering.vertexDescriptor
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction

        descriptor.sampleCount = context.sampleCount
        descriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = context.depthPixelFormat
        descriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat

        setupPipelineDescriptorBlending(blending: configuration.rendering.blending, descriptor: &descriptor)

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

    class func getShadowPipeline(configuration: ShaderConfiguration) throws -> MTLRenderPipelineState? {
        if let shadowPipeline = shadowPipelineCache[configuration] { return shadowPipeline }

        guard let context = configuration.context, let library = try ShaderLibraryCache.getLibrary(configuration: configuration.getLibraryConfiguration()) else { return nil }

        guard let vertexFunction = library.makeFunction(name: configuration.shadowFunctionName) ?? library.makeFunction(name: configuration.vertexFunctionName) else { return nil }

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = configuration.label + " Shadow"

        pipelineStateDescriptor.vertexDescriptor = configuration.rendering.vertexDescriptor
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = nil

        pipelineStateDescriptor.sampleCount = 1
        pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat

        let pipeline = try context.device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        shadowPipelineCache[configuration] = pipeline
        return pipeline
    }

    class func getPipelineReflection(configuration: ShaderConfiguration) -> MTLRenderPipelineReflection? {
        return pipelineReflectionCache[configuration]
    }

    class func getPipelineParameters(configuration: ShaderConfiguration) throws -> ParameterGroup? {
        if let parameters = pipelineParametersCache[configuration] { return parameters }

        if let reflection = pipelineReflectionCache[configuration], let fragmentArgs = reflection.fragmentArguments {
            let args = fragmentArgs[FragmentBufferIndex.MaterialUniforms.rawValue]
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

    class func setupPipelineDescriptorBlending(blending: ShaderBlending, descriptor: inout MTLRenderPipelineDescriptor) {
        guard blending.type != .disabled, let colorAttachment = descriptor.colorAttachments[0] else { return }

        colorAttachment.isBlendingEnabled = true

        switch blending.type {
            case .alpha:
                colorAttachment.sourceRGBBlendFactor = .sourceAlpha
                colorAttachment.sourceAlphaBlendFactor = .sourceAlpha
                colorAttachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
                colorAttachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
                colorAttachment.rgbBlendOperation = .add
                colorAttachment.alphaBlendOperation = .add
            case .additive:
                colorAttachment.sourceRGBBlendFactor = .sourceAlpha
                colorAttachment.sourceAlphaBlendFactor = .one
                colorAttachment.destinationRGBBlendFactor = .one
                colorAttachment.destinationAlphaBlendFactor = .one
                colorAttachment.rgbBlendOperation = .add
                colorAttachment.alphaBlendOperation = .add
            case .subtract:
                colorAttachment.sourceRGBBlendFactor = .sourceAlpha
                colorAttachment.sourceAlphaBlendFactor = .sourceAlpha
                colorAttachment.destinationRGBBlendFactor = .oneMinusBlendColor
                colorAttachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
                colorAttachment.rgbBlendOperation = .reverseSubtract
                colorAttachment.alphaBlendOperation = .add
            case .custom:
                colorAttachment.sourceRGBBlendFactor = blending.sourceRGBBlendFactor
                colorAttachment.sourceAlphaBlendFactor = blending.sourceAlphaBlendFactor
                colorAttachment.destinationRGBBlendFactor = blending.destinationRGBBlendFactor
                colorAttachment.destinationAlphaBlendFactor = blending.destinationAlphaBlendFactor
                colorAttachment.rgbBlendOperation = blending.rgbBlendOperation
                colorAttachment.alphaBlendOperation = blending.alphaBlendOperation
            case .disabled:
                break
        }
    }
}
