//
//  ExampleApp.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Satin
import SwiftUI

#if canImport(CompositorServices)
// import CompositorServices
//

// struct ExampleSpace: Scene {
//    var body: some Scene {
//        ImmersiveSpace(id: "ImmersiveSpace", for: ExampleType.self) { type in
//            CompositorLayer(configuration: ForgeContentStageConfiguration()) { layerRenderer in
//                var renderer: Forge.Renderer
//
//                switch type.wrappedValue {
//                case .threed:
//                    renderer = Renderer3D(layerRenderer: layerRenderer)
//                case .supershapes:
//                    renderer = SuperShapesRenderer(layerRenderer: layerRenderer)
//                case .none:
//                    renderer = Renderer3D(layerRenderer: layerRenderer)
//                }
//
//                renderer
//                    .onDisappear {
//                        print("type: \(type.wrappedValue?.rawValue) onDisappear")
//                    }
//                    .startRenderLoop()
//            }
//        }
//        .immersionStyle(selection: .constant(.full), in: .full)
//    }
// }
#endif

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            #if os(visionOS)
            VisionsView()
            #else
            ContentView().preferredColorScheme(.dark)
            #endif
        }
        .commands {
            SidebarCommands()
        }

        #if os(visionOS)
        SatinImmersiveSpace(renderer: Immersive3DRenderer())
        SatinImmersiveSpace(renderer: ImmersiveSuperShapesRenderer())
        #endif
    }
}
