//
//  OcclusionRendererView.swift
//  Example
//
//  Created by Reza Ali on 1/13/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Satin
import SwiftUI

struct OcclusionRendererView: View {
    var body: some View {
        SatinMetalView(renderer: OcclusionRenderer())
            .ignoresSafeArea()
            .navigationTitle("Occlusion Material")
    }
}

struct OcclusionRendererView_Previews: PreviewProvider {
    static var previews: some View {
        OcclusionRendererView()
    }
}
