//
//  ComputeConfiguration.swift
//
//
//  Created by Reza Ali on 1/8/24.
//

import Foundation

public struct ComputeConfiguration: Equatable, Hashable {
    var threadGroupSizeIsMultipleOfThreadExecutionWidth = true

    var defines: [ShaderDefine] = []
    var constants: [String] = []

    public func hash(into hasher: inout Hasher) {
        hasher.combine(threadGroupSizeIsMultipleOfThreadExecutionWidth)
        if !defines.isEmpty { hasher.combine(defines) }
        if !constants.isEmpty { hasher.combine(constants) }
    }

    func getDefines() -> [ShaderDefine] {
        defines
    }

    func getConstants() -> [String] {
        constants
    }
}

extension ComputeConfiguration: CustomStringConvertible {
    public var description: String {
        var output = "ComputeConfiguration: \n"

        output += "\t\t threadGroupSizeIsMultipleOfThreadExecutionWidth: \(threadGroupSizeIsMultipleOfThreadExecutionWidth)\n"

        if !defines.isEmpty {
            output += "\t\t defines:\n"
            for (index, define) in defines.enumerated() {
                output += "\t\t\t \(index): \(define.description)"
            }
        }

        if !constants.isEmpty {
            output += "\t\t constants:\n"
            for (index, constant) in constants.enumerated() {
                output += "\t\t\t \(index): \(constant)\n"
            }
        }

        return output
    }
}
