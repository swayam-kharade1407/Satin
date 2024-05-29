//
//  SquircleGeometry.swift
//  Satin
//
//  Created by Reza Ali on 8/3/20.
//

#if SWIFT_PACKAGE
import SatinCore
#endif

public final class SquircleGeometry: SatinGeometry {
    var size: Float = 2.0
    var radius: Float = 4.0
    var angularResolution: Int = 90
    var radialResolution: Int = 20

    public init(size: Float, radius: Float, angularResolution: Int, radialResolution: Int) {
        self.size = size
        self.radius = radius
        self.angularResolution = angularResolution
        self.radialResolution = radialResolution
        super.init()
    }

    public override func generateGeometryData() -> GeometryData {
        generateSquircleGeometryData(size, radius, Int32(angularResolution), Int32(radialResolution))
    }
}
