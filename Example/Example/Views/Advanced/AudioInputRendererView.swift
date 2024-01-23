//
//  AudioInputRendererView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

#if !os(visionOS)

import Satin
import SwiftUI

struct AudioInputRendererView: View {
    var body: some View {
        SatinMetalView(renderer: AudioInputRenderer())
            .ignoresSafeArea()
            .navigationTitle("Audio Input")
    }
}

struct AudioInputRendererView_Previews: PreviewProvider {
    static var previews: some View {
        AudioInputRendererView()
    }
}

#endif
