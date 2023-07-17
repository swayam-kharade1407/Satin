//
//  BufferGeometryRendererView.swift
//  Example
//
//  Created by Reza Ali on 7/13/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Forge
import SwiftUI

struct BufferGeometryRendererView: View {
    var body: some View {
        ForgeView(renderer: BufferGeometryRenderer())
            .ignoresSafeArea()
            .navigationTitle("Buffer Geometry")
    }
}

struct BufferGeometryRendererView_Previews: PreviewProvider {
    static var previews: some View {
        BufferGeometryRendererView()
    }
}
