//
//  PipelineSources.swift
//  Satin
//
//  Created by Reza Ali on 3/3/23.
//

import Foundation

public final actor ShaderSourceCache {
    static var sourceCache: [URL: String] = [:]
    static var compilerCache: [URL: MetalFileCompiler] = [:]

    private static let sourceQueue = DispatchQueue(label: "ShaderSourceCacheSourceQueue", attributes: .concurrent)
    private static let compilerQueue = DispatchQueue(label: "ShaderSourceCacheCompilerQueue", attributes: .concurrent)

    public static func removeSource(url: URL) {
        _ = sourceQueue.sync(flags: .barrier) {
            sourceCache.removeValue(forKey: url)
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

public final actor PassThroughVertexPipelineSource {
    static let shared = PassThroughVertexPipelineSource()
    private static var sharedSource: String?

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

public final actor PassThroughShadowPipelineSource {
    static let shared = PassThroughShadowPipelineSource()
    private static var sharedSource: String?

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

public final actor ShadowFunctionSource {
    static let shared = ShadowFunctionSource()
    private static var sharedSource: String?

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

public final actor ConstantsSource {
    static let shared = ConstantsSource()
    private static var sharedSource: String?

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

public final actor ComputeConstantsSource {
    static let shared = ComputeConstantsSource()
    private static var sharedSource: String?

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

public final actor MeshConstantsSource {
    static let shared = MeshConstantsSource()
    private static var sharedSource: String?

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

public final actor VertexConstantsSource {
    static let shared = VertexConstantsSource()
    private static var sharedSource: String?

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

public final actor FragmentConstantsSource {
    static let shared = FragmentConstantsSource()
    private static var sharedSource: String?

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

public final actor PBRConstantsSource {
    static let shared = PBRConstantsSource()
    private static var sharedSource: String?

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

public final actor RenderIncludeSource {
    static let shared = RenderIncludeSource()
    private static var sharedSource: String?

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

public final actor ComputeIncludeSource {
    static let shared = ComputeIncludeSource()
    private static var sharedSource: String?

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

public final actor VertexSource {
    static let shared = VertexSource()
    private static var sharedSource: String?

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

public final actor VertexDataSource {
    static let shared = VertexDataSource()
    private static var sharedSource: String?

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

public final actor VertexUniformsSource {
    static let shared = VertexUniformsSource()
    private static var sharedSource: String?

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

public final actor InstanceMatrixUniformsSource {
    static let shared = InstanceMatrixUniformsSource()
    private static var sharedSource: String?

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

public final actor LightingSource {
    static let shared = LightingSource()
    private static var sharedSource: String?

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

public final actor ShadowDataSource {
    static let shared = ShadowDataSource()
    private static var sharedSource: String?

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

public final actor InstancingArgsSource {
    static let shared = InstancingArgsSource()
    private static var sharedSource: String?

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
