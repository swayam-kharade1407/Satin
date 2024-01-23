//
//  FXAARendererView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Satin
import SwiftUI

struct FXAARendererView: View {
    var body: some View {
        SatinMetalView(renderer: FXAARenderer())
            .ignoresSafeArea()
            .navigationTitle("FXAA")
    }
}

struct FXAARendererView_Previews: PreviewProvider {
    static var previews: some View {
        FXAARendererView()
    }
}
