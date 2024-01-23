//
//  TessellationRendererView.swift
//  Example
//
//  Created by Reza Ali on 4/2/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Satin
import SwiftUI

struct TessellationRendererView: View {
    var body: some View {
        SatinMetalView(renderer: TessellationRenderer())
            .ignoresSafeArea()
            .navigationTitle("Tessellation")
    }
}

struct TessellationRendererView_Previews: PreviewProvider {
    static var previews: some View {
        TessellationRendererView()
    }
}
