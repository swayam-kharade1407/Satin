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
    #if DEBUG && os(visionOS)
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView().preferredColorScheme(.dark)
        }

        #if os(visionOS)
        SatinImmersiveSpace(renderer: Immersive3DRenderer(), immersionStyle: .constant(.mixed))
        SatinImmersiveSpace(renderer: ImmersiveSuperShapesRenderer(), immersionStyle: .constant(.full))
        SatinImmersiveSpace(renderer: ImmersivePostRenderer(), immersionStyle: .constant(.full))
        #endif
    }
}
