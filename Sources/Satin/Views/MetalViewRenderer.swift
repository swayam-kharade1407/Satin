//
//  ForgeRenderer.swift
//  Forging
//
//  Created by Reza Ali on 1/21/24.
//

import Foundation
import QuartzCore

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

open class MetalViewRenderer: MetalViewRendererDelegate {
    public enum Appearance {
        case unspecified
        case dark
        case light
    }

    open var id: String {
        var result = String(describing: type(of: self)).replacingOccurrences(of: "Renderer", with: "")
        if let bundleName = Bundle(for: type(of: self)).displayName, bundleName != result {
            result = result.replacingOccurrences(of: bundleName, with: "")
        }
        result = result.replacingOccurrences(of: ".", with: "")
        return result
    }

    public internal(set) unowned var metalView: MetalView!

    public internal(set) var device: MTLDevice!
    public internal(set) var commandQueue: MTLCommandQueue!
    public internal(set) var colorTextureNeedsUpdate = true
    public internal(set) var colorTexture: MTLTexture?
    public internal(set) var depthTextureNeedsUpdate = true
    public internal(set) var depthTexture: MTLTexture?

    public internal(set) var isSetup = false

    public internal(set) var appearance: Appearance = .unspecified {
        didSet {
            self.updateAppearance()
        }
    }

    open var sampleCount: Int { 1 }
    open var colorPixelFormat: MTLPixelFormat { .bgra8Unorm }
    open var depthPixelFormat: MTLPixelFormat { .depth32Float }
    open var stencilPixelFormat: MTLPixelFormat { .invalid }

    public var defaultContext: Context {
        Context(
            device: device,
            sampleCount: sampleCount,
            colorPixelFormat: colorPixelFormat,
            depthPixelFormat: depthPixelFormat,
            stencilPixelFormat: stencilPixelFormat
        )
    }

    private let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)
    private var inFlightSemaphoreWait = 0
    private var inFlightSemaphoreRelease = 0

    public init() {}

    open func setup() {}

    open func update() {}

    open func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {}

    open func updateAppearance() {}

    open func cleanup() {
#if DEBUG_VIEW
        print("\ncleanup - MetalViewRenderer: \(id)\n")
#endif
    }

    deinit {
#if DEBUG_VIEW
        print("\ndeinit - MetalViewRenderer: \(id)\n")
#endif
        let delta = inFlightSemaphoreWait + inFlightSemaphoreRelease
        for _ in 0 ..< delta {
            inFlightSemaphore.signal()
        }
    }

    open func resize(size: (width: Float, height: Float), scaleFactor: Float) {}

    open func preDraw() -> MTLCommandBuffer? {
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            inFlightSemaphoreWait += 1
            commandBuffer.addCompletedHandler { [weak self] _ in
                self?.inFlightSemaphore.signal()
                self?.inFlightSemaphoreRelease -= 1
            }
            return commandBuffer
        }
        return nil
    }

    open func postDraw(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer) {
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    // MARK: - Events

#if os(macOS)

    open func touchesBegan(with event: NSEvent) {}

    open func touchesEnded(with event: NSEvent) {}

    open func touchesMoved(with event: NSEvent) {}

    open func touchesCancelled(with event: NSEvent) {}

    open func scrollWheel(with event: NSEvent) {}

    open func mouseMoved(with event: NSEvent) {}

    open func mouseDown(with event: NSEvent) {}

    open func mouseDragged(with event: NSEvent) {}

    open func mouseUp(with event: NSEvent) {}

    open func mouseEntered(with event: NSEvent) {}

    open func mouseExited(with event: NSEvent) {}

    open func rightMouseDown(with event: NSEvent) {}

    open func rightMouseDragged(with event: NSEvent) {}

    open func rightMouseUp(with event: NSEvent) {}

    open func otherMouseDown(with event: NSEvent) {}

    open func otherMouseDragged(with event: NSEvent) {}

    open func otherMouseUp(with event: NSEvent) {}

    open func performKeyEquivalent(with event: NSEvent) -> Bool { return false }

    open func keyDown(with event: NSEvent) -> Bool { return false }

    open func keyUp(with event: NSEvent) -> Bool { return false }

    open func flagsChanged(with event: NSEvent) -> Bool { return false }

    open func magnify(with event: NSEvent) {}

    open func rotate(with event: NSEvent) {}

    open func swipe(with event: NSEvent) {}

#elseif os(iOS) || os(tvOS) || os(visionOS)

    open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}

    open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}

    open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}

    open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}

