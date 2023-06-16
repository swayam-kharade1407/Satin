//
//  ShaderDefine.swift
//  
//
//  Created by Reza Ali on 6/15/23.
//

import Foundation

public struct ShaderDefine {
    var key: String
    var value: NSObject

    public init(key: String, value: NSObject) {
        self.key = key
        self.value = value
    }
}

extension ShaderDefine: CustomStringConvertible {
    public var description: String {
        "#define \(key) \(value)\n"
    }
}

extension ShaderDefine: Equatable, Hashable {
    public static func == (lhs: ShaderDefine, rhs: ShaderDefine) -> Bool {
        lhs.description == rhs.description
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }
}

