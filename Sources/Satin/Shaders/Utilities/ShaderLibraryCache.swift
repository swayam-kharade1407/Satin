//
//  ShaderLibraryCache.swift
//
//
//  Created by Reza Ali on 6/14/23.
//

import Foundation
import Metal

public actor ShaderLibraryCache {
    static var cache: [ShaderLibraryConfiguration: MTLLibrary] = [:]
    static var defaultLibrary: MTLLibrary?

    public static func invalidateLibrary(configuration: ShaderLibraryConfiguration) {
        cache.removeValue(forKey: configuration)
    }

    public static func getDefaultLibrary(device: MTLDevice) -> MTLLibrary? {
        if let defaultLibrary { return defaultLibrary }

        defaultLibrary = device.makeDefaultLibrary()
        return defaultLibrary
    }

    public static func getLibrary(configuration: ShaderLibraryConfiguration, device: MTLDevice) throws -> MTLLibrary? {
        if let library = cache[configuration] { return library }

//        print("Creating Shader Library: \(configuration.label)")

        if let source = try ShaderLibrarySourceCache.getLibrarySource(configuration: configuration) {
            let library = try device.makeLibrary(source: source, options: nil)
            cache[configuration] = library
            return library
        }
        else if let url = configuration.libraryURL {
            let library = try device.makeLibrary(URL: url)
            cache[configuration] = library
            return library
        }
        else if let defaultLibrary = getDefaultLibrary(device: device) {
            cache[configuration] = defaultLibrary
            return defaultLibrary
        }

        return nil
    }
}
