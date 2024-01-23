//
//  ForgeMetalViewController.swift
//  Forging
//
//  Created by Reza Ali on 1/21/24.
//

#if os(macOS)

import AppKit

public class MetalViewController: NSViewController {
    public var renderer: MetalViewRenderer?
    public private(set) var metalView = MetalView()

    override public var acceptsFirstResponder: Bool { return true }
    override public func becomeFirstResponder() -> Bool { return true }
    override public func resignFirstResponder() -> Bool { return true }

    private var trackingArea: NSTrackingArea?
    private var keyDownHandler: Any?
    private var keyUpHandler: Any?
    private var flagsChangedHandler: Any?

    // MARK: - Init

    init(renderer: MetalViewRenderer) {
        super.init(nibName: nil, bundle: nil)
        self.renderer = renderer
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init with Renderer")
    }

    // MARK: - Deinit

    deinit {
        print("deinit - ForgeMetalViewController: \(renderer?.label)")

        cleanupRenderer()
        removeTracking()
        removeEvents()
        metalView.delegate = nil
    }

    // MARK: - Load View

    override public func loadView() {
        print("loadView - ForgeMetalViewController: \(self.renderer?.label)")

        view = self.metalView
    }

    // MARK: - View Did Load

    override public func viewDidLoad() {
        super.viewDidLoad()

        print("viewDidLoad - ForgeMetalViewController: \(self.renderer?.label)")

        self.setupView()
        self.setupRenderer()

        self.setupEvents()
        self.setupTracking()
    }

    // MARK: - Setup View

    private func setupView() {
        guard let device = MTLCreateSystemDefaultDevice() else { return }

        print("setupView - ForgeMetalViewController: \(self.renderer?.label)")

        self.metalView.metalLayer.device = device
    }

    // MARK: - Renderer

    private func setupRenderer() {
        guard let device = metalView.metalLayer.device,
              let queue = device.makeCommandQueue(),
              let renderer = renderer, !renderer.isSetup
        else { return }

        print("setupRenderer - ForgeMetalViewController: \(renderer.label)")

        renderer.metalView = self.metalView
        renderer.device = device
        renderer.commandQueue = queue
        renderer.setup()
        renderer.isSetup = true

        self.updateAppearance()

        self.metalView.metalLayer.pixelFormat = renderer.colorPixelFormat
        self.metalView.delegate = renderer
    }

    private func cleanupRenderer() {
        guard let renderer = renderer, renderer.isSetup else { return }
        print("cleanupRenderer - ForgeMetalViewController: \(renderer.label)")
        renderer.cleanup()
        renderer.isSetup = false
    }

    // MARK: - Tracking

    private func setupTracking() {
        print("setupTracking - ForgeMetalViewController: \(self.renderer?.label)")
        let area = NSTrackingArea(rect: self.view.bounds, options: [.activeAlways, .mouseEnteredAndExited, .mouseMoved, .inVisibleRect], owner: self, userInfo: nil)
        self.view.addTrackingArea(area)
        self.trackingArea = area
    }

    private func removeTracking() {
        guard let trackingArea = trackingArea else { return }
        print("removeTracking - ForgeMetalViewController: \(self.renderer?.label)")
        self.view.removeTrackingArea(trackingArea)
        self.trackingArea = nil
        NSCursor.setHiddenUntilMouseMoves(false)
    }

    // MARK: - Events

    private func setupEvents() {
        print("setupEvents - ForgeMetalViewController: \(self.renderer?.label)")

        self.metalView.allowedTouchTypes = .indirect

        self.keyDownHandler = NSEvent.addLocalMonitorForEvents(
            matching: .keyDown,
            handler: { [weak self] event -> NSEvent? in
                self?.keyDown(with: event)
            }
        )

        self.keyUpHandler = NSEvent.addLocalMonitorForEvents(
            matching: .keyUp,
            handler: { [weak self] event -> NSEvent? in
                self?.keyUp(with: event)
            }
        )

        self.flagsChangedHandler = NSEvent.addLocalMonitorForEvents(
            matching: .flagsChanged,
            handler: { [weak self] event -> NSEvent? in
                self?.flagsChanged(with: event)
            }
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.updateAppearance),
            name: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
    }

