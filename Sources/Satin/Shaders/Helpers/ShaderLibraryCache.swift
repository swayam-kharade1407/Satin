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
    static var defaultLibrary: MTLLibrary?

    class func invalidateLibrary(configuration: ShaderLibraryConfiguration) {
        cache.removeValue(forKey: configuration)
    }

    class func getDefaultLibrary(device: MTLDevice) -> MTLLibrary? {
        guard defaultLibrary == nil else { return defaultLibrary! }
        defaultLibrary = device.makeDefaultLibrary()
        return defaultLibrary
    }

    class func getLibrary(configuration: ShaderLibraryConfiguration) throws -> MTLLibrary? {
        if let library = ShaderLibraryCache.cache[configuration] { return library }

        guard let device = configuration.device else { return nil }

        print("Creating Shader Library: \(configuration.label)")
        
        if let source = try ShaderLibrarySourceCache.getLibrarySource(configuration: configuration) {
            let library = try device.makeLibrary(source: source, options: nil)
            ShaderLibraryCache.cache[configuration] = library
            return library
        }
        else if let url = configuration.libraryURL {
            let library = try device.makeLibrary(URL: url)
            ShaderLibraryCache.cache[configuration] = library
            return library
        }
        else if let defaultLibrary = getDefaultLibrary(device: device) {
            ShaderLibraryCache.cache[configuration] = defaultLibrary
            return defaultLibrary
        }

        return nil
    }
}
