//
//  MeshShaderRenderer.swift
//  Example
//
//  Created by Reza Ali on 3/17/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Satin

class MeshShaderRenderer: BaseRenderer {
    var geometry = IcoSphereGeometry(radius: 1.0, resolution: 4)
    lazy var mesh = Mesh(geometry: geometry, material: BasicDiffuseMaterial(hardness: 0.7))
    fileprivate lazy var meshNormals = CustomMesh(geometry: geometry, material: CustomMaterial(pipelinesURL: pipelinesURL))

    lazy var scene = Object(label: "Scene", [mesh])
    lazy var context = Context(device: device, sampleCount: sampleCount, colorPixelFormat: colorPixelFormat, depthPixelFormat: depthPixelFormat, stencilPixelFormat: stencilPixelFormat)
    lazy var camera = PerspectiveCamera(position: .init(0.0, 0.0, 8.0), near: 0.01, far: 100.0, fov: 45)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: metalView)
    lazy var renderer = Renderer(context: context)
    lazy var startTime = getTime()

    override func setup() {
        mesh.triangleFillMode = .lines
        mesh.add(meshNormals)

        renderer.setClearColor(.one)

#if os(visionOS)
        renderer.setClearColor(.zero)
        metalView.backgroundColor = .clear
#endif
    }

    deinit {
        cameraController.disable()
    }

    override func update() {
        meshNormals.material?.set("Time", Float(getTime() - startTime))
        cameraController.update()
        camera.update()
        scene.update()
    }

    override func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )
    }

    override func resize(size: (width: Float, height: Float), scaleFactor: Float) {
        camera.aspect = size.width / size.height
        renderer.resize(size)
    }
}

private class CustomShader: SourceShader {
    public var objectFunctionName = "shaderObject"
    public var meshFunctionName = "shaderMesh"

    var meshFunction: String?

    init(_ label: String,
         _ pipelineURL: URL,
         _ objectFunctionName: String? = nil,
         _ meshFunctionName: String? = nil,
         _: String? = nil)
    {
        super.init(label: label, pipelineURL: pipelineURL)
        self.objectFunctionName = objectFunctionName ?? label.camelCase + "Object"
        self.meshFunctionName = meshFunctionName ?? label.camelCase + "Mesh"
    }

    required init(configuration: ShaderConfiguration) {
        super.init(configuration: configuration)
    }

    override open func makePipeline() throws -> MTLRenderPipelineState? {
        if #available(macOS 13.0, iOS 16.0, *) {
            if let context = context,
               let library = try ShaderLibraryCache.getLibrary(configuration: configuration.getLibraryConfiguration(), device: context.device),
               let objectFunction = library.makeFunction(name: objectFunctionName),
               let meshFunction = library.makeFunction(name: meshFunctionName),
               let fragmentFunction = library.makeFunction(name: fragmentFunctionName)
            {
                var descriptor = MTLMeshRenderPipelineDescriptor()
                descriptor.label = label + " Mesh"

                descriptor.objectFunction = objectFunction
                descriptor.meshFunction = meshFunction
                descriptor.fragmentFunction = fragmentFunction

                descriptor.rasterSampleCount = context.sampleCount
                descriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
                descriptor.depthAttachmentPixelFormat = context.depthPixelFormat
                descriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat

                setupMeshPipelineDescriptorBlending(blending: configuration.blending, descriptor: &descriptor)

                return try context.device.makeRenderPipelineState(descriptor: descriptor, options: []).0
            } else {
                return nil
            }
        } else {
            fatalError("Mesh Shader's are not supported")
        }
    }

    @available(macOS 13.0, iOS 16.0, *)
    public func setupMeshPipelineDescriptorBlending(blending: ShaderBlending, descriptor: inout MTLMeshRenderPipelineDescriptor) {
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
            default:
                break
        }
    }
}

private class CustomMaterial: SourceMaterial {
    init(pipelinesURL: URL) {
        super.init(pipelinesURL: pipelinesURL)
//        set("Time", 0.0)
    }

    required init() {
        fatalError("init() has not been implemented")
    }

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    override func createShader() -> Shader {
        let shader = CustomShader(label, pipelineURL)
        shader.live = true
        return shader
    }

