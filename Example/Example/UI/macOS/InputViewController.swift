//
//  InputViewController.swift
//  Youi-macOS
//
//  Created by Reza Ali on 5/4/20.
//

#if os(macOS)

import AppKit

public class InputViewController: NSViewController {
    override public func viewWillDisappear() {
        deactivate()
    }

    public func deactivate() {
        if let window = view.window {
            window.makeFirstResponder(nil)
        }
    }

    public func deactivateAsync() {
        if let window = view.window {
            DispatchQueue.main.async { // omg
                window.makeFirstResponder(nil)
            }
        }
    }
}

#endif
