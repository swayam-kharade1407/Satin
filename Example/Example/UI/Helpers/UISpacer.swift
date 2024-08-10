//
//  Spacer.swift
//  Slate macOS
//
//  Created by Reza Ali on 3/20/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

#if os(macOS)
import Cocoa

final class UISpacer: NSView {
    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        self.setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    func setup() {
        wantsLayer = true
    }

    public override func updateLayer() {
        super.updateLayer()
        layer?.backgroundColor = NSColor(named: "Spacer", bundle: Bundle(for: UISpacer.self))?.cgColor
    }
}

#elseif os(iOS)

import UIKit

final class UISpacer: UIView {
    public init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        self.backgroundColor = UIColor(named: "Spacer", in: Bundle(for: UISpacer.self), compatibleWith: nil)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.backgroundColor = UIColor(named: "Spacer", in: Bundle(for: UISpacer.self), compatibleWith: nil)
    }
}

#endif
