//
//  ExampleApp.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Satin
import SwiftUI

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
//            #if os(visionOS)
//            VisionsView()
//            #else
            ContentView().preferredColorScheme(.dark)
//            #endif
        }


        #if os(visionOS)
        SatinImmersiveSpace(renderer: Immersive3DRenderer())
        SatinImmersiveSpace(renderer: ImmersiveSuperShapesRenderer())
        #endif
    }
}
