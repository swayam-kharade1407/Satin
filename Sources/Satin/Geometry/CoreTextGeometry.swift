//
//  CoreTextGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/9/24.
//

import Foundation

#if SWIFT_PACKAGE
import SatinCore
#endif

public final class CoreTextGeometry: SatinGeometry {
    public var text: String {
        didSet {
            if text != oldValue {
                _updateData = true
            }
        }
    }

    public init(text: String) {
        self.text = text
        super.init()
        self.primitiveType = .triangle
    }

    public override func generateGeometryData() -> GeometryData {
        var result: GeometryData = createGeometryData()
        withExtendedLifetime(text) {
            text.utf8CString.withUnsafeBufferPointer { buffer in
                result = generateTextGeometryData("Teko", buffer.baseAddress!)
            }
        }

        return result
    }
}
