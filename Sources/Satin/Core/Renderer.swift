//
//  Renderer.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Combine
import Metal
import simd

open class Renderer {
    public var label = "Satin Renderer"

    public var onUpdate: (() -> Void)?

    public var sortObjects = false

    public var context: Context {
        didSet {
            if oldValue != context {
                updateColorTexture = true
                updateDepthTexture = true
                updateStencilTexture = true
            }
        }
    }

    public var size: (width: Float, height: Float) = (0, 0) {
        didSet {
            if oldValue.width != size.width || oldValue.height != size.height {
                updateViewport()

                updateColorTexture = true
                updateColorMultisampleTexture = true

                updateDepthTexture = true
                updateDepthMultisampleTexture = true

                updateStencilTexture = true
                updateStencilMultisampleTexture = true
            }
        }
    }

    // MARK: - Color Textures

    public var clearColor: MTLClearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)

    private var updateColorTexture = true
    public private(set) var colorTexture: MTLTexture?
    public var colorTextureStorageMode: MTLStorageMode = .memoryless {
        didSet {
            if oldValue != colorTextureStorageMode {
                updateColorTexture = true
            }
        }
    }

    private var updateColorMultisampleTexture = true
    public private(set) var colorMultisampleTexture: MTLTexture?
    public var colorMultisampleTextureStorageMode: MTLStorageMode = .memoryless {
        didSet {
            if oldValue != colorMultisampleTextureStorageMode {
                updateColorMultisampleTexture = true
            }
        }
    }

    public var colorLoadAction: MTLLoadAction = .clear
    public var colorStoreAction: MTLStoreAction = .store

    // MARK: - Depth Textures

    public var clearDepth = 0.0

    public var updateDepthTexture = true
    public private(set) var depthTexture: MTLTexture?
    public var depthTextureStorageMode: MTLStorageMode = .memoryless {
        didSet {
            if oldValue != depthTextureStorageMode {
                updateDepthTexture = true
            }
        }
    }

    public var updateDepthMultisampleTexture = true
    public private(set) var depthMultisampleTexture: MTLTexture?
    public var depthMultisampleTextureStorageMode: MTLStorageMode = .memoryless {
        didSet {
            if oldValue != depthMultisampleTextureStorageMode {
                updateDepthMultisampleTexture = true
            }
        }
    }

    public var depthLoadAction: MTLLoadAction = .clear
    public var depthStoreAction: MTLStoreAction = .store

    // MARK: - Stencil Textures

    public var clearStencil: UInt32 = 0

    public var updateStencilTexture = true
    public var stencilTexture: MTLTexture?
    public var stencilTextureStorageMode: MTLStorageMode = .memoryless {
        didSet {
            if oldValue != stencilTextureStorageMode {
                updateStencilTexture = true
            }
        }
    }

    public var updateStencilMultisampleTexture = true
    public var stencilMultisampleTexture: MTLTexture?
    public var stencilMultisampleTextureStorageMode: MTLStorageMode = .memoryless {
        didSet {
            if oldValue != stencilMultisampleTextureStorageMode {
                updateStencilMultisampleTexture = true
            }
        }
    }

    public var stencilLoadAction: MTLLoadAction = .clear
    public var stencilStoreAction: MTLStoreAction = .dontCare

    public var viewport = MTLViewport()

    public var invertViewportNearFar = false {
        didSet {
            if invertViewportNearFar != oldValue {
                updateViewport()
            }
        }
    }

    private var objectList = [Object]()
    private var renderLists = [Int: RenderList]()

    private var lightList = [Light]()
    private var lightReceivers = [Renderable]()
    private var _updateLightDataBuffer = false
    private var lightDataBuffer: StructBuffer<LightData>?
    private var lightDataSubscriptions = Set<AnyCancellable>()

    private var shadowCasters = [Renderable]()
    private var shadowReceivers = [Renderable]()
    private var shadowList = [Shadow]()
    private var _updateShadowMatrices = false
    private var shadowMatricesBuffer: StructBuffer<simd_float4x4>?
    private var shadowMatricesSubscriptions = Set<AnyCancellable>()