    private func removeEvents() {
        print("removeEvents - ForgeMetalViewController: \(self.renderer?.label)")

        if let keyDownHandler = self.keyDownHandler {
            NSEvent.removeMonitor(keyDownHandler)
            self.keyDownHandler = nil
        }

        if let keyUpHandler = self.keyUpHandler {
            NSEvent.removeMonitor(keyUpHandler)
            self.keyUpHandler = nil
        }

        if let flagsChangedHandler = self.flagsChangedHandler {
            NSEvent.removeMonitor(flagsChangedHandler)
            self.flagsChangedHandler = nil
        }

        DistributedNotificationCenter.default.removeObserver(
            self,
            name: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
    }

    // MARK: - Appearance

    @objc private func updateAppearance() {
        guard let renderer = self.renderer else { return }

        print("updateAppearance - ForgeMetalViewController: \(renderer.label)")

        renderer.appearance = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" ? .dark : .light
    }

    // MARK: - Events

    override public func touchesBegan(with event: NSEvent) {
        guard let renderer = self.renderer, event.window == self.view.window else { return }

        renderer.touchesBegan(with: event)
    }

    override public func touchesEnded(with event: NSEvent) {
        guard let renderer = self.renderer, event.window == self.view.window else { return }

        renderer.touchesEnded(with: event)
    }

    override public func touchesMoved(with event: NSEvent) {
        guard let renderer = self.renderer, event.window == self.view.window else { return }

        renderer.touchesMoved(with: event)
    }

    override public func touchesCancelled(with event: NSEvent) {
        guard let renderer = self.renderer, event.window == self.view.window else { return }

        renderer.touchesCancelled(with: event)
    }

    override public func mouseMoved(with event: NSEvent) {
        guard let renderer = self.renderer, event.window == self.view.window else { return }

        renderer.mouseMoved(with: event)
    }

    override public func mouseDown(with event: NSEvent) {
        guard let renderer = self.renderer, event.window == self.view.window else { return }

        renderer.mouseDown(with: event)
    }

    override public func mouseDragged(with event: NSEvent) {
        guard let renderer = self.renderer, event.window == self.view.window else { return }

        renderer.mouseDragged(with: event)
    }

    override public func mouseUp(with event: NSEvent) {
        guard let renderer = self.renderer, event.window == self.view.window else { return }

        renderer.mouseUp(with: event)
    }

    override public func rightMouseDown(with event: NSEvent) {
        guard let renderer = self.renderer, event.window == self.view.window else { return }

        renderer.rightMouseDown(with: event)
    }

    override public func rightMouseDragged(with event: NSEvent) {
        guard let renderer = self.renderer, event.window == self.view.window else { return }

        renderer.rightMouseDragged(with: event)
    }

    override public func rightMouseUp(with event: NSEvent) {
        guard let renderer = self.renderer, event.window == self.view.window else { return }

        renderer.rightMouseUp(with: event)
    }

    override public func otherMouseDown(with event: NSEvent) {
        guard let renderer = self.renderer, event.window == self.view.window else { return }

        renderer.otherMouseDown(with: event)
    }

    override public func otherMouseDragged(with event: NSEvent) {
        guard let renderer = self.renderer, event.window == self.view.window else { return }

        renderer.otherMouseDragged(with: event)
    }

    override public func otherMouseUp(with event: NSEvent) {
        guard let renderer = self.renderer, event.window == self.view.window else { return }

        renderer.otherMouseUp(with: event)
    }

    override public func mouseEntered(with event: NSEvent) {
        guard let renderer = self.renderer, event.window == self.view.window else { return }

        renderer.mouseEntered(with: event)
    }

    override public func mouseExited(with event: NSEvent) {
        guard let renderer = self.renderer, event.window == self.view.window else { return }

        renderer.mouseExited(with: event)
    }

    override public func magnify(with event: NSEvent) {
        guard let renderer = self.renderer, event.window == self.view.window else { return }

        renderer.magnify(with: event)
    }

    override public func rotate(with event: NSEvent) {
        guard let renderer = self.renderer, event.window == self.view.window else { return }

        renderer.rotate(with: event)
    }

    override public func swipe(with event: NSEvent) {
        guard let renderer = self.renderer, event.window == self.view.window else { return }

        renderer.swipe(with: event)
    }

    override public func scrollWheel(with event: NSEvent) {
        guard let renderer = self.renderer, event.window == self.view.window else { return }
        renderer.scrollWheel(with: event)
    }

    public func keyDown(with event: NSEvent) -> NSEvent? {
        guard let renderer = self.renderer, event.window == self.view.window else { return event }
        renderer.keyDown(with: event)
        return event
    }

    public func keyUp(with event: NSEvent) -> NSEvent? {
        guard let renderer = self.renderer, event.window == self.view.window else { return event }
        renderer.keyUp(with: event)
        return event
    }

    private func flagsChanged(with event: NSEvent) -> NSEvent? {
        guard let renderer = self.renderer, event.window == metalView.window else { return event }
        renderer.flagsChanged(with: event)
        return event
    }
}

#elseif os(iOS) || os(tvOS) || os(visionOS)

import UIKit

public final class MetalViewController: UIViewController {
    public var renderer: MetalViewRenderer?
    public private(set) var metalView = MetalView()

