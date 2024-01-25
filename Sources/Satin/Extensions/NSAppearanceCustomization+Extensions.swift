//
//  NSAppearanceCustomization+Extensions.swift
//
//
//  Created by Reza Ali on 1/24/24.
//

import Foundation

#if os(macOS)

import AppKit

extension NSAppearanceCustomization {
    // Runs the specified closure in the context of the receiver's effective
    // appearance. This enables retrieving system and asset catalog colors
    // with light or dark mode variations, among other things.
    func withEffectiveAppearance(_ closure: () -> ()) {
        if #available(macOS 11.0, *) {
            effectiveAppearance.performAsCurrentDrawingAppearance {
                closure()
            }
        } else {
            let previousAppearance = NSAppearance.current
            NSAppearance.current = effectiveAppearance
            defer {
                NSAppearance.current = previousAppearance
            }
            closure()
        }
    }
}

#endif
