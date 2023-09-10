//
//  ShaderLibrarySourceCache.swift
//
//
//  Created by Reza Ali on 6/14/23.
//

import Foundation

public final class ShaderLibrarySourceCache {
    static var cache: [ShaderLibraryConfiguration: String] = [:]

    class func invalidateLibrarySource(configuration: ShaderLibraryConfiguration) {
        cache.removeValue(forKey: configuration)
    }

    class func getLibrarySource(configuration: ShaderLibraryConfiguration) throws -> String? {
        if let source = ShaderLibrarySourceCache.cache[configuration] { return source }

//        print("Creating Shader Library Source: \(configuration.label)")

        guard let pipelineURL = configuration.pipelineURL,
              var source = try RenderIncludeSource.get(),
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

        injectShadowData(
            source: &source,
            receiveShadow: configuration.receiveShadow,
            shadowCount: configuration.shadowCount
        )

        injectShadowBuffer(
            source: &source,
            receiveShadow: configuration.receiveShadow,
            shadowCount: configuration.shadowCount
        )

        injectShadowFunction(
            source: &source,
            receiveShadow: configuration.receiveShadow,
            shadowCount: configuration.shadowCount
        )

        injectVertex(
            source: &source,
            vertexDescriptor: configuration.vertexDescriptor
        )

        source += shaderSource

        injectPassThroughVertex(
            label: configuration.label,
            source: &source
        )

        if configuration.castShadow {
            injectPassThroughShadowVertex(
                label: configuration.label,
                source: &source
            )
        }

        injectInstancingArgs(
            source: &source,
            instancing: configuration.instancing
        )

        injectShadowCoords(
            source: &source,
            receiveShadow: configuration.receiveShadow,
            shadowCount: configuration.shadowCount
        )

        injectShadowVertexArgs(
            source: &source,
            receiveShadow: configuration.receiveShadow
        )

        injectShadowVertexCalc(
            source: &source,
            receiveShadow: configuration.receiveShadow,
            shadowCount: configuration.shadowCount
        )

        injectShadowFragmentArgs(
            source: &source,
            receiveShadow: configuration.receiveShadow,
            shadowCount: configuration.shadowCount
        )

        injectShadowFragmentCalc(
            source: &source,
            receiveShadow: configuration.receiveShadow,
            shadowCount: configuration.shadowCount
        )

        injectLightingArgs(
            source: &source,
            lighting: configuration.lighting
        )

        //        modifyShaderSource(source: &source) // PBR

        ShaderLibrarySourceCache.cache[configuration] = source

        return source
    }
}
