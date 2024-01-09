//
//  ComputeShaderLibrarySourceCache.swift
//
//
//  Created by Reza Ali on 1/8/24.
//

import Foundation

public final class ComputeShaderLibrarySourceCache {
    static var cache: [ComputeShaderLibraryConfiguration: String] = [:]

    class func invalidateLibrarySource(configuration: ComputeShaderLibraryConfiguration) {
        cache.removeValue(forKey: configuration)
    }

    class func getLibrarySource(configuration: ComputeShaderLibraryConfiguration) throws -> String? {
        if let source = ComputeShaderLibrarySourceCache.cache[configuration] { return source }

//        print("Creating Compute Shader Library Source: \(configuration.label)")

        guard let pipelineURL = configuration.pipelineURL,
              var source = ComputeIncludeSource.get(),
              let shaderSource = try ShaderSourceCache.getSource(url: pipelineURL)
        else { return nil }

        injectDefines(
            source: &source,
            defines: configuration.defines
        )

        injectConstants(
            source: &source,
            constants: configuration.constants
        )

        source += shaderSource

        ComputeShaderLibrarySourceCache.cache[configuration] = source

        return source
    }
}
