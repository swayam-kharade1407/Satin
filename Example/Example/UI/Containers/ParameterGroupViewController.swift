//
//  PanelViewController.swift
//  Slate macOS
//
//  Created by Reza Ali on 3/14/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import Satin

#if os(macOS)

import AppKit

public protocol ParameterGroupViewControllerDelegate: AnyObject {
    func onPanelOpen(panel: ParameterGroupViewController)
    func onPanelClose(panel: ParameterGroupViewController)
    func onPanelResized(panel: ParameterGroupViewController)
    func onPanelRemove(panel: ParameterGroupViewController)
}

public final class ParameterGroupViewController: ControlViewController {
    public var open: Bool = false {
        didSet {
            updateState()
        }
    }

    public var vStack: NSStackView?
    public var hStack: NSStackView?
    public var button: NSButton?
    public var label: NSTextField?

    override public var title: String? {
        didSet {
            if let title = title {
                label?.stringValue = title
            }
        }
    }

    public weak var delegate: ParameterGroupViewControllerDelegate?

    public convenience init(_ title: String, parameters: ParameterGroup) {
        self.init()
        self.title = title
        self.parameters = parameters
        setupParameterGroupSubscriptions()
    }

    public func setupVerticalStackView() {
        let stack = NSStackView()
        stack.wantsLayer = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.spacing = 0
        stack.distribution = .equalSpacing
        view.addSubview(stack)
        stack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stack.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        stack.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        view.heightAnchor.constraint(equalTo: stack.heightAnchor).isActive = true
        vStack = stack
    }

    public func setupHorizontalStackView() {
        guard let vStack = vStack else { return }
        let hStack = NSStackView()
        hStack.wantsLayer = true
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.orientation = .horizontal
        hStack.spacing = 4
        hStack.alignment = .centerY
        hStack.distribution = .gravityAreas
        vStack.addView(hStack, in: .center)
        hStack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        hStack.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        hStack.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -16).isActive = true
        hStack.heightAnchor.constraint(equalToConstant: 42).isActive = true
        self.hStack = hStack
    }

    public func setupDisclosureButton() {
        guard let hStack = hStack else { return }
        let button = NSButton()
        button.wantsLayer = true
        button.bezelStyle = .disclosure
        button.title = ""
        button.setButtonType(.onOff)
        button.state = .on
        button.target = self
        button.action = #selector(ParameterGroupViewController.onButtonChange)
        button.translatesAutoresizingMaskIntoConstraints = false
        hStack.addView(button, in: .leading)
        self.button = button
    }

    public func setupLabel() {
        guard let hStack = hStack else { return }
        let label = NSTextField()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.wantsLayer = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        label.stringValue = title ?? "Panel"
        hStack.addView(label, in: .leading)
        self.label = label
    }

    public func setupSpacer() {
        guard let vStack = vStack else { return }
        let spacer = UISpacer()
        vStack.addView(spacer, in: .bottom)
        spacer.heightAnchor.constraint(equalToConstant: 1).isActive = true
        spacer.widthAnchor.constraint(equalTo: vStack.widthAnchor).isActive = true
    }

    override public func setupStackView() {
        guard let vStack = vStack else { return }
        let stack = NSStackView()
        stack.wantsLayer = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        vStack.addView(stack, in: .bottom)
        stack.orientation = .vertical
        stack.distribution = .gravityAreas
        stack.spacing = 0
        stack.widthAnchor.constraint(equalTo: vStack.widthAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: stack.bottomAnchor).isActive = true
        self.stack = stack
    }

    public func setupContainer() {
        setupDisclosureButton()
        setupLabel()
    }

    override public func loadView() {
        setupView()
        setupVerticalStackView()
        setupSpacer()
        setupHorizontalStackView()
        setupContainer()
        setupStackView()
        setupParameters()
        updateState()
    }

    @objc public func onButtonChange() {
        if let button = button, button.state == .off {
            open = false
        }
        else {
            open = true
        }
    }

    public func _close() {
        if let button = button {
            button.state = .off
        }

        if let vStack = vStack, let stack = stack {
            if vStack.views.contains(stack) {
                vStack.removeView(stack)
            }
        }

        delegate?.onPanelClose(panel: self)
    }

    public func _open() {
        if let button = button {
            button.state = .on
        }

        if let vStack = vStack, let stack = stack {
            if !vStack.views.contains(stack) {
                vStack.addView(stack, in: .bottom)
                stack.widthAnchor.constraint(equalTo: vStack.widthAnchor).isActive = true
            }
        }

        delegate?.onPanelOpen(panel: self)
    }

    override public func viewDidLayout() {
        super.viewDidLayout()
        delegate?.onPanelResized(panel: self)
    }

    private func updateState() {
        if open {
            _open()
        }
        else {
            _close()
        }
    }

    deinit {
        parameters = nil
        stack = nil
    }
}

#elseif os(iOS)

import UIKit

public final class ParameterGroupViewController: ControlViewController, ParameterGroupHeaderViewControllerDelegate {
    var header: ParameterGroupHeaderViewController?
    var vStack: UIStackView?
    var hStack: UIStackView?

    override public var title: String? {
        didSet {
            header?.title = title
        }
    }

    public var open: Bool = false {
        didSet {
            updateState()
        }
    }

    public convenience init(_ title: String, parameters: ParameterGroup) {
        self.init(parameters)
        self.title = title
    }

    override public func loadView() {
        setupView()
        setupVerticalStackView()
        setupHeader()
        setupStackView()
        setupParameters()
    }

    func setupVerticalStackView() {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 0
        stack.alignment = .center
        stack.distribution = .fillProportionally
        view.addSubview(stack)
        stack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stack.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        stack.heightAnchor.constraint(equalTo: view.heightAnchor, constant: 0).isActive = true
        stack.widthAnchor.constraint(equalTo: view.widthAnchor, constant: 0).isActive = true
        vStack = stack
    }

    func setupHeader() {
        guard let title = title, let vStack = vStack else { return }
        let header = ParameterGroupHeaderViewController(title, open)
        header.delegate = self
        vStack.addArrangedSubview(header.view)
        header.view.widthAnchor.constraint(equalTo: vStack.widthAnchor).isActive = true
        self.header = header
    }

    override func setupStackView() {
        guard let vStack = vStack else { return }
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 0
        stack.alignment = .center
        stack.isHidden = !open
        vStack.addArrangedSubview(stack)
        stack.widthAnchor.constraint(equalTo: vStack.widthAnchor, constant: 0).isActive = true
        self.stack = stack
    }

    func onOpen(header: ParameterGroupHeaderViewController) {
        open = true
    }

    func onClose(header: ParameterGroupHeaderViewController) {
        open = false
    }

    func updateState() {
        if let stack {
            stack.isHidden = !open
        }

        if let header = header {
            header.state = open
        }
    }

    func isOpen() -> Bool {
        return open
    }

    func setState(_ open: Bool) {
        self.open = open
    }

    deinit {
        header = nil
        vStack = nil
    }
}

#endif
