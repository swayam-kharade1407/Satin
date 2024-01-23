//
//  InstancingRendererView.swift
//  Example
//
//  Created by Reza Ali on 8/17/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Satin
import SwiftUI

struct CustomInstancingRendererView: View {
    var body: some View {
        SatinMetalView(renderer: CustomInstancingRenderer())
            .ignoresSafeArea()
            .navigationTitle("Custom Instancing")
    }
}

struct CustomInstancingRendererView_Previews: PreviewProvider {
    static var previews: some View {
        CustomInstancingRendererView()
    }
}