#endif

    // MARK: - ForgeMetalViewRenderDelegate

    internal func draw(metalLayer: CAMetalLayer) {
        updateColorTexture()
        updateDepthTexture()

        update()

        guard let drawable = metalLayer.nextDrawable(), let commandBuffer = preDraw() else { return }

        let renderPassDescriptor = MTLRenderPassDescriptor()

        if sampleCount > 1 {
            renderPassDescriptor.colorAttachments[0].texture = colorTexture
            renderPassDescriptor.colorAttachments[0].resolveTexture = drawable.texture
            renderPassDescriptor.renderTargetWidth = colorTexture?.width ?? 0
            renderPassDescriptor.renderTargetHeight = colorTexture?.height ?? 0
        }
        else {
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.renderTargetWidth = drawable.texture.width
            renderPassDescriptor.renderTargetHeight = drawable.texture.height
        }
        renderPassDescriptor.depthAttachment.texture = depthTexture

        draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
        postDraw(drawable: drawable, commandBuffer: commandBuffer)
    }

    internal func updateDepthTexture() {
        guard depthPixelFormat != .invalid, depthTextureNeedsUpdate else { return }
        let width = Int(metalView.drawableSize.width)
        let height = Int(metalView.drawableSize.height)

        guard width > 0, height > 0 else { return }

        if let depthTexture, width == depthTexture.width, height == depthTexture.height {
            depthTextureNeedsUpdate = false
        }

        if depthTextureNeedsUpdate {
#if DEBUG_VIEWS
            print("Creating Depth Texture - MetalViewRenderer: \(id)")
#endif
            let multiSample = sampleCount > 1
            let descriptor = MTLTextureDescriptor()
            descriptor.pixelFormat = depthPixelFormat
            descriptor.width = width
            descriptor.height = height
            descriptor.sampleCount = sampleCount
            descriptor.textureType = multiSample ? .type2DMultisample : .type2D
            descriptor.usage = [.renderTarget, .shaderRead]
            descriptor.storageMode = .private
            descriptor.resourceOptions = .storageModePrivate

            depthTexture = device.makeTexture(descriptor: descriptor)
            depthTexture?.label = "\(id) \(multiSample ? "MultiSample" : "") Depth Texture"
        }

        depthTextureNeedsUpdate = depthTexture == nil
    }

    internal func updateColorTexture() {
        guard sampleCount > 1, colorTextureNeedsUpdate else { return }

        let width = Int(metalView.drawableSize.width)
        let height = Int(metalView.drawableSize.height)

        guard width > 0, height > 0 else { return }

        if let colorTexture, width == colorTexture.width, height == colorTexture.height {
            colorTextureNeedsUpdate = false
        }

        if colorTextureNeedsUpdate {
#if DEBUG_VIEWS
            print("Creating Color Texture - MetalViewRenderer: \(id)")
#endif
            let descriptor = MTLTextureDescriptor()
            descriptor.pixelFormat = colorPixelFormat
            descriptor.sampleCount = sampleCount
            descriptor.textureType = .type2DMultisample
            descriptor.width = width
            descriptor.height = height
            descriptor.usage = [.renderTarget, .shaderRead]
            descriptor.storageMode = .private
            descriptor.resourceOptions = .storageModePrivate
            colorTexture = device.makeTexture(descriptor: descriptor)
            colorTexture?.label = "\(id) Multisample Color Texture"
        }

        colorTextureNeedsUpdate = colorTexture == nil
    }

    internal func drawableResized(size: CGSize, scaleFactor: CGFloat) {
#if DEBUG_VIEWS
        print("renderer resize: \(size), scaleFactor: \(scaleFactor) - MetalViewRenderer: \(id)")
#endif
        depthTextureNeedsUpdate = true
        colorTextureNeedsUpdate = true
        resize(size: (Float(size.width), Float(size.height)), scaleFactor: Float(scaleFactor))
    }
}
