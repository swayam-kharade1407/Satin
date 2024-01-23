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
    open var label: String { "MetalViewRenderer" }

    public internal(set) unowned var metalView: MetalView!

    public internal(set) var device: MTLDevice!
    public internal(set) var commandQueue: MTLCommandQueue!
    public internal(set) var depthTextureNeedsUpdate = true
    public internal(set) var depthTexture: MTLTexture?

    public internal(set) var isSetup = false

#if !os(visionOS)
    public enum Appearance {
        case unknown
        case dark
        case light
    }

    public internal(set) var appearance: Appearance = .unknown {
        didSet {
            updateAppearance()
        }
    }
#endif

    open var sampleCount: Int { 1 }
    open var colorPixelFormat: MTLPixelFormat { .bgra8Unorm }
    open var depthPixelFormat: MTLPixelFormat { .depth32Float }
    open var stencilPixelFormat: MTLPixelFormat { .invalid }

    private let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)
    private var inFlightSemaphoreWait = 0
    private var inFlightSemaphoreRelease = 0

    public init() {}

    open func setup() {}

    open func update() {}

    open func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {}

    open func cleanup() {}

    deinit {
        let delta = inFlightSemaphoreWait + inFlightSemaphoreRelease
        for _ in 0 ..< delta {
            inFlightSemaphore.signal()
        }
    }

    open func resize(size: (width: Float, height: Float), scaleFactor: Float) {}

#if !os(visionOS)
    open func updateAppearance() {}
#endif

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

    open func keyDown(with event: NSEvent) {}

    open func keyUp(with event: NSEvent) {}

    open func flagsChanged(with event: NSEvent) {}

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
        updateDepthTexture()
        update()

        guard let drawable = metalLayer.nextDrawable(), let commandBuffer = preDraw() else { return }

//        print("draw - MetalViewRenderer")

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.depthAttachment.texture = depthTexture
        draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
        postDraw(drawable: drawable, commandBuffer: commandBuffer)
    }

    internal func updateDepthTexture() {
        if depthPixelFormat != .invalid, depthTextureNeedsUpdate {

            let width = Int(metalView.drawableSize.width)
            let height = Int(metalView.drawableSize.height)

            if let depthTexture, width == depthTexture.width, height == depthTexture.height {
                depthTextureNeedsUpdate = false
            }

            if depthTextureNeedsUpdate {
                print("creating depth texture - MetalViewRenderer: \(label)")
                let descriptor = MTLTextureDescriptor()
                descriptor.pixelFormat = depthPixelFormat
                descriptor.usage = .renderTarget
                descriptor.width = width
                descriptor.height = height
                descriptor.storageMode = .private
                depthTexture = device.makeTexture(descriptor: descriptor)
            }
        }
        
        depthTextureNeedsUpdate = false
    }

    internal func drawableResized(size: CGSize, scaleFactor: CGFloat) {
        print("renderer resize: \(size), scaleFactor: \(scaleFactor) - MetalViewRenderer: \(label)")
        depthTextureNeedsUpdate = true
        resize(size: (Float(size.width), Float(size.height)), scaleFactor: Float(scaleFactor))
    }
}
