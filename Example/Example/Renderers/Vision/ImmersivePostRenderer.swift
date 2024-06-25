//
//  ImmersivePostRenderer.swift
//  Example
//
//  Created by Reza Ali on 6/25/24.
//  Copyright © 2024 Hi-Rez. All rights reserved.
//

#if os(visionOS)

import ARKit
import CompositorServices
import Metal
import Satin

class ImmersiveBaseRenderer: MetalLayerRenderer {
    var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    var sharedAssetsURL: URL { assetsURL.appendingPathComponent("Shared") }
    var rendererAssetsURL: URL { assetsURL.appendingPathComponent(String(describing: type(of: self))) }
    var dataURL: URL { rendererAssetsURL.appendingPathComponent("Data") }
    var pipelinesURL: URL { rendererAssetsURL.appendingPathComponent("Pipelines") }
    var texturesURL: URL { rendererAssetsURL.appendingPathComponent("Textures") }
    var modelsURL: URL { rendererAssetsURL.appendingPathComponent("Models") }
}

final class ImmersivePostRenderer: ImmersiveBaseRenderer {
    let background = Mesh(geometry: SkyboxGeometry(size: 10), material: BasicColorMaterial(color: [0, 0, 0, 0]))
    let mesh = Mesh(geometry: IcoSphereGeometry(radius: 0.5, resolution: 0), material: BasicDiffuseMaterial())
    let floor = Mesh(geometry: PlaneGeometry(size: 3.0, orientation: .zx, centered: true), material: UVColorMaterial())

    final class PostMaterial: SourceMaterial {}

    lazy var postMaterial = PostMaterial(pipelinesURL: pipelinesURL)

    lazy var startTime = getTime()
    lazy var scene = Object(label: "Scene", [background, floor, mesh])
    lazy var context = Context(
        device: device,
        sampleCount: sampleCount,
        colorPixelFormat: colorPixelFormat,
        depthPixelFormat: depthPixelFormat,
        vertexAmplificationCount: layerRenderer.configuration.layout == .layered ? 2 : 1
    )

    var renderTexture: MTLTexture?

    lazy var renderer = Renderer(context: context, clearColor: .zero)

    lazy var postProcessor = PostProcessor(
        context: Context(
            device: device,
            sampleCount: 1,
            colorPixelFormat: colorPixelFormat,
            vertexAmplificationCount: layerRenderer.configuration.layout == .layered ? 2 : 1
        ),
        material: postMaterial
    )

    override var layerLayout: LayerRenderer.Layout { .layered }
    override var isFoveationEnabled: Bool { false }

    let planeDetectionProvider = PlaneDetectionProvider(alignments: [.horizontal])
    override var arSessionDataProviders: [any DataProvider] {
        var providers = super.arSessionDataProviders
        providers.append(planeDetectionProvider)
        return providers
    }

    override func setup() {
        renderer.colorStoreAction = .store
        mesh.position.y = 1.0
        mesh.position.z = -1
        floor.visible = false

        Task {
            for await update in planeDetectionProvider.anchorUpdates {
                if update.anchor.classification == .floor {
                    floor.visible = true
                    floor.worldMatrix = update.anchor.originFromAnchorTransform
                }
            }
        }
    }

    override func update() {
        let theta = Float(getTime() - startTime)
        mesh.orientation = simd_quatf(angle: theta * 0.75, axis: simd_normalize(simd_make_float3(sin(theta), cos(theta), 1.0)))
        scene.update()
    }

    override func draw(
        frame: LayerRenderer.Frame,
        renderPassDescriptor: MTLRenderPassDescriptor,
        commandBuffer: MTLCommandBuffer,
        cameras: [PerspectiveCamera],
        viewports: [MTLViewport],
        viewMappings: [MTLVertexAmplificationViewMapping]
    ) {
        if renderTexture == nil, let refTexture = renderPassDescriptor.colorAttachments[0].texture {
            renderTexture = duplicateTexture(ref: refTexture, rateMap: nil /*renderPassDescriptor.rasterizationRateMap*/)
        }

        guard let renderTexture else { return }

        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            cameras: cameras,
            viewports: viewports,
            viewMappings: viewMappings,
            renderTarget: renderTexture
        )

        if let refTexture = renderPassDescriptor.colorAttachments[0].texture {
            postProcessor.resize(size: (Float(viewports[0].width), Float(viewports[0].height)), scaleFactor: 1)
            postMaterial.set(renderTexture, index: FragmentTextureIndex.Custom0)

            let postRenderPassDescriptor = MTLRenderPassDescriptor()
            postRenderPassDescriptor.colorAttachments[0].texture = refTexture
            postRenderPassDescriptor.renderTargetArrayLength = viewports.count
            postRenderPassDescriptor.rasterizationRateMap = renderPassDescriptor.rasterizationRateMap

//            if let rateMap = renderPassDescriptor.rasterizationRateMap {
//                // Create a buffer for the rate map.
//                let rateMapParamSize = rateMap.parameterDataSizeAndAlign
//                if let rateMapData = device.makeBuffer(
//                    length: rateMapParamSize.size,
//                    options: MTLResourceOptions.storageModeShared
//                ) {
//                    rateMap.copyParameterData(buffer: rateMapData, offset: 0)
//                    postMaterial.set(rateMapData, index: FragmentBufferIndex.Custom0)
//                }
//            }

            postProcessor.draw(
                renderPassDescriptor: postRenderPassDescriptor,
                commandBuffer: commandBuffer,
                viewports: viewports,
                viewMappings: viewMappings
            )
        }
    }

    override func drawView(view: Int, frame: LayerRenderer.Frame, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer, camera: PerspectiveCamera, viewport: MTLViewport) {
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera,
            viewport: viewport
        )
    }

    func duplicateTexture(ref: MTLTexture, rateMap: MTLRasterizationRateMap?) -> MTLTexture? {
        let textureSize: MTLSize = rateMap?.physicalSize(layer: 0) ?? MTLSize(width: ref.width, height: ref.height, depth: ref.depth)
        let desc = MTLTextureDescriptor()
        desc.textureType = ref.textureType
        desc.pixelFormat = ref.pixelFormat
        desc.width = textureSize.width
        desc.height = textureSize.height
        desc.depth = textureSize.depth
        desc.sampleCount = ref.sampleCount
        desc.usage = [.renderTarget, .shaderRead]
        desc.arrayLength = ref.arrayLength

        let texture = device.makeTexture(descriptor: desc)
        texture?.label = "Render Texture"
        return texture
    }
}

#endif
