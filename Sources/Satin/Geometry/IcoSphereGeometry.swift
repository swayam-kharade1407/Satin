//
//  IcoSphereGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/11/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import SatinCore

public final class IcoSphereGeometry: SatinGeometry {
    public var radius: Float = 1 {
        didSet {
            if oldValue != radius {
                _updateGeometryData = true
            }
        }
    }

    public var resolution: Int = 1 {
        didSet {
            if oldValue != resolution {
                _updateGeometryData = true
            }
        }
    }

    public init(radius: Float, resolution: Int) {
        self.radius = radius
        self.resolution = resolution
        super.init()
    }

    public override func generateGeometryData() -> GeometryData {
        generateIcoSphereGeometryData(radius, Int32(self.resolution))
    }
}
