//
//  BaseRenderer.swift
//  Example
//
//  Created by Reza Ali on 3/22/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Foundation
import Metal
import Satin

#if canImport(AppKit)
import AppKit
#endif

class BaseRenderer: MetalViewRenderer {
    // MARK: - Paths

    var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    var sharedAssetsURL: URL { assetsURL.appendingPathComponent("Shared") }
    var rendererAssetsURL: URL { assetsURL.appendingPathComponent(String(describing: type(of: self))) }
    var dataURL: URL { rendererAssetsURL.appendingPathComponent("Data") }
    var pipelinesURL: URL { rendererAssetsURL.appendingPathComponent("Pipelines") }
    var texturesURL: URL { rendererAssetsURL.appendingPathComponent("Textures") }
    var modelsURL: URL { rendererAssetsURL.appendingPathComponent("Models") }

    // MARK: - Parameters

    var paramKeys: [String] {
        return []
    }

    var params: [String: ParameterGroup?] {
        return [:]
    }

#if os(macOS)
    func openEditor() {
        if let editorUrl = UserDefaults.standard.url(forKey: "Editor") {
            NSWorkspace.shared.open([assetsURL], withApplicationAt: editorUrl, configuration: .init(), completionHandler: nil)
        } else {
            let openPanel = NSOpenPanel()
            openPanel.canChooseFiles = true
            openPanel.allowsMultipleSelection = false
            openPanel.canCreateDirectories = false
            openPanel.begin { [unowned self] (result: NSApplication.ModalResponse) in
                if result == .OK {
                    if let editorUrl = openPanel.url {
                        UserDefaults.standard.set(editorUrl, forKey: "Editor")
                        self.openEditor()
                    }
                }
                openPanel.close()
            }
        }
    }

    override func keyDown(with event: NSEvent) -> Bool {
        if event.characters == "e" {
            openEditor()
            return true
        }
        return false
    }
#endif
}
