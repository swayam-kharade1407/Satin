//
//  DisclosureButton.swift
//  YouiTwo
//
//  Created by Reza Ali on 2/2/21.
//

import Foundation

#if os(iOS)

import UIKit

final class DisclosureButton: UIButton {
    var value: Bool = true {
        didSet {
            updateState()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    init() {
        super.init(frame: CGRect())
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        addAction(UIAction(handler: { [weak self] _ in
            guard let self else { return }
            self.value = !self.value
            self.updateState()
        }), for: .touchUpInside)
        updateState()
        tintColor = UIColor(named: "Disclosure", in: Bundle(for: DisclosureButton.self), compatibleWith: nil)
    }

    func updateState() {
        layer.transform = CATransform3DMakeRotation(value ? .pi * 0.5 : 0.0, 0, 0, 1)
    }
}

#endif