    override func bindUniforms(renderEncoderState: RenderEncoderState, shadow: Bool) {
        guard #available(macOS 13.0, iOS 16.0, *), let uniforms = uniforms else { return }

        let renderEncoder = renderEncoderState.renderEncoder

        renderEncoder.setObjectBuffer(
            uniforms.buffer,
            offset: uniforms.offset,
            index: ObjectBufferIndex.MaterialUniforms.rawValue
        )

        renderEncoder.setMeshBuffer(
            uniforms.buffer,
            offset: uniforms.offset,
            index: MeshBufferIndex.MaterialUniforms.rawValue
        )

        if !shadow {
            renderEncoder.setFragmentBuffer(
                uniforms.buffer,
                offset: uniforms.offset,
                index: FragmentBufferIndex.MaterialUniforms.rawValue
            )
        }
    }
}

private class CustomMesh: Object, Renderable {
    var preDraw: ((MTLRenderCommandEncoder) -> Void)?

    var opaque: Bool { material?.blending == .disabled }
    var doubleSided: Bool = false

    var cullMode: MTLCullMode = .back
    var windingOrder: MTLWinding = .counterClockwise
    var triangleFillMode: MTLTriangleFillMode = .fill

    var renderOrder = 0
    var renderPass = 0

    var lighting: Bool { material?.lighting ?? false }
    var receiveShadow: Bool { material?.receiveShadow ?? false }
    var castShadow: Bool { material?.castShadow ?? false }

    var drawable: Bool {
        guard #available(macOS 13.0, iOS 16.0, *), material?.pipeline != nil else { return false }
        return true
    }

    var material: Satin.Material? {
        didSet {
            material?.context = context
        }
    }

    var materials: [Satin.Material] {
        if let material = material {
            return [material]
        }
        return []
    }

    var vertexUniforms: VertexUniformBuffer?

    public required init(from _: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    var geometry: Geometry

    init(geometry: Geometry, material: Material?) {
        self.geometry = geometry
        self.material = material
        super.init(label: "Custom Mesh")
    }

    override func setup() {
        setupVertexUniforms()
        setupGeometry()
        setupMaterial()
    }

    func setupVertexUniforms() {
        guard let context else { return }
        vertexUniforms = VertexUniformBuffer(context: context)
    }

    func setupGeometry() {
        guard let context = context else { return }
        geometry.context = context
    }

    func setupMaterial() {
        guard let context = context, let material = material else { return }
        material.context = context
    }

    // MARK: - Update

    override func update() {
        geometry.update()
        material?.update()
        super.update()
    }

    override func encode(_ commandBuffer: MTLCommandBuffer) {
        geometry.encode(commandBuffer)
        material?.encode(commandBuffer)
        super.encode(commandBuffer)
    }

    override func update(camera: Camera, viewport: simd_float4, index: Int) {
        vertexUniforms?.update(object: self, camera: camera, viewport: viewport, index: index)
        super.update(camera: camera, viewport: viewport, index: index)
    }

    // MARK: - Draw

    func draw(renderEncoderState: RenderEncoderState, shadow: Bool) {
        guard #available(macOS 13.0, iOS 16.0, *),
              let vertexUniforms,
              let material,
              let vertexBuffer = geometry.vertexBuffers[VertexBufferIndex.Vertices]
        else { return }

        material.bind(renderEncoderState: renderEncoderState, shadow: shadow)

        let renderEncoder = renderEncoderState.renderEncoder

        renderEncoder.setObjectBuffer(
            vertexBuffer,
            offset: 0,
            index: ObjectBufferIndex.Vertices.rawValue
        )

        renderEncoder.setObjectBuffer(
            geometry.indexBuffer,
            offset: 0,
            index: ObjectBufferIndex.Indicies.rawValue
        )

        renderEncoder.setMeshBuffer(
            vertexUniforms.buffer,
            offset: vertexUniforms.offset,
            index: MeshBufferIndex.VertexUniforms.rawValue
        )

        let instances = geometry.indexCount / 3

        renderEncoder.drawMeshThreadgroups(
            MTLSizeMake(instances, 1, 1),
            threadsPerObjectThreadgroup: MTLSizeMake(1, 1, 1),
            threadsPerMeshThreadgroup: MTLSizeMake(36, 1, 1)
        )
    }
}
