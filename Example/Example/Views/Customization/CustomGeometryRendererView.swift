//
//  Renderer2DView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Satin
import SwiftUI

struct CustomGeometryRendererView: View {
    var body: some View {
        SatinMetalView(renderer: CustomGeometryRenderer())
            .ignoresSafeArea()
            .navigationTitle("Custom Geometry")
    }
}

struct CustomGeometryRendererView_Previews: PreviewProvider {
    static var previews: some View {
        CustomGeometryRendererView()
    }
}
