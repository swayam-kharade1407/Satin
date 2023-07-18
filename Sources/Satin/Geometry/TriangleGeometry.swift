//
//  TriangleGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/6/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import SatinCore

public final class TriangleGeometry: SatinGeometry {
    var size: Float {
        didSet {
            if oldValue != size {
                _updateGeometryData = true
            }
        }
    }

    public init(size: Float = 1) {
        self.size = size
        super.init()
    }

    public override func generateGeometryData() -> GeometryData {
        generateTriangleGeometryData(size)
    }
}