    override public var shouldAutorotate: Bool { return true }

    // MARK: - Init

    public init(renderer: MetalViewRenderer?) {
        super.init(nibName: nil, bundle: nil)
        self.renderer = renderer
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init with Renderer")
    }

    // MARK: - Deinit

    deinit {
        print("deinit - ForgeMetalViewController: \(renderer?.label)")

        cleanupRenderer()
        removeEvents()
        metalView.delegate = nil
    }

    // MARK: - Load View

    override public func loadView() {
        print("loadView - ForgeMetalViewController: \(self.renderer?.label)")
        view = self.metalView
        view.isMultipleTouchEnabled = true
    }

    // MARK: - View Did Load

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
        self.setupRenderer()
        self.setupEvents()
    }

    // MARK: - Setup View

    private func setupView() {
        guard let device = MTLCreateSystemDefaultDevice() else { return }

        print("setupView - ForgeMetalViewController: \(self.renderer?.label)")

        self.metalView.metalLayer.device = device
    }

    // MARK: - Renderer

    private func setupRenderer() {
        guard let device = metalView.metalLayer.device,
              let queue = device.makeCommandQueue(),
              let renderer = renderer, !renderer.isSetup
        else { return }

        print("setupRenderer - ForgeMetalViewController: \(renderer.label)")

        renderer.metalView = self.metalView
        renderer.device = device
        renderer.commandQueue = queue
        renderer.setup()
        renderer.isSetup = true
#if !os(visionOS)
        self.updateAppearance()
#endif
        self.metalView.metalLayer.pixelFormat = renderer.colorPixelFormat
        self.metalView.delegate = renderer
    }

    private func cleanupRenderer() {
        guard let renderer = renderer, renderer.isSetup else { return }

        print("cleanupRenderer - ForgeMetalViewController: \(renderer.label)")

        renderer.cleanup()
        renderer.isSetup = false
    }

    // MARK: - Events

    private func setupEvents() {
        print("setupEvents - ForgeMetalViewController: \(self.renderer?.label)")
#if !os(visionOS)
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitActiveAppearance.self], action: #selector(self.updateAppearance))
        }
#endif
    }

#if !os(visionOS)
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17, tvOS 17) {
            if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
                self.updateAppearance()
            }
        }
    }
#endif

#if !os(visionOS)
    @objc private func updateAppearance() {
        guard let renderer = renderer, renderer.isSetup else { return }

        print("updateAppearance - ForgeMetalViewController: \(renderer.label)")

        if self.traitCollection.userInterfaceStyle == .dark {
            renderer.appearance = .dark
        }
        else if self.traitCollection.userInterfaceStyle == .light {
            renderer.appearance = .light
        }
        else if self.traitCollection.userInterfaceStyle == .unspecified {
            renderer.appearance = .unknown
        }
    }
#endif

    private func removeEvents() {
        print("removeEvents - ForgeMetalViewController: \(self.renderer?.label)")
    }

    // MARK: - Events

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let renderer = self.renderer else { return }
        renderer.touchesBegan(touches, with: event)
    }

    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let renderer = self.renderer else { return }
        renderer.touchesMoved(touches, with: event)
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let renderer = self.renderer else { return }
        renderer.touchesEnded(touches, with: event)
    }

    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let renderer = self.renderer else { return }
        renderer.touchesCancelled(touches, with: event)
    }
}

#endif
