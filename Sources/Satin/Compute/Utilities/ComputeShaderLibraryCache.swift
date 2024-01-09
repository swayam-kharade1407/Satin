//
//  ComputeShaderLibraryCache.swift
//
//
//  Created by Reza Ali on 1/8/24.
//

import Foundation
import Metal

public final class ComputeShaderLibraryCache {
    static var cache: [ComputeShaderLibraryConfiguration: MTLLibrary] = [:]
    static var defaultLibrary: MTLLibrary?

    public class func invalidateLibrary(configuration: ComputeShaderLibraryConfiguration) {
        cache.removeValue(forKey: configuration)
    }

    public class func getDefaultLibrary(device: MTLDevice) -> MTLLibrary? {
        guard defaultLibrary == nil else { return defaultLibrary! }
        defaultLibrary = device.makeDefaultLibrary()
        return defaultLibrary
    }

    public class func getLibrary(configuration: ComputeShaderLibraryConfiguration, device: MTLDevice) throws -> MTLLibrary? {
        if let library = ComputeShaderLibraryCache.cache[configuration] { return library }

//        print("Creating Compute Shader Library: \(configuration.label)")

        if let source = try ComputeShaderLibrarySourceCache.getLibrarySource(configuration: configuration) {
            let library = try device.makeLibrary(source: source, options: nil)
            ComputeShaderLibraryCache.cache[configuration] = library
            return library
        }
        else if let url = configuration.libraryURL {
            let library = try device.makeLibrary(URL: url)
            ComputeShaderLibraryCache.cache[configuration] = library
            return library
        }
        else if let defaultLibrary = getDefaultLibrary(device: device) {
            ComputeShaderLibraryCache.cache[configuration] = defaultLibrary
            return defaultLibrary
        }

        return nil
    }
}
