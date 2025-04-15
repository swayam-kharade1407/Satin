//
//  ComputeShaderLibraryCache.swift
//
//
//  Created by Reza Ali on 1/8/24.
//

import Foundation
import Metal

public final class ComputeShaderLibraryCache: Sendable {
    private nonisolated(unsafe) static var cache: [ComputeShaderLibraryConfiguration: MTLLibrary] = [:]
    private nonisolated(unsafe) static var defaultLibrary: MTLLibrary?

    private static let libraryQueue = DispatchQueue(label: "ShaderLibraryCacheQueue", attributes: .concurrent)
    private static let defaultLibraryQueue = DispatchQueue(label: "ComputeShaderDefaultLibraryQueue", attributes: .concurrent)

    public static func invalidateLibrary(configuration: ComputeShaderLibraryConfiguration) {
        libraryQueue.sync(flags: .barrier) {
            _ = cache.removeValue(forKey: configuration)
        }
    }

    public static func getDefaultLibrary(device: MTLDevice) -> MTLLibrary? {
        var library: MTLLibrary?

        defaultLibraryQueue.sync {
            library = defaultLibrary
        }

        if let library {
            return library
        }

        library = device.makeDefaultLibrary()

        defaultLibraryQueue.sync(flags: .barrier) {
            defaultLibrary = library
        }

        return library
    }

    public static func getLibrary(configuration: ComputeShaderLibraryConfiguration, device: MTLDevice) throws -> MTLLibrary? {
        var library: MTLLibrary?

        libraryQueue.sync {
            library = self.cache[configuration]
        }

        if let library {
            return library
        }

//        print("Creating Compute Shader Library: \(configuration.label)")

        if let source = try ComputeShaderLibrarySourceCache.getLibrarySource(configuration: configuration) {
            library = try device.makeLibrary(source: source, options: nil)
        }
        else if let url = configuration.libraryURL {
            library = try device.makeLibrary(URL: url)
        }
        else if let defaultLibrary = getDefaultLibrary(device: device) {
            library = defaultLibrary
        }

        if let library {
            libraryQueue.sync(flags: .barrier) {
                cache[configuration] = library
            }
            return library
        }
        else {
            return nil
        }
    }
}
