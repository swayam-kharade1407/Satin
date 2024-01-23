//
//  Renderer2DView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Satin
import SwiftUI

struct ExportGeometryRendererView: View {
    var body: some View {
        SatinMetalView(renderer: ExportGeometryRenderer())
            .ignoresSafeArea()
            .navigationTitle("Export Geometry")
    }
}

struct ExportGeometryRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ExportGeometryRendererView()
    }
}
