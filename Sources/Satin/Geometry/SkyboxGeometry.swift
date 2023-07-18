//
//  SkyboxGeometry.swift
//  Satin
//
//  Created by Reza Ali on 4/16/20.

import SatinCore

public final class SkyboxGeometry: SatinGeometry {
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

    override public func generateGeometryData() -> GeometryData {
        generateSkyboxGeometryData(size)
    }
}
