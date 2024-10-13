//
//  PipelineSources.swift
//  Satin
//
//  Created by Reza Ali on 3/3/23.
//

import Foundation

public final class ShaderSourceCache: Sendable {
    nonisolated(unsafe) private static var sourceCache: [URL: String] = [:]
    nonisolated(unsafe) private static var compilerCache: [URL: MetalFileCompiler] = [:]

    private static let sourceQueue = DispatchQueue(label: "ShaderSourceCacheSourceQueue", attributes: .concurrent)
    private static let compilerQueue = DispatchQueue(label: "ShaderSourceCacheCompilerQueue", attributes: .concurrent)

    public static func removeSource(url: URL) {
        sourceQueue.sync(flags: .barrier) {
            _ = sourceCache.removeValue(forKey: url)
        }
    }

    public static func getSource(url: URL) throws -> String? {
        var cachedSource: String?

        sourceQueue.sync { // Read
            cachedSource = sourceCache[url]
        }

        if let cachedSource {
            return cachedSource
        }

        try sourceQueue.sync(flags: .barrier) {
            cachedSource = try getCompiler(url: url).parse(url)
            sourceCache[url] = cachedSource
        }

        return cachedSource
    }

    public static func getCompiler(url: URL) -> MetalFileCompiler {
        var cachedCompiler: MetalFileCompiler?

        compilerQueue.sync { // Read
            cachedCompiler = compilerCache[url]
        }

        if let cachedCompiler {
            return cachedCompiler
        }

        let compiler = MetalFileCompiler(watch: false)

        compilerQueue.sync(flags: .barrier) {
            compilerCache[url] = compiler
        }

        return compiler
    }
}

public final class PassThroughVertexPipelineSource: Sendable {
    static let shared = PassThroughVertexPipelineSource()
    nonisolated(unsafe) private static var sharedSource: String?

    private static let url = getPipelinesCommonURL("VertexShader.metal")
    private static let queue = DispatchQueue(label: "PassThroughVertexPipelineSourceQueue", attributes: .concurrent)

