//
//  QuadGeometry.swift
//  Satin
//
//  Created by Reza Ali on 3/19/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import SatinCore

public final class QuadGeometry: SatinGeometry {
    public var size: Float {
        didSet {
            if oldValue != size {
                _updateGeometryData = true
            }
        }
    }

    public init(size: Float = 2) {
        self.size = size
        super.init()
    }

    public override func generateGeometryData() -> GeometryData {
        generateQuadGeometryData(size)
    }
}
