//
//  MetalLayerRenderer.swift
//
//
//  Created by Reza Ali on 1/23/24.
//

#if os(visionOS)

import CompositorServices
import Spatial
import Metal
import simd

extension LayerRenderer.Clock.Instant.Duration {
    var timeInterval: TimeInterval {
        let nanoseconds = TimeInterval(components.attoseconds / 1_000_000_000)
        return TimeInterval(components.seconds) + (nanoseconds / TimeInterval(NSEC_PER_SEC))
    }
}

open class MetalLayerRenderer {
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

    public var sampleCount: Int { 1 }
    public var colorPixelFormat: MTLPixelFormat { .bgra8Unorm_srgb }
    public var depthPixelFormat: MTLPixelFormat { .depth32Float }

    private let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)

    public let leftEye = PerspectiveCamera()
    public let rightEye = PerspectiveCamera()

    public internal(set) var firstFrame: Bool = true

    public var cameras: [PerspectiveCamera] {
        [leftEye, rightEye]
    }

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

        let info = camera(forViewIndex: 0)
        leftEye.viewMatrix = info.view
        leftEye.updateViewMatrix = false
        leftEye.projectionMatrix = info.projection
        leftEye.updateProjectionMatrix = false

        if drawable.views.count > 1 {
            let info = camera(forViewIndex: 1)
            rightEye.viewMatrix = info.view
            rightEye.updateViewMatrix = false
            rightEye.projectionMatrix = info.projection
            rightEye.updateProjectionMatrix = false
        }

        return (drawable, commandBuffer)
    }

    open func draw(frame: LayerRenderer.Frame, drawable: LayerRenderer.Drawable, commandBuffer: MTLCommandBuffer) {
        for i in 0 ..< drawable.views.count {
            let colorTexture = drawable.colorTextures[i]
            let depthTexture = drawable.depthTextures[i]

            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = colorTexture
            renderPassDescriptor.depthAttachment.texture = depthTexture
            renderPassDescriptor.rasterizationRateMap = drawable.rasterizationRateMaps.first

            drawView(
                frame: frame,
                renderPassDescriptor: renderPassDescriptor,
                commandBuffer: commandBuffer,
                camera: cameras[i],
                viewport: drawable.views[i].textureMap.viewport
            )
        }
    }

    open func drawView(
        frame: LayerRenderer.Frame,
        renderPassDescriptor: MTLRenderPassDescriptor,
        commandBuffer: MTLCommandBuffer,
        camera: PerspectiveCamera,
        viewport: MTLViewport
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
