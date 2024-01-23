//
//  RayMarchingRendererView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Satin
import SwiftUI

struct RayMarchingRendererView: View {
    var body: some View {
        SatinMetalView(renderer: RayMarchingRenderer())
            .ignoresSafeArea()
            .navigationTitle("Ray Marching")
    }
}

struct RayMarchingRendererView_Previews: PreviewProvider {
    static var previews: some View {
        RayMarchingRendererView()
    }
}
