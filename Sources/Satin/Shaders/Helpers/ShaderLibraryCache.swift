//
//  ShaderLibraryCache.swift
//  
//
//  Created by Reza Ali on 6/14/23.
//

import Foundation
import Metal

final class ShaderLibraryCache {
    static var cache: [ShaderLibraryConfiguration: MTLLibrary] = [:]

    class func invalidateLibrary(configuration: ShaderLibraryConfiguration) {
        cache.removeValue(forKey: configuration)
    }

    class func getLibrary(configuration: ShaderLibraryConfiguration) throws -> MTLLibrary? {
        if let library = ShaderLibraryCache.cache[configuration] { return library }

        guard let device = configuration.device else { return nil }

        print("Creating Shader Library: \(configuration.label)")
        
        if let url = configuration.libraryURL {
            let library = try device.makeLibrary(URL: url)
            ShaderLibraryCache.cache[configuration] = library
            return library
        }

        if let source = try ShaderLibrarySourceCache.getLibrarySource(configuration: configuration) {
            let library = try device.makeLibrary(source: source, options: nil)
            ShaderLibraryCache.cache[configuration] = library
            return library
        }

        return nil
    }
}
