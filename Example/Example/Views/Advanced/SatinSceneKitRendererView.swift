//
//  SatinSceneKitRendererView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Satin
import SwiftUI

struct SatinSceneKitRendererView: View {
    var body: some View {
        SatinMetalView(renderer: SatinSceneKitRenderer())
            .ignoresSafeArea()
            .navigationTitle("Satin + SceneKit")
    }
}

struct SatinSceneKitRendererView_Previews: PreviewProvider {
    static var previews: some View {
        SatinSceneKitRendererView()
    }
}
