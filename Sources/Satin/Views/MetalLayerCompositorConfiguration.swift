//
//  MetalLayerCompositorConfiguration.swift
//
//
//  Created by Reza Ali on 1/23/24.
//

#if os(visionOS)

import CompositorServices
import SwiftUI

public struct MetalLayerCompositorConfiguration: CompositorLayerConfiguration {
    private let renderer: MetalLayerRenderer
    
    public init(renderer: MetalLayerRenderer) {
        self.renderer = renderer
    }

    public func makeConfiguration(capabilities: LayerRenderer.Capabilities, configuration: inout LayerRenderer.Configuration) {
        configuration.depthFormat = renderer.depthPixelFormat
        configuration.colorFormat = renderer.colorPixelFormat

        let foveationEnabled = capabilities.supportsFoveation
        configuration.isFoveationEnabled = foveationEnabled
        configuration.layout = .dedicated
    }
}

#endif
