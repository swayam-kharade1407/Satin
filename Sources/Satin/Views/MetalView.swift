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
#if DEBUG
            print("isPaused - ForgeMetalView: \(newValue)")
#endif
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
#if DEBUG
        print("\ndeinit - ForgeMetalView: \(delegate?.id)\n")
#endif
        stopRenderLoop()
    }

    // MARK: - Layer

    override public func makeBackingLayer() -> CALayer {
        CAMetalLayer()
    }

    // MARK: - Configure

    private func configure() {
#if DEBUG
        print("\n\n\nconfigure - ForgeMetalView: \(delegate?.id)")
#endif
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

        if let window = window {
#if DEBUG
            print("viewDidMoveToWindow - ForgeMetalView: \(delegate?.id), \(window)")
#endif
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
#if DEBUG
        print("setupRenderLoop - ForgeMetalView: \(delegate?.id)")
#endif
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
#if DEBUG
            print("pauseRenderLoop - ForgeMetalView: \(delegate?.id)")
#endif
            CVDisplayLinkStop(displayLink)
        }

        _displayLinkPaused = true
    }

    private func resumeRenderLoop() {
        if let displayLink = _displayLink, _displayLinkPaused {
#if DEBUG
            print("resumeRenderLoop - ForgeMetalView: \(delegate?.id)")
#endif
            CVDisplayLinkStart(displayLink)
        }

        _displayLinkPaused = false
    }

    func stopRenderLoop() {
        guard _displayLink != nil else { return }
#if DEBUG
        print("stopRenderLoop - ForgeMetalView: \(delegate?.id)")
#endif
        pauseRenderLoop()

        _displayLink = nil

        _displaySource?.cancel()
        _displaySource = nil
    }

    @objc func windowWillClose(_ notification: Notification) {
        guard notification.object as AnyObject? === window else { return }
#if DEBUG
        print("windowWillClose - ForgeMetalView: \(delegate?.id)")
#endif
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
#if DEBUG
        print("resizeDrawable - ForgeMetalView: \(delegate?.id)")
#endif
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
#if DEBUG
            print("set(isPaused) - ForgeMetalView: \(delegate?.id) - isPaused: \(newValue)")
#endif
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

    public var preferredFramesPerSecond: Int = 120 {
        didSet {
            if #available(iOS 15.0, *) {
                _displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: Float(preferredFramesPerSecond))
            }
            else {
                _displayLink?.preferredFramesPerSecond = preferredFramesPerSecond
            }
        }
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
#if DEBUG
        print("\ndeinit - ForgeMetalView: \(delegate?.id)\n")
#endif
        NotificationCenter.default.removeObserver(self)

        stopRenderLoop()
    }

    // MARK: - Layer

    override public class var layerClass: AnyClass {
        CAMetalLayer.self
    }

    // MARK: - Configure

    private func configure() {
#if DEBUG
        print("configure - ForgeMetalView: \(delegate?.id)")
#endif
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
#if DEBUG
        print("didMoveToWindow - ForgeMetalView: \(delegate?.id), - window: \(window)")
#endif
        if window != nil {
            setupRenderLoop()
            resizeDrawable()
        }
        else {
            stopRenderLoop()
        }
    }

    // MARK: - Render Loop

    private func setupRenderLoop() {
#if DEBUG
        print("setupRenderLoop - ForgeMetalView: \(delegate?.id)")
#endif
        _displayLink?.isPaused = true
        _displayLink?.invalidate()
        _displayLink = nil

        let displayLink = CADisplayLink(target: self, selector: #selector(render))
        displayLink.isPaused = _displayLinkPaused
        displayLink.preferredFramesPerSecond = preferredFramesPerSecond
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
#if DEBUG
        print("didEnterBackground - ForgeMetalView: \(delegate?.id)")
#endif
        _displayLink?.isPaused = true
    }

    @objc func willResignActive(_ notification: Notification) {
#if DEBUG
        print("willResignActive - ForgeMetalView: \(delegate?.id)")
#endif
        _displayLink?.isPaused = true
    }

    @objc func willEnterForeground(_ notification: Notification) {
#if DEBUG
        print("willEnterForeground - ForgeMetalView: \(delegate?.id)")
#endif
        _displayLink?.isPaused = _displayLinkPaused
    }

    private func stopRenderLoop() {
        guard _displayLink != nil else { return }
#if DEBUG
        print("stopRenderLoop - ForgeMetalView: \(delegate?.id)")
#endif
        _displayLink?.isPaused = true
        _displayLink?.invalidate()
        _displayLink = nil
    }

    private func pauseRenderLoop() {
#if DEBUG
        print("pauseRenderLoop - ForgeMetalView: \(delegate?.id)")
#endif
        _displayLinkPaused = true
        _displayLink?.isPaused = true
    }

    private func resumeRenderLoop() {
#if DEBUG
        print("resumeRenderLoop - ForgeMetalView: \(delegate?.id)")
#endif
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
#if DEBUG
        print("resizeDrawable - ForgeMetalView: \(delegate?.id)")
#endif
        metalLayer.drawableSize = newSize

        delegate?.drawableResized(size: newSize, scaleFactor: newScaleFactor)

        render()
    }
}

#endif
