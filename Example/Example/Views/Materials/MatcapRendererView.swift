//
//  Renderer2DView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Satin
import SwiftUI

struct MatcapRendererView: View {
    var body: some View {
        SatinMetalView(renderer: MatcapRenderer())
            .ignoresSafeArea()
            .navigationTitle("Matcap")
    }
}

struct MatcapRendererView_Previews: PreviewProvider {
    static var previews: some View {
        MatcapRendererView()
    }
}
