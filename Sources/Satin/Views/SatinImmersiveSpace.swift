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
    private var renderer: MetalLayerRenderer

    public var body: some SwiftUI.Scene {
        ImmersiveSpace(id: renderer.label) {
            CompositorLayer(configuration: MetalLayerCompositorConfiguration(renderer: renderer)) { layerRenderer in

                renderer.layerRenderer = layerRenderer

                guard let queue = layerRenderer.device.makeCommandQueue() else {
                    fatalError("MTLDevice failed to create command queue")
                }

                renderer.device = layerRenderer.device
                renderer.commandQueue = queue
                renderer.worldTracking = WorldTrackingProvider()
                renderer.arSession = ARKitSession()
                renderer.setup()
                renderer.isSetup = true
                renderer.startRenderLoop()
            }
        }.immersionStyle(selection: .constant(.full), in: .full)
    }
}

#endif