//    to do: fix this so we actually listen to texture updates and update the arg encoder
    private var _updateShadowData = false
    private var _updateShadowTextures = false
    private var shadowArgumentEncoder: MTLArgumentEncoder?
    private var shadowArgumentBuffer: MTLBuffer?
    private var shadowDataBuffer: StructBuffer<ShadowData>?
    private var shadowTextureSubscriptions = Set<AnyCancellable>()
    private var shadowBufferSubscriptions = Set<AnyCancellable>()

    // MARK: - Init

    public init(label: String = "Satin Renderer", context: Context, sortObjects: Bool = false, clearColor: simd_float4 = .init(0, 0, 0, 1), clearDepth: Double = 0) {
        self.label = label
        self.context = context
        self.sortObjects = sortObjects
        self.clearColor = .init(clearColor)
        self.clearDepth = clearDepth
    }

    public func setClearColor(_ color: simd_float4) {
        clearColor = .init(color)
    }

    // MARK: - Drawing

    public func draw(
        renderPassDescriptor: MTLRenderPassDescriptor,
        commandBuffer: MTLCommandBuffer,
        scene: Object,
        camera: Camera,
        viewport: MTLViewport? = nil,
        renderTarget: MTLTexture
    ) {
        if context.sampleCount > 1 {
            let resolveTexture = renderPassDescriptor.colorAttachments[0].resolveTexture
            renderPassDescriptor.colorAttachments[0].resolveTexture = renderTarget
            draw(
                renderPassDescriptor: renderPassDescriptor,
                commandBuffer: commandBuffer,
                scene: scene,
                cameras: [camera],
                viewports: [viewport ?? self.viewport]
            )
            renderPassDescriptor.colorAttachments[0].resolveTexture = resolveTexture
        } else {
            let renderTexture = renderPassDescriptor.colorAttachments[0].texture
            renderPassDescriptor.colorAttachments[0].texture = renderTarget
            draw(
                renderPassDescriptor: renderPassDescriptor,
                commandBuffer: commandBuffer,
                scene: scene,
                cameras: [camera],
                viewports: [viewport ?? self.viewport]
            )
            renderPassDescriptor.colorAttachments[0].texture = renderTexture
        }
    }

    public func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer, scene: Object, cameras: [Camera], viewports: [MTLViewport], viewMappings: [MTLVertexAmplificationViewMapping] = [], renderTarget: MTLTexture)
    {
        if context.sampleCount > 1 {
            let resolveTexture = renderPassDescriptor.colorAttachments[0].resolveTexture
            renderPassDescriptor.colorAttachments[0].resolveTexture = renderTarget
            draw(
                renderPassDescriptor: renderPassDescriptor,
                commandBuffer: commandBuffer,
                scene: scene,
                cameras: cameras,
                viewports: viewports,
                viewMappings: viewMappings
            )
            renderPassDescriptor.colorAttachments[0].resolveTexture = resolveTexture
        } else {
            let renderTexture = renderPassDescriptor.colorAttachments[0].texture
            renderPassDescriptor.colorAttachments[0].texture = renderTarget
            draw(
                renderPassDescriptor: renderPassDescriptor,
                commandBuffer: commandBuffer,
                scene: scene,
                cameras: cameras,
                viewports: viewports,
                viewMappings: viewMappings
            )
            renderPassDescriptor.colorAttachments[0].texture = renderTexture
        }
    }

    // https://developer.apple.com/documentation/metal/render_passes/improving_rendering_performance_with_vertex_amplification?language=objc
    // https://developer.apple.com/documentation/metal/render_passes/rendering_to_multiple_viewports_in_a_draw_command?language=objc

    public func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer, scene: Object, camera: Camera, viewport: MTLViewport? = nil) {
        draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            cameras: [camera],
            viewports: [viewport ?? self.viewport]
        )
    }

    public func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer, scene: Object, cameras: [Camera], viewports: [MTLViewport], viewMappings: [MTLVertexAmplificationViewMapping] = [])
    {
        let simd_viewports = viewports.map(\.float4)
        update(
            commandBuffer: commandBuffer,
            scene: scene,
            cameras: cameras,
            viewports: simd_viewports
        )

        // render objects that cast shadows into the depth textures
        if !shadowCasters.isEmpty, !shadowReceivers.isEmpty {
            for light in lightList where light.castShadow {
                light.shadow.draw(commandBuffer: commandBuffer, renderables: shadowCasters)
            }
        }

        let inColorStoreAction = renderPassDescriptor.colorAttachments[0].storeAction
        let inColorLoadAction = renderPassDescriptor.colorAttachments[0].loadAction
        let inColorTexture = renderPassDescriptor.colorAttachments[0].texture
        let inColorResolveTexture = renderPassDescriptor.colorAttachments[0].resolveTexture

        let inDepthStoreAction = renderPassDescriptor.depthAttachment.storeAction
        let inDepthLoadAction = renderPassDescriptor.depthAttachment.loadAction
        let inDepthTexture = renderPassDescriptor.depthAttachment.texture
        let inDepthResolveTexture = renderPassDescriptor.depthAttachment.resolveTexture

        let inStencilStoreAction = renderPassDescriptor.stencilAttachment.storeAction
        let inStencilLoadAction = renderPassDescriptor.stencilAttachment.loadAction
        let inStencilTexture = renderPassDescriptor.stencilAttachment.texture
        let inStencilResolveTexture = renderPassDescriptor.stencilAttachment.resolveTexture

        defer {
            renderPassDescriptor.colorAttachments[0].storeAction = inColorStoreAction
            renderPassDescriptor.colorAttachments[0].loadAction = inColorLoadAction
            renderPassDescriptor.colorAttachments[0].texture = inColorTexture
            renderPassDescriptor.colorAttachments[0].resolveTexture = inColorResolveTexture

            renderPassDescriptor.depthAttachment.storeAction = inDepthStoreAction
            renderPassDescriptor.depthAttachment.loadAction = inDepthLoadAction
            renderPassDescriptor.depthAttachment.texture = inDepthTexture
            renderPassDescriptor.depthAttachment.resolveTexture = inDepthResolveTexture

            renderPassDescriptor.stencilAttachment.storeAction = inStencilStoreAction
            renderPassDescriptor.stencilAttachment.loadAction = inStencilLoadAction
            renderPassDescriptor.stencilAttachment.texture = inStencilTexture
            renderPassDescriptor.stencilAttachment.resolveTexture = inStencilResolveTexture
        }

        if context.colorPixelFormat == .invalid {
            renderPassDescriptor.colorAttachments[0].texture = nil
            renderPassDescriptor.colorAttachments[0].resolveTexture = nil
        } else {
            if context.sampleCount > 1 {
                if inColorTexture?.sampleCount != context.sampleCount {
                    setupColorMultisampleTexture()
                    renderPassDescriptor.colorAttachments[0].texture = colorMultisampleTexture
                }

                if inColorResolveTexture == nil {
                    setupColorTexture()
                    renderPassDescriptor.colorAttachments[0].resolveTexture = colorTexture
                    renderPassDescriptor.renderTargetWidth = colorTexture!.width
                    renderPassDescriptor.renderTargetHeight = colorTexture!.height
                }

            } else if inColorTexture == nil {
                setupColorTexture()
                renderPassDescriptor.colorAttachments[0].texture = colorTexture
                renderPassDescriptor.renderTargetWidth = colorTexture!.width
                renderPassDescriptor.renderTargetHeight = colorTexture!.height
            }
        }

        if context.depthPixelFormat == .invalid {
            renderPassDescriptor.depthAttachment.texture = nil
            renderPassDescriptor.depthAttachment.resolveTexture = nil
        } else {
            if context.sampleCount > 1 {
                if inDepthTexture?.sampleCount != context.sampleCount {
                    setupDepthMultisampleTexture()
                    renderPassDescriptor.depthAttachment.texture = depthMultisampleTexture
                }

                if inDepthResolveTexture == nil {
                    setupDepthTexture()
                    renderPassDescriptor.depthAttachment.resolveTexture = depthTexture
                }

            } else if inDepthTexture == nil {
                setupDepthTexture()
                renderPassDescriptor.depthAttachment.texture = depthTexture
            }

            if context.depthPixelFormat == .depth32Float_stencil8 {
                renderPassDescriptor.stencilAttachment.texture = depthTexture
            }
        }

        if context.stencilPixelFormat != .invalid, context.depthPixelFormat != .depth32Float_stencil8 {
            if context.stencilPixelFormat == .invalid {
                renderPassDescriptor.stencilAttachment.texture = nil
                renderPassDescriptor.stencilAttachment.resolveTexture = nil
            } else if context.sampleCount > 1 {
                if inStencilTexture?.sampleCount != context.sampleCount {
                    setupStencilMultisampleTexture()
                    renderPassDescriptor.stencilAttachment.texture = stencilMultisampleTexture
                }

                if inStencilResolveTexture == nil {
                    setupStencilTexture()
                    renderPassDescriptor.depthAttachment.resolveTexture = stencilTexture
                }

            } else if inStencilTexture == nil {
                setupStencilTexture()
                renderPassDescriptor.stencilAttachment.texture = stencilTexture
            }
        }

        if context.sampleCount > 1 {
            if colorStoreAction == .store || colorStoreAction == .storeAndMultisampleResolve {
                renderPassDescriptor.colorAttachments[0].storeAction = .storeAndMultisampleResolve
            } else {
                renderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve
            }
            if depthStoreAction == .store || depthStoreAction == .storeAndMultisampleResolve {
                renderPassDescriptor.depthAttachment.storeAction = .storeAndMultisampleResolve
            } else {
                renderPassDescriptor.depthAttachment.storeAction = .multisampleResolve
            }
            if context.stencilPixelFormat != .invalid {
                if stencilStoreAction == .store || stencilStoreAction == .storeAndMultisampleResolve {
                    renderPassDescriptor.stencilAttachment.storeAction = .storeAndMultisampleResolve
                } else {
                    renderPassDescriptor.stencilAttachment.storeAction = .multisampleResolve
                }
            }
        } else {
            if colorStoreAction == .store || colorStoreAction == .storeAndMultisampleResolve {
                renderPassDescriptor.colorAttachments[0].storeAction = .store
            } else {
                renderPassDescriptor.colorAttachments[0].storeAction = .dontCare
            }
            if depthStoreAction == .store || depthStoreAction == .storeAndMultisampleResolve {
                renderPassDescriptor.depthAttachment.storeAction = .store
            } else {
                renderPassDescriptor.depthAttachment.storeAction = .dontCare
            }
            if context.stencilPixelFormat != .invalid {
                if stencilStoreAction == .store || stencilStoreAction == .storeAndMultisampleResolve {
                    renderPassDescriptor.stencilAttachment.storeAction = .store
                } else {
                    renderPassDescriptor.stencilAttachment.storeAction = .dontCare
                }
            }
        }

        renderPassDescriptor.colorAttachments[0].loadAction = colorLoadAction
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor

        renderPassDescriptor.depthAttachment.loadAction = depthLoadAction
        renderPassDescriptor.depthAttachment.clearDepth = clearDepth

        renderPassDescriptor.stencilAttachment.loadAction = stencilLoadAction
        renderPassDescriptor.stencilAttachment.clearStencil = clearStencil

        if renderLists.isEmpty {
            if colorLoadAction == .clear, let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
#if DEBUG
                renderEncoder.pushDebugGroup(label + " Empty Pass")
#endif
                renderEncoder.setViewports(viewports)
#if DEBUG
                renderEncoder.popDebugGroup()
#endif
                renderEncoder.endEncoding()
            }
        } else {
            let renderPassLists = renderLists.sorted { $0.key < $1.key }

            for (pass, renderPassList) in renderPassLists.enumerated() {
                let renderList = renderPassList.value
                let renderables = renderList.getRenderables(sorted: sortObjects)

                if !renderables.isEmpty, let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
#if DEBUG
                    renderEncoder.label = label + " Pass \(pass)"
                    renderEncoder.pushDebugGroup("Pass \(pass)")
#endif
                    renderEncoder.setViewports(viewports)

                    if context.vertexAmplificationCount > 1 {
                        var maps = viewMappings
                        if maps.isEmpty {
                            maps = (0..<context.vertexAmplificationCount).map { .init(viewportArrayIndexOffset: UInt32($0), renderTargetArrayIndexOffset: UInt32($0)) }
                        }
                        renderEncoder.setVertexAmplificationCount(context.vertexAmplificationCount, viewMappings: &maps)
                    }

                    encode(
                        renderEncoder: renderEncoder,
                        pass: pass,
                        renderables: renderables,
                        cameras: cameras,
                        viewports: simd_viewports
                    )

#if DEBUG
                    renderEncoder.popDebugGroup()
#endif
                    renderEncoder.endEncoding()

                    renderPassDescriptor.colorAttachments[0].loadAction = .load
                    renderPassDescriptor.depthAttachment.loadAction = .load
                    renderPassDescriptor.stencilAttachment.loadAction = .load
                }
            }
        }
    }

    // MARK: - Internal Update

    private func update(commandBuffer: MTLCommandBuffer, scene: Object, cameras: [Camera], viewports: [simd_float4]) {
        onUpdate?()

        objectList.removeAll(keepingCapacity: true)
        renderLists.removeAll(keepingCapacity: true)

        lightList.removeAll(keepingCapacity: true)
        lightReceivers.removeAll(keepingCapacity: true)

        shadowList.removeAll(keepingCapacity: true)
        shadowCasters.removeAll(keepingCapacity: true)
        shadowReceivers.removeAll(keepingCapacity: true)

        updateLists(object: scene)

        updateScene(commandBuffer: commandBuffer, cameras: cameras, viewports: viewports)
        updateLights()
        updateShadows()
    }

    private func updateLists(object: Object) {
        guard object.visible else { return }

        objectList.append(object)

        if let light = object as? Light {
            lightList.append(light)
            if light.castShadow {
                shadowList.append(light.shadow)
            }
        }

        if let renderable = object as? Renderable {
            if let renderPassList = renderLists[renderable.renderPass] {
                renderPassList.append(renderable)
            } else {
                renderLists[renderable.renderPass] = RenderList(renderable)
            }

            if renderable.lighting {
                lightReceivers.append(renderable)
            }

            if renderable.receiveShadow {
                shadowReceivers.append(renderable)
            }

            if renderable.castShadow {
                shadowCasters.append(renderable)
            }
        }

        for child in object.children {
            updateLists(object: child)
        }
    }

    private func updateScene(commandBuffer: MTLCommandBuffer, cameras: [Camera], viewports: [simd_float4]) {
        let lightCount = lightList.count
        let shadowCount = shadowList.count

        var environmentIntensity: Float = 1.0
        var cubemapTexture: MTLTexture?
        var reflectionTexture: MTLTexture?
        var irradianceTexture: MTLTexture?
        var brdfTexture: MTLTexture?
        var reflectionTexcoordTransform = matrix_identity_float3x3
        var irradianceTexcoordTransform = matrix_identity_float3x3

        for object in objectList {
            if let environment = object as? IBLEnvironment {
                environmentIntensity = environment.environmentIntensity
                cubemapTexture = environment.cubemapTexture

                reflectionTexture = environment.reflectionTexture
                reflectionTexcoordTransform = environment.reflectionTexcoordTransform

                irradianceTexture = environment.irradianceTexture
                irradianceTexcoordTransform = environment.irradianceTexcoordTransform

                brdfTexture = environment.brdfTexture
            }

            if let renderable = object as? Renderable {
                for material in renderable.materials {
                    if material.lighting {
                        material.lightCount = lightCount
                    }

                    if renderable.receiveShadow {
                        material.shadowCount = shadowCount
                    }

                    if let pbrMaterial = material as? StandardMaterial {
                        pbrMaterial.environmentIntensity = environmentIntensity
                        if let reflectionTexture = reflectionTexture {
                            pbrMaterial.setTexture(reflectionTexture, type: .reflection)
                            pbrMaterial.setTexcoordTransform(reflectionTexcoordTransform, type: .reflection)
                        }
                        if let irradianceTexture = irradianceTexture {
                            pbrMaterial.setTexture(irradianceTexture, type: .irradiance)
                            pbrMaterial.setTexcoordTransform(irradianceTexcoordTransform, type: .irradiance)
                        }
                        if let brdfTexture = brdfTexture {
                            pbrMaterial.setTexture(brdfTexture, type: .brdf)
                        }
                        pbrMaterial.update()
                    }

                    if let cubemapTexture = cubemapTexture, let skyboxMaterial = material as? SkyboxMaterial {
                        skyboxMaterial.texture = cubemapTexture
                        skyboxMaterial.texcoordTransform = reflectionTexcoordTransform
                        skyboxMaterial.environmentIntensity = environmentIntensity
                        skyboxMaterial.update()
                    }
                }
            } else {
                for i in 0..<context.vertexAmplificationCount {
                    object.update(camera: cameras[i], viewport: viewports[i], index: i)
                }
            }

            object.context = context
            object.encode(commandBuffer)
        }
    }

    // MARK: - Internal Encoding

    private func encode(
        renderEncoder: MTLRenderCommandEncoder,
        pass: Int,
        renderables: [Renderable],
        cameras: [Camera],
        viewports: [simd_float4]
    ) {
        let renderEncoderState = RenderEncoderState(renderEncoder: renderEncoder)

        if !lightReceivers.isEmpty {
            if let lightBuffer = lightDataBuffer {
                renderEncoder.setFragmentBuffer(
                    lightBuffer.buffer,
                    offset: lightBuffer.offset,
                    index: FragmentBufferIndex.Lighting.rawValue
                )
            }
        }

        if !shadowReceivers.isEmpty {
            for shadow in shadowList {
                if let shadowTexture = shadow.texture {
                    renderEncoder.useResource(shadowTexture, usage: .read, stages: .fragment)
                }
            }

            if let shadowDataBuffer = shadowDataBuffer {
                renderEncoder.useResource(shadowDataBuffer.buffer, usage: .read, stages: .fragment)
            }

            if let shadowBuffer = shadowMatricesBuffer {
                renderEncoder.setVertexBuffer(
                    shadowBuffer.buffer,
                    offset: shadowBuffer.offset,
                    index: VertexBufferIndex.ShadowMatrices.rawValue
                )
            }

            if let shadowArgumentBuffer = shadowArgumentBuffer {
                renderEncoder.setFragmentBuffer(
                    shadowArgumentBuffer,
                    offset: 0,
                    index: FragmentBufferIndex.Shadows.rawValue
                )
            }
        }

        for renderable in renderables where renderable.drawable {
            _encode(
                renderEncoder: renderEncoder,
                renderEncoderState: renderEncoderState,
                renderable: renderable,
                cameras: cameras,
                viewports: viewports
            )
        }
    }

    private func _encode(renderEncoder: MTLRenderCommandEncoder, renderEncoderState: RenderEncoderState, renderable: Renderable, cameras: [Camera], viewports: [simd_float4]) {
#if DEBUG
        renderEncoder.pushDebugGroup(renderable.label)
#endif
        for i in 0..<context.vertexAmplificationCount {
            renderable.update(camera: cameras[i], viewport: viewports[i], index: i)
        }

        renderable.preDraw?(renderEncoder)

        renderEncoderState.windingOrder = renderable.windingOrder
        renderEncoderState.triangleFillMode = renderable.triangleFillMode

        if renderable.doubleSided, renderable.cullMode == .none, renderable.opaque == false {
            renderEncoderState.cullMode = .front
            renderable.draw(renderEncoderState: renderEncoderState, shadow: false)

            renderEncoderState.cullMode = .back
            renderable.draw(renderEncoderState: renderEncoderState, shadow: false)
        } else {
            renderEncoderState.cullMode = renderable.cullMode
            renderable.draw(renderEncoderState: renderEncoderState, shadow: false)
        }

#if DEBUG
        renderEncoder.popDebugGroup()
#endif
    }

    // MARK: - Resizing

    public func resize(_ size: (width: Float, height: Float)) {
        self.size = size
    }

    private func updateViewport() {
        viewport = MTLViewport(
            originX: 0.0,
            originY: 0.0,
            width: Double(size.width),
            height: Double(size.height),
            znear: invertViewportNearFar ? 1.0 : 0.0,
            zfar: invertViewportNearFar ? 0.0 : 1.0
        )
    }

    // MARK: - Color Textures

    private func setupColorTexture() {
        guard updateColorTexture, context.colorPixelFormat != .invalid, size.width > 1, size.height > 1 else { return }

        let descriptor = MTLTextureDescriptor
            .texture2DDescriptor(
                pixelFormat: context.colorPixelFormat,
                width: Int(size.width),
                height: Int(size.height),
                mipmapped: false
            )
        descriptor.sampleCount = 1
        descriptor.textureType = .type2D
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = colorTextureStorageMode
        descriptor.resourceOptions = .storageModePrivate

        colorTexture = context.device.makeTexture(descriptor: descriptor)
        colorTexture?.label = label + " Color Texture"

        updateColorTexture = false
    }

    private func setupColorMultisampleTexture() {
        guard updateColorMultisampleTexture,
              context.colorPixelFormat != .invalid,
              context.sampleCount > 1,
              size.width > 0,
              size.height > 0
        else { return }

        let descriptor = MTLTextureDescriptor
            .texture2DDescriptor(
                pixelFormat: context.colorPixelFormat,
                width: Int(size.width),
                height: Int(size.height),
                mipmapped: false
            )
        descriptor.sampleCount = context.sampleCount
        descriptor.textureType = .type2DMultisample
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = colorMultisampleTextureStorageMode
        descriptor.resourceOptions = .storageModePrivate

        colorMultisampleTexture = context.device.makeTexture(descriptor: descriptor)
        colorMultisampleTexture?.label = label + "Multisample Color Texture"

        updateColorMultisampleTexture = false
    }

    // MARK: - Depth Textures

    private func setupDepthTexture() {
        guard updateDepthTexture,
              context.depthPixelFormat != .invalid,
              size.width > 0,
              size.height > 0
        else { return }

        let descriptor = MTLTextureDescriptor
            .texture2DDescriptor(
                pixelFormat: context.depthPixelFormat,
                width: Int(size.width),
                height: Int(size.height),
                mipmapped: false
            )
        descriptor.sampleCount = 1
        descriptor.textureType = .type2D
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = depthTextureStorageMode
        descriptor.resourceOptions = .storageModePrivate

        depthTexture = context.device.makeTexture(descriptor: descriptor)
        depthTexture?.label = label + " Depth Texture"

        updateDepthTexture = false
    }

    private func setupDepthMultisampleTexture() {
        guard updateDepthMultisampleTexture,
              context.depthPixelFormat != .invalid,
              context.sampleCount > 1,
              size.width > 0,
              size.height > 0
        else { return }

        let descriptor = MTLTextureDescriptor
            .texture2DDescriptor(
                pixelFormat: context.depthPixelFormat,
                width: Int(size.width),
                height: Int(size.height),
                mipmapped: false
            )
        descriptor.sampleCount = context.sampleCount
        descriptor.textureType = .type2DMultisample
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = depthMultisampleTextureStorageMode
        descriptor.resourceOptions = .storageModePrivate

        depthMultisampleTexture = context.device.makeTexture(descriptor: descriptor)
        depthMultisampleTexture?.label = label + "Multisample Depth Texture"

        updateDepthMultisampleTexture = false
    }

    // MARK: - Stencil Textures

    private func setupStencilTexture() {
        guard updateStencilTexture, context.stencilPixelFormat != .invalid, size.width > 1, size.height > 1 else { return }

        let descriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = context.stencilPixelFormat
        descriptor.width = Int(size.width)
        descriptor.height = Int(size.height)
        descriptor.sampleCount = 1
        descriptor.textureType = .type2D
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .memoryless
        descriptor.resourceOptions = .storageModePrivate

        stencilTexture = context.device.makeTexture(descriptor: descriptor)
        stencilTexture?.label = label + " Stencil Texture"

        updateStencilTexture = false
    }

    private func setupStencilMultisampleTexture() {
        guard updateStencilMultisampleTexture,
              context.stencilPixelFormat != .invalid,
              context.sampleCount > 1,
              size.width > 0,
              size.height > 0 else { return }

        let descriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = context.stencilPixelFormat
        descriptor.width = Int(size.width)
        descriptor.height = Int(size.height)
        descriptor.sampleCount = context.sampleCount
        descriptor.textureType = .type2DMultisample
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .memoryless
        descriptor.resourceOptions = .storageModePrivate

        stencilMultisampleTexture = context.device.makeTexture(descriptor: descriptor)
        stencilMultisampleTexture?.label = label + "Multisample Stencil Texture"

        updateStencilTexture = false
    }

    // MARK: - Lights

    private func updateLights() {
        setupLightDataBuffer()
        updateLightDataBuffer()
    }

    private func setupLightDataBuffer() {
        guard lightList.count != lightDataBuffer?.count else { return }
        lightDataSubscriptions.removeAll(keepingCapacity: true)

        if lightList.isEmpty {
            lightDataBuffer = nil
        } else {
            for light in lightList {
                light.publisher.sink { [weak self] _ in
                    self?._updateLightDataBuffer = true
                }.store(in: &lightDataSubscriptions)
            }
            lightDataBuffer = StructBuffer<LightData>.init(
                device: context.device,
                count: lightList.count,
                label: "Light Data Buffer"
            )

            _updateLightDataBuffer = true
        }
    }

    private func updateLightDataBuffer() {
        guard let lightBuffer = lightDataBuffer, _updateLightDataBuffer else { return }

        lightBuffer.update(data: lightList.map { $0.data })

        _updateLightDataBuffer = false
    }

    // MARK: - Shadows

    private func updateShadows() {
        setupShadows()
        updateShadowMatrices()
        updateShadowData()
        updateShadowTextures()
    }

    private func setupShadows() {
        guard shadowList.count != shadowMatricesBuffer?.count else { return }

        shadowMatricesSubscriptions.removeAll(keepingCapacity: true)
        shadowTextureSubscriptions.removeAll(keepingCapacity: true)
        shadowBufferSubscriptions.removeAll(keepingCapacity: true)

        if shadowList.isEmpty {
            shadowMatricesBuffer = nil
            shadowArgumentEncoder = nil
            shadowArgumentBuffer = nil

        } else {
            shadowMatricesBuffer = StructBuffer<simd_float4x4>.init(
                device: context.device,
                count: shadowList.count,
                label: "Shadow Matrices Buffer"
            )

            for light in lightList where light.castShadow {
                light.publisher.sink { [weak self] _ in
                    self?._updateShadowMatrices = true
                }.store(in: &shadowMatricesSubscriptions)
            }

            _updateShadowMatrices = true

            let strengthsArg = MTLArgumentDescriptor()
            strengthsArg.index = FragmentBufferIndex.ShadowData.rawValue
            strengthsArg.access = .readOnly
            strengthsArg.dataType = .pointer

            let texturesArg = MTLArgumentDescriptor()
            texturesArg.index = FragmentTextureIndex.Shadow0.rawValue
            texturesArg.access = .readOnly
            texturesArg.arrayLength = shadowList.count
            texturesArg.dataType = .texture
            texturesArg.textureType = .type2D

            if let shadowArgumentEncoder = context.device.makeArgumentEncoder(arguments: [strengthsArg, texturesArg]) {
                let shadowArgumentBuffer = context.device.makeBuffer(length: shadowArgumentEncoder.encodedLength, options: .storageModeShared)
                shadowArgumentBuffer?.label = "Shadow Argument Buffer"
                shadowArgumentEncoder.setArgumentBuffer(shadowArgumentBuffer, offset: 0)

                let shadowDataBuffer = StructBuffer<ShadowData>.init(
                    device: context.device,
                    count: shadowList.count,
                    label: "Shadow Data Buffer"
                )

                self.shadowArgumentBuffer = shadowArgumentBuffer
                self.shadowArgumentEncoder = shadowArgumentEncoder
                self.shadowDataBuffer = shadowDataBuffer

                shadowArgumentEncoder.setBuffer(shadowDataBuffer.buffer, offset: shadowDataBuffer.offset, index: FragmentBufferIndex.ShadowData.rawValue)

                for (index, shadow) in shadowList.enumerated() {
                    shadowArgumentEncoder.setTexture(shadow.texture, index: FragmentTextureIndex.Shadow0.rawValue + index)
                }
            }

            for shadow in shadowList {
                shadow.dataPublisher.sink { [weak self] _ in
                    self?._updateShadowData = true
                }.store(in: &shadowBufferSubscriptions)

                shadow.texturePublisher.sink { [weak self] _ in
                    self?._updateShadowTextures = true
                }.store(in: &shadowTextureSubscriptions)
            }

            _updateShadowData = true
            _updateShadowTextures = true
        }
    }

    private func updateShadowMatrices() {
        guard let shadowMatricesBuffer = shadowMatricesBuffer,
              _updateShadowMatrices else { return }

        shadowMatricesBuffer.update(data: shadowList.map { $0.camera.viewProjectionMatrix })

        _updateShadowMatrices = false
    }

    private func updateShadowData() {
        guard let shadowArgumentEncoder = shadowArgumentEncoder,
              let shadowDataBuffer = shadowDataBuffer,
              _updateShadowData else { return }

        shadowDataBuffer.update(data: shadowList.map { $0.data })
        shadowArgumentEncoder.setBuffer(
            shadowDataBuffer.buffer,
            offset: shadowDataBuffer.offset,
            index: FragmentBufferIndex.ShadowData.rawValue
        )

        _updateShadowData = false
    }

    private func updateShadowTextures() {
        guard let shadowArgumentEncoder = shadowArgumentEncoder,
              _updateShadowTextures else { return }

        for (index, shadow) in shadowList.enumerated() {
            shadowArgumentEncoder.setTexture(shadow.texture, index: FragmentTextureIndex.Shadow0.rawValue + index)
        }

        _updateShadowTextures = false
    }
}
