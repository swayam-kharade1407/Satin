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
import Youi

#if os(macOS)
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

    // MARK: - UI

#if !os(visionOS)
    var inspectorWindow: InspectorWindow?
    var _updateInspector: Bool = true
#endif

    // MARK: - Parameters

    var paramKeys: [String] {
        return []
    }

    var params: [String: ParameterGroup?] {
        return [:]
    }
#if !os(visionOS)
    override func preDraw() -> MTLCommandBuffer? {
        updateInspector()
        return super.preDraw()
    }
#endif
    
    override func cleanup() {
        super.cleanup()
        print("cleanup: \(String(describing: type(of: self)))")
#if os(macOS)
        inspectorWindow?.setIsVisible(false)
#endif
    }

    deinit {
        print("\ndeinit: \(String(describing: type(of: self)))\n")
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

    override func keyDown(with event: NSEvent) {
        if event.characters == "e" {
            openEditor()
        }
    }
#endif
}

#if !os(visionOS)

import Foundation
import Satin
import Youi

extension BaseRenderer {
    func setupInspector() {
        guard !paramKeys.isEmpty else { return }

        var panelOpenStates: [String: Bool] = [:]
        if let inspectorWindow = inspectorWindow, let inspector = inspectorWindow.inspectorViewController {
            let panels = inspector.getPanels()
            for panel in panels {
                if let label = panel.title {
                    panelOpenStates[label] = panel.open
                }
            }
        }

        if inspectorWindow == nil {
#if os(macOS)
            let inspectorWindow = InspectorWindow("Inspector")
            inspectorWindow.setIsVisible(true)
#elseif os(iOS)
            let inspectorWindow = InspectorWindow("Inspector", edge: .right)
            metalView.addSubview(inspectorWindow.view)
#endif
            self.inspectorWindow = inspectorWindow
        }

        if let inspectorWindow = inspectorWindow, let inspectorViewController = inspectorWindow.inspectorViewController {
            if inspectorViewController.getPanels().count > 0 {
                inspectorViewController.removeAllPanels()
            }

            updateUI(inspectorViewController)

            let panels = inspectorViewController.getPanels()
            for panel in panels {
                if let label = panel.title {
                    if let open = panelOpenStates[label] {
                        panel.open = open
                    }
                }
            }
        }
    }

    func updateUI(_ inspectorViewController: InspectorViewController) {
        let paramters = params
        for key in paramKeys {
            if let param = paramters[key], let p = param {
                let panel = PanelViewController(key, parameters: p)
                inspectorViewController.addPanel(panel)
            }
        }
    }

    func updateInspector() {
        if _updateInspector {
            DispatchQueue.main.async { [weak self] in
                self?.setupInspector()
            }
            _updateInspector = false
        }
    }
}

#endif
