//
//  PipelineSources.swift
//  Satin
//
//  Created by Reza Ali on 3/3/23.
//

import Foundation

public actor ShaderSourceCache {
    static var sourceCache: [URL: String] = [:]
    static var compilerCache: [URL: MetalFileCompiler] = [:]

    public static func removeSource(url: URL) {
        sourceCache.removeValue(forKey: url)
    }

    public static func getSource(url: URL) throws -> String? {
        if let source = sourceCache[url] { return source }

        let source = try getCompiler(url: url).parse(url)
        sourceCache[url] = source
        return source
    }

    public static func getCompiler(url: URL) -> MetalFileCompiler {
        if let compiler = compilerCache[url] { return compiler }

        let compiler = MetalFileCompiler(watch: false)
        compilerCache[url] = compiler
        return compiler
    }
}

public actor PassThroughVertexPipelineSource {
    static let shared = PassThroughVertexPipelineSource()
    private static var sharedSource: String?

    public static func get() -> String? {
        if let sharedSource { return sharedSource }

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

public actor PassThroughShadowPipelineSource {
    static let shared = PassThroughShadowPipelineSource()
    private static var sharedSource: String?

    public static func get() -> String? {
        if let sharedSource { return sharedSource }

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

public actor ShadowFunctionSource {
    static let shared = ShadowFunctionSource()
    private static var sharedSource: String?

    public static func get() -> String? {
        if let sharedSource { return sharedSource }

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

public actor ConstantsSource {
    static let shared = ConstantsSource()
    private static var sharedSource: String?

    public static func get() -> String? {
        if let sharedSource { return sharedSource }

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

public actor ComputeConstantsSource {
    static let shared = ComputeConstantsSource()
    private static var sharedSource: String?

    public static func get() -> String? {
        if let sharedSource { return sharedSource }

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

public actor MeshConstantsSource {
    static let shared = MeshConstantsSource()
    private static var sharedSource: String?

    public static func get() -> String? {
        if let sharedSource { return sharedSource }

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

public actor VertexConstantsSource {
    static let shared = VertexConstantsSource()
    private static var sharedSource: String?

    public static func get() -> String? {
        if let sharedSource { return sharedSource }

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

public actor FragmentConstantsSource {
    static let shared = FragmentConstantsSource()
    private static var sharedSource: String?

    public static func get() -> String? {
        if let sharedSource { return sharedSource }

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

public actor PBRConstantsSource {
    static let shared = PBRConstantsSource()
    private static var sharedSource: String?

    public static func get() -> String? {
        if let sharedSource { return sharedSource }

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

public actor RenderIncludeSource {
    static let shared = RenderIncludeSource()
    private static var sharedSource: String?

    public static func get() throws -> String? {
        if let sharedSource { return sharedSource }

        if let url = getPipelinesSatinURL("RenderIncludes.metal") {
            sharedSource = try MetalFileCompiler(watch: false).parse(url)
        }
        return sharedSource
    }
}

public actor ComputeIncludeSource {
    static let shared = ComputeIncludeSource()
    private static var sharedSource: String?

    public static func get() -> String? {
        if let sharedSource { return sharedSource }

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

public actor VertexSource {
    static let shared = VertexSource()
    private static var sharedSource: String?

    public static func get() -> String? {
        if let sharedSource { return sharedSource }

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

public actor VertexDataSource {
    static let shared = VertexDataSource()
    private static var sharedSource: String?

    public static func get() -> String? {
        if let sharedSource { return sharedSource }

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

public actor VertexUniformsSource {
    static let shared = VertexUniformsSource()
    private static var sharedSource: String?

    public static func get() -> String? {
        if let sharedSource { return sharedSource }

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

public actor InstanceMatrixUniformsSource {
    static let shared = InstanceMatrixUniformsSource()
    private static var sharedSource: String?

    public static func get() -> String? {
        if let sharedSource { return sharedSource }

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

public actor LightingSource {
    static let shared = LightingSource()
    private static var sharedSource: String?

    public static func get() -> String? {
        if let sharedSource { return sharedSource }

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

public actor ShadowDataSource {
    static let shared = ShadowDataSource()
    private static var sharedSource: String?

    public static func get() -> String? {
        if let sharedSource { return sharedSource }

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

public actor InstancingArgsSource {
    static let shared = InstancingArgsSource()
    private static var sharedSource: String?

    public static func get() -> String? {
        if let sharedSource { return sharedSource }
        
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
