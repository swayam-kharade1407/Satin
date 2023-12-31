//
//  String+Extensions.swift
//  Satin
//
//  Created by Reza Ali on 4/19/20.
//

import Foundation

public extension String {
    var camelCase: String {
        var parts = split(separator: " ")
        if let first = parts.first {
            let upperChars = first.prefix(while: { $0 .isUppercase }).lowercased()
            parts[0] = upperChars + Substring(first.dropFirst(upperChars.count))
        }
        return parts.joined()
    }

    var titleCase: String {
        replacingOccurrences(of: "([A-Z])",
                             with: " $1",
                             options: .regularExpression,
                             range: range(of: self))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .capitalized
    }
}
