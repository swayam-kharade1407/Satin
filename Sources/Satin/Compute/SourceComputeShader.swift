//
//  SourceComputeShader.swift
//
//
//  Created by Reza Ali on 1/8/24.
//

import Foundation
import Combine

open class SourceComputeShader: ComputeShader {
    public var pipelineURL: URL {
        get { configuration.pipelineURL! }
        set { configuration.pipelineURL = newValue }
    }

    public var source: String? {
        do {
            return try ComputeShaderLibrarySourceCache.getLibrarySource(configuration: configuration.getLibraryConfiguration())
        }
        catch {
            print("\(label) Compute Shader Source: \(error.localizedDescription)")
        }
        return nil
    }

    public var live = false {
        didSet {
            compiler.watch = live
        }
    }

    var compilerSubscription: AnyCancellable?
    private lazy var compiler: MetalFileCompiler = .init(watch: live) {
        didSet {
            compilerSubscription = compiler.onUpdatePublisher.sink { [weak self] _ in
                guard let self = self else { return }

                ShaderSourceCache.removeSource(url: self.pipelineURL)

                ComputeShaderLibrarySourceCache.invalidateLibrarySource(
                    configuration: self.configuration.getLibraryConfiguration()
                )

                ComputeShaderLibraryCache.invalidateLibrary(
                    configuration: self.configuration.getLibraryConfiguration()
                )

                ComputeShaderPipelineCache.invalidate(configuration: self.configuration)

                // invalidate caches to recompile shader

                self.resetPipelineNeedsUpdate = true
                self.updatePipelineNeedsUpdate = true
                self.parametersNeedsUpdate = true

                print("Updating Compute Shader: \(self.label) at: \(self.pipelineURL.path)")

                self.update()
            }
        }
    }

    public init(label: String, pipelineURL: URL) {
        super.init(label: label, pipelineURL: pipelineURL)
        setupShaderCompiler()
    }

    public required init(configuration: ComputeShaderConfiguration) {
        super.init(configuration: configuration)
        setupShaderCompiler()
    }

    open func setupShaderCompiler() {
        compiler = ShaderSourceCache.getCompiler(url: pipelineURL)
        compiler.watch = live
    }
}
