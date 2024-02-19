//
//  ComputeShaderLibrarySourceCache.swift
//
//
//  Created by Reza Ali on 1/8/24.
//

import Foundation

public actor ComputeShaderLibrarySourceCache {
    static var cache: [ComputeShaderLibraryConfiguration: String] = [:]

    static func invalidateLibrarySource(configuration: ComputeShaderLibraryConfiguration) {
        cache.removeValue(forKey: configuration)
    }

    static func getLibrarySource(configuration: ComputeShaderLibraryConfiguration) throws -> String? {
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

        cache[configuration] = source

        return source
    }
}
