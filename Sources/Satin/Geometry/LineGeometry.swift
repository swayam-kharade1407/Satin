//
//  LineGeometry.swift
//  
//
//  Created by Reza Ali on 7/20/23.
//

#if SWIFT_PACKAGE
import SatinCore
#endif

public final class LineGeometry: SatinGeometry {
    public override func generateGeometryData() -> GeometryData {
        generateLineGeometryData()
    }
}
