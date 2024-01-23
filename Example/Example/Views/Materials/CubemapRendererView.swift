//
//  CubemapRendererView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Satin
import SwiftUI

struct CubemapRendererView: View {
    var body: some View {
        SatinMetalView(renderer: CubemapRenderer())
            .ignoresSafeArea()
            .navigationTitle("Cubemap")
    }
}

struct CubemapRendererView_Previews: PreviewProvider {
    static var previews: some View {
        CubemapRendererView()
    }
}
