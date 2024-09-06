//
//  ControlViewController.swift
//  Slate macOS
//
//  Created by Reza Ali on 3/14/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import Combine
import Satin

#if os(macOS)

import AppKit

public class ControlViewController: InputViewController {
    public weak var parameters: ParameterGroup? {
        didSet {
            setupParameterGroupSubscriptions()
        }
    }

    public var controls: [NSViewController] = []
    public var stack: NSStackView?

    internal var parameterGroupSubscriptions = Set<AnyCancellable>()

    public convenience init(_ parameters: ParameterGroup) {
        self.init()
        self.parameters = parameters
        setupParameterGroupSubscriptions()
    }

    open func setupView() {
        view = NSView()
        view.wantsLayer = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer?.backgroundColor = .clear
    }

    open func setupStackView() {
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
        self.stack = stack
    }

    open func addControl(_ control: NSViewController) {
        guard !controls.contains(control), let stack = stack else { return }
        stack.addView(control.view, in: .top)
        control.view.leadingAnchor.constraint(equalTo: stack.leadingAnchor).isActive = true
        control.view.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        controls.append(control)
    }

    open func addSpacer() {
        guard let stack = stack else { return }
        let spacer = UISpacer()
        stack.addView(spacer, in: .top)
        spacer.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }

    deinit {
        removeAll()
    }
}

#else

import UIKit

open class ControlViewController: UIViewController {
    public weak var parameters: ParameterGroup? {
        didSet {
            setupParameterGroupSubscriptions()
        }
    }

    public var controls: [UIViewController] = []
    public var stack: UIStackView?

    internal var parameterGroupSubscriptions = Set<AnyCancellable>()

    public convenience init(_ parameters: ParameterGroup) {
        self.init()
        self.parameters = parameters
        setupParameterGroupSubscriptions()
    }

    func setupView() {
        view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        view.widthAnchor.constraint(greaterThanOrEqualToConstant: 240).isActive = true
    }

    func setupStackView() {
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
        self.stack = stack
    }

    func addControl(_ control: UIViewController) {
        guard let stack else { return }

        stack.addArrangedSubview(control.view)

        control.view.leadingAnchor.constraint(equalTo: stack.leadingAnchor).isActive = true
        control.view.trailingAnchor.constraint(equalTo: stack.trailingAnchor).isActive = true

        controls.append(control)
    }

    func addSpacer() {
        guard let stack else { return }

        let spacer = UISpacer()
        stack.addArrangedSubview(spacer)

        spacer.heightAnchor.constraint(equalToConstant: 1).isActive = true
        spacer.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    }

    deinit {
        removeAll()
        parameters = nil
        stack = nil
    }
}

#endif
