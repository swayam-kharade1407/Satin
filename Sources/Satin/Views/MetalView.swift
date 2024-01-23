//
//  ForgeMetalView.swift
//  Forging
//
//  Created by Reza Ali on 1/21/24.
//

#if os(macOS)

import AppKit
import Foundation
import QuartzCore

public class MetalView: NSView, CALayerDelegate {
    public var isPaused: Bool {
        get {
            _displayLinkPaused
        }
        set {
            print("isPaused - ForgeMetalView: \(newValue)")

            if newValue {
                pauseRenderLoop()
            }
            else {
                resumeRenderLoop()
            }
        }
    }

    public var drawableSize: CGSize {
        metalLayer.drawableSize
    }

    weak var delegate: MetalViewRendererDelegate?

    public private(set) lazy var metalLayer: CAMetalLayer = self.layer as! CAMetalLayer

    public var contentScaleFactor: CGFloat { window?.screen?.backingScaleFactor ?? 1 }

    private var _displayLinkPaused = false
    private var _displayLink: CVDisplayLink?
    private var _displaySource: DispatchSourceUserDataAdd?
    private let _dispatchRenderLoop: CVDisplayLinkOutputCallback = {
        displayLink, now, outputTime, flagsIn, flagsOut, displayLinkContext in
        let source = Unmanaged<DispatchSourceUserDataAdd>.fromOpaque(displayLinkContext!).takeUnretainedValue()
        source.add(data: 1)
        return kCVReturnSuccess
    }

    // MARK: - Init

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    // MARK: - Deinit

    deinit {
        print("deinit - ForgeMetalView: \(delegate?.label)")

        stopRenderLoop()
    }

    // MARK: - Layer

    override public func makeBackingLayer() -> CALayer {
        CAMetalLayer()
    }

    // MARK: - Configure

    private func configure() {
        print("\n\n\nconfigure - ForgeMetalView: \(delegate?.label)")

        autoresizingMask = [.width, .height]

        wantsLayer = true
        layerContentsRedrawPolicy = .duringViewResize
        metalLayer.delegate = self
    }

    // MARK: - Render

    private func render() {
//        print("render - ForgeMetalView")

        delegate?.draw(metalLayer: metalLayer)
    }

    // MARK: - View Window Change

    override public func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if let window = self.window {
            print("viewDidMoveToWindow - ForgeMetalView: \(delegate?.label), \(window)")
            setupRenderLoop(screen: window.screen)
            resizeDrawable()
        }
    }

    // MARK: - Event Based Rendering

    public func display(_ layer: CALayer) {
        render()
    }

    public func draw(_ layer: CALayer, in ctx: CGContext) {
        render()
    }

    override public func draw(_ dirtyRect: NSRect) {
        render()
    }

    // MARK: - Render Loop

    private func setupRenderLoop(screen: NSScreen?) {
        print("setupRenderLoop - ForgeMetalView: \(delegate?.label)")

        _displaySource = DispatchSource.makeUserDataAddSource(queue: DispatchQueue.main)
        _displaySource!.setEventHandler { [weak self] in
            self?.render()
        }
        _displaySource!.resume()

        var cvReturn = CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink)

        assert(cvReturn == kCVReturnSuccess)

        cvReturn = CVDisplayLinkSetOutputCallback(
            _displayLink!,
            _dispatchRenderLoop,
            Unmanaged.passUnretained(_displaySource!).toOpaque()
        )

        assert(cvReturn == kCVReturnSuccess)

        let displayID = screen?.deviceDescription[NSDeviceDescriptionKey(rawValue: "NSScreenNumber")] as? CGDirectDisplayID

        cvReturn = CVDisplayLinkSetCurrentCGDisplay(_displayLink!, displayID ?? CGMainDisplayID())

        assert(cvReturn == kCVReturnSuccess)

        if !_displayLinkPaused {
            CVDisplayLinkStart(_displayLink!)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: window
        )
    }

    private func pauseRenderLoop() {
        if let displayLink = _displayLink, !_displayLinkPaused {
            print("pauseRenderLoop - ForgeMetalView: \(delegate?.label)")
            CVDisplayLinkStop(displayLink)
        }

        _displayLinkPaused = true
    }

    private func resumeRenderLoop() {
        if let displayLink = _displayLink, _displayLinkPaused {
            print("resumeRenderLoop - ForgeMetalView: \(delegate?.label)")
            CVDisplayLinkStart(displayLink)
        }

        _displayLinkPaused = false
    }

    func stopRenderLoop() {
        guard _displayLink != nil else { return }

        print("stopRenderLoop - ForgeMetalView: \(delegate?.label)")

        pauseRenderLoop()

        _displayLink = nil

        _displaySource?.cancel()
        _displaySource = nil
    }

    @objc func windowWillClose(_ notification: Notification) {
        guard notification.object as AnyObject? === window else { return }
        print("windowWillClose - ForgeMetalView: \(delegate?.label)")
        stopRenderLoop()
    }

    // MARK: - Resize

    override public func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        resizeDrawable()
    }

    override public func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        resizeDrawable()
    }

    override public func setBoundsSize(_ newSize: NSSize) {
        super.setBoundsSize(newSize)
        resizeDrawable()
    }

    private func resizeDrawable() {
        let newScaleFactor = contentScaleFactor
        var newSize = bounds.size

        newSize.width *= newScaleFactor
        newSize.height *= newScaleFactor

        guard newSize.width > 0, newSize.height > 0 else { return }

        guard newSize.height != metalLayer.drawableSize.height ||
            newSize.width != metalLayer.drawableSize.width else { return }

        print("resizeDrawable - ForgeMetalView: \(delegate?.label)")

        metalLayer.drawableSize = newSize

        delegate?.drawableResized(size: newSize, scaleFactor: newScaleFactor)

        render()
    }
}

