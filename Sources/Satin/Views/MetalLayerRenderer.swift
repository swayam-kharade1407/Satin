//
//  MetalLayerRenderer.swift
//
//
//  Created by Reza Ali on 1/23/24.
//

#if os(visionOS)

import CompositorServices
import Metal
import simd
import Spatial
import SwiftUI

extension LayerRenderer.Clock.Instant.Duration {
    var timeInterval: TimeInterval {
        let nanoseconds = TimeInterval(components.attoseconds / 1_000_000_000)
        return TimeInterval(components.seconds) + (nanoseconds / TimeInterval(NSEC_PER_SEC))
    }
}

open class MetalLayerRenderer: CompositorLayerConfiguration {
    open var id: String {
        var result = String(describing: type(of: self)).replacingOccurrences(of: "Renderer", with: "")
        if let bundleName = Bundle(for: type(of: self)).displayName, bundleName != result {
            result = result.replacingOccurrences(of: bundleName, with: "")
        }
        result = result.replacingOccurrences(of: ".", with: "")
        return result
    }

    public internal(set) var layerRenderer: LayerRenderer!
    public internal(set) var arSession: ARKitSession!
    public internal(set) var worldTracking: WorldTrackingProvider!

    public internal(set) var isSetup: Bool = false

    public internal(set) var device: MTLDevice!
    public internal(set) var commandQueue: MTLCommandQueue!

    open var sampleCount: Int { 1 }
    open var colorPixelFormat: MTLPixelFormat { .bgra8Unorm_srgb }
    open var depthPixelFormat: MTLPixelFormat { .depth32Float }
    open var isFoveationEnabled: Bool { true }
    open var layerLayout: LayerRenderer.Layout { .dedicated }

