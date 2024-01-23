//
//  BufferComputeRendererView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Satin
import SwiftUI

struct BufferComputeRendererView: View {
    var body: some View {
        SatinMetalView(renderer: BufferComputeRenderer())
            .ignoresSafeArea()
            .navigationTitle("Buffer Compute")
    }
}

struct BufferComputeRendererView_Previews: PreviewProvider {
    static var previews: some View {
        BufferComputeRendererView()
    }
}
