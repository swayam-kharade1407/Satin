//
//  TessellatedMaterial.swift
//  Tesselation
//
//  Created by Reza Ali on 4/1/23.
//  Copyright © 2023 Reza Ali. All rights reserved.
//

import Foundation
import Metal
import Satin

final class TessellatedShader: SourceShader {
    unowned var geometry: TessellatedGeometry

    public init(_ label: String, _ pipelineURL: URL, _ geometry: TessellatedGeometry) {
        self.geometry = geometry
        super.init(label: label, pipelineURL: pipelineURL)
    }

    required init(configuration: ShaderConfiguration) {
        fatalError("init(configuration:) has not been implemented")
    }

    override public func makePipeline() throws -> (pipeline: MTLRenderPipelineState?, reflection: MTLRenderPipelineReflection?) {
        guard let context,
              let library = try ShaderLibraryCache.getLibrary(configuration: configuration.getLibraryConfiguration(), device: context.device),
              let vertexFunction = library.makeFunction(name: vertexFunctionName),
              let fragmentFunction = library.makeFunction(name: fragmentFunctionName) else { return (nil, nil) }

        var reflection: MTLRenderPipelineReflection?

        var descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = label

        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction

        descriptor.tessellationPartitionMode = geometry.partitionMode
        descriptor.tessellationFactorStepFunction = geometry.stepFunction
        descriptor.tessellationOutputWindingOrder = geometry.windingOrder
        descriptor.tessellationControlPointIndexType = geometry.controlPointIndexType

        setupRenderPipelineDescriptorContext(context: context, descriptor: &descriptor)
        setupRenderPipelineDescriptorBlending(blending: configuration.blending, descriptor: &descriptor)

        let pipeline = try context.device.makeRenderPipelineState(
            descriptor: descriptor,
            options: [.bindingInfo, .bufferTypeInfo],
            reflection: &reflection
        )

        return (pipeline, reflection)
    }
}

final class TessellatedMaterial: SourceMaterial {
    unowned var geometry: TessellatedGeometry

    public init(pipelinesURL: URL, geometry: TessellatedGeometry) {
        self.geometry = geometry
        super.init(pipelinesURL: pipelinesURL)
    }

    required init() {
        fatalError("init() has not been implemented")
    }

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    override func createShader() -> Shader {
        return TessellatedShader(label, pipelineURL, geometry)
    }
}
