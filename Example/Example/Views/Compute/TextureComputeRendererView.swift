//
//  TextureComputeRendererView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Satin
import SwiftUI

struct TextureComputeRendererView: View {
    var body: some View {
        SatinMetalView(renderer: TextureComputeRenderer())
            .ignoresSafeArea()
            .navigationTitle("Texture Compute")
    }

}

struct TextureComputeRendererView_Previews: PreviewProvider {
    static var previews: some View {
        TextureComputeRendererView()
    }
}
