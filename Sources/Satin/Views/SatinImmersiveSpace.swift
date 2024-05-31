//
//  SatinImmersiveSpace.swift
//
//
//  Created by Reza Ali on 1/23/24.
//

#if os(visionOS)

import CompositorServices
import Foundation
import SwiftUI

public struct SatinImmersiveSpace: SwiftUI.Scene {
    private let renderer: MetalLayerRenderer

    public init(renderer: MetalLayerRenderer) {
        self.renderer = renderer
    }

    public var body: some SwiftUI.Scene {
        ImmersiveSpace(id: renderer.id) {
            CompositorLayer(configuration: renderer) { layerRenderer in

                guard let queue = layerRenderer.device.makeCommandQueue() else { fatalError("MTLDevice failed to create command queue") }

                renderer.layerRenderer = layerRenderer
                renderer.device = layerRenderer.device
                renderer.commandQueue = queue
                if !renderer.isSetup {
                    renderer.setup()
                    renderer.isSetup = true
                    renderer.startARSession()
                }
                renderer.startRenderLoop()
            }
        }.immersionStyle(selection: .constant(.full), in: .full)
    }
}

#endif
