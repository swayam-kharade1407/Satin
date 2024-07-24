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

    static let defaultDefines: [ShaderDefine] = {
        var results = [ShaderDefine]()

#if targetEnvironment(simulator)
        results.append(ShaderDefine(key: "SIMULATOR", value: NSString(string: "true")))
#endif

#if os(iOS) || os(visionOS)
        results.append(ShaderDefine(key: "MOBILE", value: NSString(string: "true")))
#endif

#if os(visionOS)
        results.append(ShaderDefine(key: "VISIONOS", value: NSString(string: "true")))
#endif

#if os(macOS)
        results.append(ShaderDefine(key: "MACOS", value: NSString(string: "true")))
#endif

#if os(iOS)
        results.append(ShaderDefine(key: "IOS", value: NSString(string: "true")))
#endif

#if os(tvOS)
        results.append(ShaderDefine(key: "TVOS", value: NSString(string: "true")))
#endif

#if DEBUG
        results.append(ShaderDefine(key: "DEBUG", value: NSString(string: "true")))
#endif
        return results
    }()
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