    public static func get() -> String? {
        var source: String?

        queue.sync {
            source = self.sharedSource
        }

        if let source {
            return source
        }

        guard let url else { return nil }

        do {
            let source = try MetalFileCompiler(watch: false).parse(url)
            queue.sync(flags: .barrier) {
                self.sharedSource = source
            }
            return source
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

public final class PassThroughShadowPipelineSource: Sendable {
    static let shared = PassThroughShadowPipelineSource()
    nonisolated(unsafe) private static var sharedSource: String?

    private static let url = getPipelinesCommonURL("ShadowShader.metal")
    private static let queue = DispatchQueue(label: "PassThroughShadowPipelineSourceQueue", attributes: .concurrent)

    public static func get() -> String? {
        var source: String?

        queue.sync {
            source = self.sharedSource
        }

        if let source {
            return source
        }

        guard let url else { return nil }

        do {
            let source = try MetalFileCompiler(watch: false).parse(url)
            queue.sync(flags: .barrier) {
                self.sharedSource = source
            }
            return source
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

public final class ShadowFunctionSource: Sendable {
    static let shared = ShadowFunctionSource()
    nonisolated(unsafe) private static var sharedSource: String?

    private static let url = getPipelinesLibraryURL("Shadow.metal")
    private static let queue = DispatchQueue(label: "ShadowFunctionSourceQueue", attributes: .concurrent)

    public static func get() -> String? {
        var source: String?

        queue.sync {
            source = self.sharedSource
        }

        if let source {
            return source
        }

        guard let url else { return nil }

        do {
            let source = try MetalFileCompiler(watch: false).parse(url)
            queue.sync(flags: .barrier) {
                self.sharedSource = source
            }
            return source
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

public final class ConstantsSource: Sendable {
    static let shared = ConstantsSource()
    nonisolated(unsafe) private static var sharedSource: String?

    private static let url = getPipelinesSatinURL("Constants.metal")
    private static let queue = DispatchQueue(label: "ConstantsSourceQueue", attributes: .concurrent)

    public static func get() -> String? {
        var source: String?

        queue.sync {
            source = self.sharedSource
        }

        if let source {
            return source
        }

        guard let url else { return nil }

        do {
            let source = try MetalFileCompiler(watch: false).parse(url)
            queue.sync(flags: .barrier) {
                self.sharedSource = source
            }
            return source
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

public final class ComputeConstantsSource: Sendable {
    static let shared = ComputeConstantsSource()
    nonisolated(unsafe) private static var sharedSource: String?

    private static let url = getPipelinesSatinURL("ComputeConstants.metal")
    private static let queue = DispatchQueue(label: "ComputeConstantsSourceQueue", attributes: .concurrent)

    public static func get() -> String? {
        var source: String?

        queue.sync {
            source = self.sharedSource
        }

        if let source {
            return source
        }

        guard let url else { return nil }

        do {
            let source = try MetalFileCompiler(watch: false).parse(url)
            queue.sync(flags: .barrier) {
                self.sharedSource = source
            }
            return source
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

public final class MeshConstantsSource: Sendable {
    static let shared = MeshConstantsSource()
    nonisolated(unsafe) private static var sharedSource: String?

    private static let url = getPipelinesSatinURL("MeshConstants.metal")
    private static let queue = DispatchQueue(label: "MeshConstantsSourceQueue", attributes: .concurrent)

    public static func get() -> String? {
        var source: String?

        queue.sync {
            source = self.sharedSource
        }

        if let source {
            return source
        }

        guard let url else { return nil }

        do {
            let source = try MetalFileCompiler(watch: false).parse(url)
            queue.sync(flags: .barrier) {
                self.sharedSource = source
            }
            return source
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

public final class VertexConstantsSource: Sendable {
    static let shared = VertexConstantsSource()
    nonisolated(unsafe) private static var sharedSource: String?

    private static let url = getPipelinesSatinURL("VertexConstants.metal")
    private static let queue = DispatchQueue(label: "VertexConstantsSourceQueue", attributes: .concurrent)

    public static func get() -> String? {
        var source: String?

        queue.sync {
            source = self.sharedSource
        }

        if let source {
            return source
        }

        guard let url else { return nil }

        do {
            let source = try MetalFileCompiler(watch: false).parse(url)
            queue.sync(flags: .barrier) {
                self.sharedSource = source
            }
            return source
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

public final class FragmentConstantsSource: Sendable {
    static let shared = FragmentConstantsSource()
    nonisolated(unsafe) private static var sharedSource: String?

    private static let url = getPipelinesSatinURL("FragmentConstants.metal")
    private static let queue = DispatchQueue(label: "FragmentConstantsSourceQueue", attributes: .concurrent)

    public static func get() -> String? {
        var source: String?

        queue.sync {
            source = self.sharedSource
        }

        if let source {
            return source
        }

        guard let url else { return nil }

        do {
            let source = try MetalFileCompiler(watch: false).parse(url)
            queue.sync(flags: .barrier) {
                self.sharedSource = source
            }
            return source
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

public final class PBRConstantsSource: Sendable {
    static let shared = PBRConstantsSource()
    nonisolated(unsafe) private static var sharedSource: String?

    private static let url = getPipelinesSatinURL("PBRConstants.metal")
    private static let queue = DispatchQueue(label: "PBRConstantsSourceQueue", attributes: .concurrent)

    public static func get() -> String? {
        var source: String?

        queue.sync {
            source = self.sharedSource
        }

        if let source {
            return source
        }

        guard let url else { return nil }

        do {
            let source = try MetalFileCompiler(watch: false).parse(url)
            queue.sync(flags: .barrier) {
                self.sharedSource = source
            }
            return source
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

public final class RenderIncludeSource: Sendable {
    static let shared = RenderIncludeSource()
    nonisolated(unsafe) private static var sharedSource: String?

    private static let url = getPipelinesSatinURL("RenderIncludes.metal")
    private static let queue = DispatchQueue(label: "RenderIncludeSourceQueue", attributes: .concurrent)

    public static func get() -> String? {
        var source: String?

        queue.sync {
            source = self.sharedSource
        }

        if let source {
            return source
        }

        guard let url else { return nil }

        do {
            let source = try MetalFileCompiler(watch: false).parse(url)
            queue.sync(flags: .barrier) {
                self.sharedSource = source
            }
            return source
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

public final class ComputeIncludeSource: Sendable {
    static let shared = ComputeIncludeSource()
    nonisolated(unsafe) private static var sharedSource: String?

    private static let url = getPipelinesSatinURL("ComputeIncludes.metal")
    private static let queue = DispatchQueue(label: "ComputeIncludeSourceQueue", attributes: .concurrent)

    public static func get() -> String? {
        var source: String?

        queue.sync {
            source = self.sharedSource
        }

        if let source {
            return source
        }

        guard let url else { return nil }

        do {
            let source = try MetalFileCompiler(watch: false).parse(url)
            queue.sync(flags: .barrier) {
                self.sharedSource = source
            }
            return source
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

public final class VertexSource: Sendable {
    static let shared = VertexSource()
    nonisolated(unsafe) private static var sharedSource: String?

    private static let url = getPipelinesSatinURL("Vertex.metal")
    private static let queue = DispatchQueue(label: "VertexSourceQueue", attributes: .concurrent)

    public static func get() -> String? {
        var source: String?

        queue.sync {
            source = self.sharedSource
        }

        if let source {
            return source
        }

        guard let url else { return nil }

        do {
            let source = try MetalFileCompiler(watch: false).parse(url)
            queue.sync(flags: .barrier) {
                self.sharedSource = source
            }
            return source
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

public final class VertexDataSource: Sendable {
    static let shared = VertexDataSource()
    nonisolated(unsafe) private static var sharedSource: String?

    private static let url = getPipelinesSatinURL("VertexData.metal")
    private static let queue = DispatchQueue(label: "VertexDataSourceQueue", attributes: .concurrent)

    public static func get() -> String? {
        var source: String?

        queue.sync {
            source = self.sharedSource
        }

        if let source {
            return source
        }

        guard let url else { return nil }

        do {
            let source = try MetalFileCompiler(watch: false).parse(url)
            queue.sync(flags: .barrier) {
                self.sharedSource = source
            }
            return source
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

public final class VertexUniformsSource: Sendable {
    static let shared = VertexUniformsSource()
    nonisolated(unsafe) private static var sharedSource: String?

    private static let url = getPipelinesSatinURL("VertexUniforms.metal")
    private static let queue = DispatchQueue(label: "VertexUniformsSourceQueue", attributes: .concurrent)

    public static func get() -> String? {
        var source: String?

        queue.sync {
            source = self.sharedSource
        }

        if let source {
            return source
        }

        guard let url else { return nil }

        do {
            let source = try MetalFileCompiler(watch: false).parse(url)
            queue.sync(flags: .barrier) {
                self.sharedSource = source
            }
            return source
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

public final class InstanceMatrixUniformsSource: Sendable {
    static let shared = InstanceMatrixUniformsSource()
    nonisolated(unsafe) private static var sharedSource: String?

    private static let url = getPipelinesSatinURL("InstanceMatrixUniforms.metal")
    private static let queue = DispatchQueue(label: "InstanceMatrixUniformsSourceQueue", attributes: .concurrent)

    public static func get() -> String? {
        var source: String?

        queue.sync {
            source = self.sharedSource
        }

        if let source {
            return source
        }

        guard let url else { return nil }

        do {
            let source = try MetalFileCompiler(watch: false).parse(url)
            queue.sync(flags: .barrier) {
                self.sharedSource = source
            }
            return source
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

public final class LightingSource: Sendable {
    static let shared = LightingSource()
    nonisolated(unsafe) private static var sharedSource: String?

    private static let url = getPipelinesSatinURL("LightData.metal")
    private static let queue = DispatchQueue(label: "LightingSourceQueue", attributes: .concurrent)

    public static func get() -> String? {
        var source: String?

        queue.sync {
            source = self.sharedSource
        }

        if let source {
            return source
        }

        guard let url else { return nil }

        do {
            let source = try MetalFileCompiler(watch: false).parse(url)
            queue.sync(flags: .barrier) {
                self.sharedSource = source
            }
            return source
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

public final class ShadowDataSource: Sendable {
    static let shared = ShadowDataSource()
    nonisolated(unsafe) private static var sharedSource: String?

    private static let url = getPipelinesSatinURL("ShadowData.metal")
    private static let queue = DispatchQueue(label: "ShadowDataSourceQueue", attributes: .concurrent)

    public static func get() -> String? {
        var source: String?

        queue.sync {
            source = self.sharedSource
        }

        if let source {
            return source
        }

        guard let url else { return nil }

        do {
            let source = try MetalFileCompiler(watch: false).parse(url)
            queue.sync(flags: .barrier) {
                self.sharedSource = source
            }
            return source
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

public final class InstancingArgsSource: Sendable {
    static let shared = InstancingArgsSource()
    nonisolated(unsafe) private static var sharedSource: String?

    private static let url = getPipelinesSatinURL("InstancingArgs.metal")
    private static let queue = DispatchQueue(label: "InstancingArgsSourceQueue", attributes: .concurrent)

    public static func get() -> String? {
        var source: String?

        queue.sync {
            source = self.sharedSource
        }

        if let source {
            return source
        }

        guard let url else { return nil }

        do {
            let source = try MetalFileCompiler(watch: false).parse(url)
            queue.sync(flags: .barrier) {
                self.sharedSource = source
            }
            return source
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}