    private let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)

    public var cameras = Array(repeating: PerspectiveCamera(), count: 2)

    internal var onDisappearAction: (() -> Void)?

    public init() {}

    public func onDisappear(perform action: @escaping () -> Void) -> Self {
        onDisappearAction = action
        return self
    }

    public func startRenderLoop() {
        Task {
            do {
                try await arSession.run([worldTracking])
            } catch {
                fatalError("Failed to initialize ARSession")
            }

            let renderThread = Thread {
                self.renderLoop()
            }
            renderThread.name = "Forge Render Thread"
            renderThread.start()
        }
    }

    internal func renderLoop() {
        while true {
            if layerRenderer.state == .invalidated {
                cleanup()
                onDisappearAction?()
                return
            } else if layerRenderer.state == .paused {
                layerRenderer.waitUntilRunning()
                continue
            } else {
                autoreleasepool {
                    self.renderFrame()
                }
            }
        }
    }

    open func makeConfiguration(capabilities: LayerRenderer.Capabilities, configuration: inout LayerRenderer.Configuration) {
        configuration.depthFormat = depthPixelFormat
        configuration.colorFormat = colorPixelFormat

        let foveationEnabled = isFoveationEnabled && capabilities.supportsFoveation
        configuration.isFoveationEnabled = foveationEnabled

        let options: LayerRenderer.Capabilities.SupportedLayoutsOptions = foveationEnabled ? [.foveationEnabled] : []
        let supportedLayouts = capabilities.supportedLayouts(options: options)
        configuration.layout = supportedLayouts.contains(layerLayout) ? layerLayout : .dedicated

        print("configuration.layout: \(configuration.layout == .layered ? "layered" : "dedicated")")
    }

    open func setup() {}

    open func update() {}

    open func cleanup() {}

    open func preDraw(frame: LayerRenderer.Frame) -> (drawable: LayerRenderer.Drawable, commandBuffer: MTLCommandBuffer)? {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { fatalError("Failed to create command buffer") }

        guard let drawable = frame.queryDrawable() else { return nil }

        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)

        frame.startSubmission()

        let time = LayerRenderer.Clock.Instant.epoch.duration(to: drawable.frameTiming.presentationTime).timeInterval

        let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: time)

        drawable.deviceAnchor = deviceAnchor

        let semaphore = inFlightSemaphore
        commandBuffer.addCompletedHandler { _ in
            semaphore.signal()
        }

        /// Update any game state before rendering

        let simdDeviceAnchor = deviceAnchor?.originFromAnchorTransform ?? matrix_identity_float4x4

        func camera(forViewIndex viewIndex: Int) -> (view: simd_float4x4, projection: simd_float4x4) {
            let view = drawable.views[viewIndex]
            let projection = ProjectiveTransform3D(
                leftTangent: Double(view.tangents[0]),
                rightTangent: Double(view.tangents[1]),
                topTangent: Double(view.tangents[2]),
                bottomTangent: Double(view.tangents[3]),
                nearZ: Double(drawable.depthRange.y),
                farZ: Double(drawable.depthRange.x),
                reverseZ: true
            )

            return (view: (simdDeviceAnchor * view.transform).inverse, projection: .init(projection))
        }

        for i in 0 ..< drawable.views.count {
            let info = camera(forViewIndex: 0)
            let camera = cameras[i]
            camera.viewMatrix = info.view
            camera.updateViewMatrix = false
            camera.projectionMatrix = info.projection
            camera.updateProjectionMatrix = false
        }

        return (drawable, commandBuffer)
    }

    open func draw(frame: LayerRenderer.Frame, drawable: LayerRenderer.Drawable, commandBuffer: MTLCommandBuffer) {
        if layerRenderer.configuration.layout == .dedicated {
            for i in 0 ..< drawable.views.count {
                let renderPassDescriptor = MTLRenderPassDescriptor()
                renderPassDescriptor.colorAttachments[0].texture = drawable.colorTextures[i]
                renderPassDescriptor.depthAttachment.texture = drawable.depthTextures[i]
#if targetEnvironment(simulator)
                renderPassDescriptor.rasterizationRateMap = drawable.rasterizationRateMaps.first
#else
                renderPassDescriptor.rasterizationRateMap = drawable.rasterizationRateMaps[i]
#endif
                drawView(
                    view: i,
                    frame: frame,
                    renderPassDescriptor: renderPassDescriptor,
                    commandBuffer: commandBuffer,
                    camera: cameras[i],
                    viewport: drawable.views[i].textureMap.viewport
                )
            }
        } else {
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = drawable.colorTextures[0]
            renderPassDescriptor.depthAttachment.texture = drawable.depthTextures[0]
#if targetEnvironment(simulator)
            renderPassDescriptor.rasterizationRateMap = drawable.rasterizationRateMaps.first
#else
            renderPassDescriptor.rasterizationRateMap = drawable.rasterizationRateMaps[i]
#endif

            renderPassDescriptor.renderTargetArrayLength = drawable.views.count

            draw(
                frame: frame,
                renderPassDescriptor: renderPassDescriptor,
                commandBuffer: commandBuffer,
                cameras: cameras,
                viewports: drawable.views.map { $0.textureMap.viewport }
            )
        }
    }

    open func drawView(
        view: Int,
        frame: LayerRenderer.Frame,
        renderPassDescriptor: MTLRenderPassDescriptor,
        commandBuffer: MTLCommandBuffer,
        camera: PerspectiveCamera,
        viewport: MTLViewport
    ) {}

    open func draw(
        frame: LayerRenderer.Frame,
        renderPassDescriptor: MTLRenderPassDescriptor,
        commandBuffer: MTLCommandBuffer,
        cameras: [PerspectiveCamera],
        viewports: [MTLViewport]
    ) {}

    open func postDraw(frame: LayerRenderer.Frame, drawable: LayerRenderer.Drawable, commandBuffer: MTLCommandBuffer) {
        drawable.encodePresent(commandBuffer: commandBuffer)

        commandBuffer.commit()

        frame.endSubmission()
    }

    open func renderFrame() {
        /// Per frame updates hare

        update()

        guard let frame = layerRenderer.queryNextFrame() else { return }

        // Perform frame independent work

        frame.startUpdate()

        frame.endUpdate()

        guard let timing = frame.predictTiming() else { return }

        LayerRenderer.Clock().wait(until: timing.optimalInputTime)

        guard let (drawable, commandBuffer) = preDraw(frame: frame) else { return }

        draw(frame: frame, drawable: drawable, commandBuffer: commandBuffer)

        postDraw(frame: frame, drawable: drawable, commandBuffer: commandBuffer)
    }
}

#endif
