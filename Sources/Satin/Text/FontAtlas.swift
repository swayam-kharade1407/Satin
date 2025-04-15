//
//  FontAtlas.swift
//
//
//  Created by Reza Ali on 12/30/23.
//

import Foundation

public struct FontAtlasCharacter: Decodable {
    public var x: Float
    public var y: Float
    public var width: Float
    public var height: Float
    public var originX: Float
    public var originY: Float
    public var advance: Float
}

public struct FontAtlas: Decodable {
    public var name: String
    public var size: Int
    public var bold: Bool
    public var italic: Bool
    public var width: Int
    public var height: Int
    public var characters: [String: FontAtlasCharacter]

    public static func load(url: URL) throws -> FontAtlas {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(FontAtlas.self, from: data)
    }
}