#elseif os(iOS) || os(tvOS) || os(visionOS)

import Foundation
import QuartzCore
import UIKit

public class MetalView: UIView {
    public var isPaused: Bool {
        get {
            _displayLinkPaused
        }
        set {
            print("isPaused - ForgeMetalView: \(newValue)")
            if newValue {
                pauseRenderLoop()
            }
            else {
                resumeRenderLoop()
            }
        }
    }

    public var drawableSize: CGSize {
        metalLayer.drawableSize
    }

    weak var delegate: MetalViewRendererDelegate?

    public private(set) lazy var metalLayer: CAMetalLayer = self.layer as! CAMetalLayer

    private var _displayLinkPaused = false
    private var _displayLink: CADisplayLink?

    // MARK: - Init

    override public init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    // MARK: - Deinit

    deinit {
        print("deinit - ForgeMetalView")

        NotificationCenter.default.removeObserver(self)

        stopRenderLoop()
    }

    // MARK: - Layer

    override public class var layerClass: AnyClass {
        CAMetalLayer.self
    }

    // MARK: - Configure

    private func configure() {
        print("configure - ForgeMetalView")

        autoresizingMask = [.flexibleWidth, .flexibleHeight]

        metalLayer.delegate = self
    }

    // MARK: - Render

    @objc private func render() {
        delegate?.draw(metalLayer: metalLayer)
    }

    // MARK: - View Window Change

    override public func didMoveToWindow() {
        super.didMoveToWindow()

        print("didMoveToWindow - ForgeMetalView")

        guard let window = window else {
            cleanupRenderLoop()
            return
        }

        setupRenderLoop()

        resizeDrawable()
    }

    // MARK: - Render Loop

    private func setupRenderLoop() {
        print("setupRenderLoop - ForgeMetalView")

        cleanupRenderLoop()

        let displayLink = CADisplayLink(target: self, selector: #selector(render))
        displayLink.isPaused = _displayLinkPaused
        displayLink.preferredFramesPerSecond = 120
        displayLink.add(to: .main, forMode: .common)

        _displayLink = displayLink

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground(_:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground(_:)),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc func didEnterBackground(_ notification: Notification) {
        print("didEnterBackground - ForgeMetalView")

        _displayLink?.isPaused = true
    }

    @objc func willResignActive(_ notification: Notification) {
        print("willResignActive - ForgeMetalView")

        _displayLink?.isPaused = true
    }

    @objc func willEnterForeground(_ notification: Notification) {
        print("willEnterForeground - ForgeMetalView")

        _displayLink?.isPaused = _displayLinkPaused
    }

    private func stopRenderLoop() {
        guard _displayLink != nil else { return }

        print("stopRenderLoop - ForgeMetalView")

        cleanupRenderLoop()
    }

    func cleanupRenderLoop() {
        print("cleanupRenderLoop - ForgeMetalView")

        _displayLink?.isPaused = true
        _displayLink?.invalidate()
        _displayLink = nil
    }

    private func pauseRenderLoop() {
        print("pauseRenderLoop - ForgeMetalView")

        _displayLinkPaused = true
        _displayLink?.isPaused = true
    }

    private func resumeRenderLoop() {
        print("resumeRenderLoop - ForgeMetalView")

        _displayLinkPaused = false
        _displayLink?.isPaused = false
    }

    // MARK: - Event Based Rendering

    override public func display(_ layer: CALayer) {
        render()
    }

    override public func draw(_ layer: CALayer, in ctx: CGContext) {
        render()
    }

    override public func draw(_ rect: CGRect) {
        render()
    }

    // MARK: - Resize

    override public func layoutSubviews() {
        super.layoutSubviews()
        resizeDrawable()
    }

    override public var bounds: CGRect {
        get {
            super.bounds
        }
        set {
            super.bounds = newValue
            resizeDrawable()
        }
    }

    override public var frame: CGRect {
        get {
            super.frame
        }
        set {
            super.frame = newValue
            resizeDrawable()
        }
    }

    override public var contentScaleFactor: CGFloat {
        get {
            super.contentScaleFactor
        }
        set {
            super.contentScaleFactor = newValue
            resizeDrawable()
        }
    }

    private func resizeDrawable() {
        let newScaleFactor = contentScaleFactor
        var newSize = bounds.size

        newSize.width *= newScaleFactor
        newSize.height *= newScaleFactor

        guard newSize.width > 0, newSize.height > 0 else { return }

        guard newSize.height != metalLayer.drawableSize.height ||
            newSize.width != metalLayer.drawableSize.width else { return }

        print("resizeDrawable - ForgeMetalView")

        metalLayer.drawableSize = newSize

        delegate?.drawableResized(size: newSize, scaleFactor: newScaleFactor)

        render()
    }
}

#endif
