//
//  PipelineSources.swift
//  Satin
//
//  Created by Reza Ali on 3/3/23.
//

import Foundation

public class ShaderSourceCache {
    static var sourceCache: [URL: String] = [:]
    static var compilerCache: [URL: MetalFileCompiler] = [:]

    public class func removeSource(url: URL) {
        sourceCache.removeValue(forKey: url)
    }

    public class func getSource(url: URL) throws -> String? {
        guard ShaderSourceCache.sourceCache[url] == nil else {
            return sourceCache[url]
        }

        let source = try getCompiler(url: url).parse(url)
        sourceCache[url] = source
        return source
    }

    public class func getCompiler(url: URL) -> MetalFileCompiler {
        guard ShaderSourceCache.compilerCache[url] == nil else { return compilerCache[url]! }
        let compiler = MetalFileCompiler(watch: false)
        compilerCache[url] = compiler
        return compiler
    }
}

public class PassThroughVertexPipelineSource {
    static let shared = PassThroughVertexPipelineSource()
    private static var sharedSource: String?

    public class func get() -> String? {
        guard PassThroughVertexPipelineSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesCommonURL("VertexShader.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error.localizedDescription)
            }
        }
        return sharedSource
    }
}

public class PassThroughShadowPipelineSource {
    static let shared = PassThroughShadowPipelineSource()
    private static var sharedSource: String?

    public class func get() -> String? {
        guard PassThroughShadowPipelineSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesCommonURL("ShadowShader.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error.localizedDescription)
            }
        }
        return sharedSource
    }
}

public class ShadowFunctionSource {
    static let shared = ShadowFunctionSource()
    private static var sharedSource: String?

    public class func get() -> String? {
        guard ShadowFunctionSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesLibraryURL("Shadow.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error.localizedDescription)
            }
        }
        return sharedSource
    }
}

public class ConstantsSource {
    static let shared = ConstantsSource()
    private static var sharedSource: String?

    public class func get() -> String? {
        guard ConstantsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("Constants.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

public class ComputeConstantsSource {
    static let shared = ComputeConstantsSource()
    private static var sharedSource: String?

    public class func get() -> String? {
        guard ComputeConstantsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("ComputeConstants.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

public class MeshConstantsSource {
    static let shared = MeshConstantsSource()
    private static var sharedSource: String?

    public class func get() -> String? {
        guard MeshConstantsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("MeshConstants.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

public class VertexConstantsSource {
    static let shared = VertexConstantsSource()
    private static var sharedSource: String?

    public class func get() -> String? {
        guard VertexConstantsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("VertexConstants.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

public class FragmentConstantsSource {
    static let shared = FragmentConstantsSource()
    private static var sharedSource: String?

    public class func get() -> String? {
        guard FragmentConstantsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("FragmentConstants.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

public class PBRConstantsSource {
    static let shared = PBRConstantsSource()
    private static var sharedSource: String?

    public class func get() -> String? {
        guard PBRConstantsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("PBRConstants.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

public class RenderIncludeSource {
    static let shared = RenderIncludeSource()
    private static var sharedSource: String?

    public class func get() -> String? {
        guard RenderIncludeSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("RenderIncludes.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

public class ComputeIncludeSource {
    static let shared = ComputeIncludeSource()
    private static var sharedSource: String?

    public class func get() -> String? {
        guard ComputeIncludeSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("ComputeIncludes.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}


public class VertexSource {
    static let shared = VertexSource()
    private static var sharedSource: String?

    public class func get() -> String? {
        guard VertexSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("Vertex.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

public class VertexDataSource {
    static let shared = VertexDataSource()
    private static var sharedSource: String?

    public class func get() -> String? {
        guard VertexDataSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("VertexData.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

public class VertexUniformsSource {
    static let shared = VertexUniformsSource()
    private static var sharedSource: String?

    public class func get() -> String? {
        guard VertexUniformsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("VertexUniforms.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

public class InstanceMatrixUniformsSource {
    static let shared = InstanceMatrixUniformsSource()
    private static var sharedSource: String?

    public class func get() -> String? {
        guard InstanceMatrixUniformsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("InstanceMatrixUniforms.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

public class LightingSource {
    static let shared = LightingSource()
    private static var sharedSource: String?

    public class func get() -> String? {
        guard LightingSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("LightData.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

public class ShadowDataSource {
    static let shared = ShadowDataSource()
    private static var sharedSource: String?

    public class func get() -> String? {
        guard ShadowDataSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("ShadowData.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error)
            }
        }
        return sharedSource
    }
}

public class InstancingArgsSource {
    static let shared = InstancingArgsSource()
    private static var sharedSource: String?

    public class func get() -> String? {
        guard InstancingArgsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinURL("InstancingArgs.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            } catch {
                print(error.localizedDescription)
            }
        }
        return sharedSource
    }
}
