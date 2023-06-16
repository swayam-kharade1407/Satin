//
//  LiveTextureComputeSystem.swift
//  Satin
//
//  Created by Reza Ali on 11/12/21.
//

import Foundation
import Metal
import Combine
import simd

open class LiveTextureComputeSystem: TextureComputeSystem, ObservableObject {
    public var compiler = MetalFileCompiler()
    private var compilerSubscription: AnyCancellable?
    public var source: String?
    public var pipelineURL: URL

    public var uniforms: UniformBuffer?
    public private(set) lazy var parameters: ParameterGroup = ParameterGroup(prefixLabel.titleCase)

    override public var textureDescriptors: [MTLTextureDescriptor] {
        didSet {
            updateSize()
        }
    }

    open var defines: [ShaderDefine] {
        var results = [ShaderDefine]()
        #if os(iOS)
        results.append(ShaderDefine(key: "MOBILE", value: NSString(string: "true")))
        #endif
        return results
    }

    open var constants: [String] {
        []
    }

    public init(device: MTLDevice,
                textureDescriptors: [MTLTextureDescriptor],
                pipelineURL: URL,
                feedback: Bool = false)
    {
        self.pipelineURL = pipelineURL

        super.init(device: device, textureDescriptors: textureDescriptors, updatePipeline: nil, resetPipeline: nil, feedback: feedback)

        label = prefixLabel
        source = compileSource()

        setup()
    }

    public init(device: MTLDevice,
                textureDescriptors: [MTLTextureDescriptor],
                pipelinesURL: URL,
                feedback: Bool = false)
    {
        pipelineURL = pipelinesURL

        super.init(device: device, textureDescriptors: textureDescriptors, updatePipeline: nil, resetPipeline: nil, feedback: feedback)

        pipelineURL = pipelineURL.appendingPathComponent(prefixLabel).appendingPathComponent("Shaders.metal")
        source = compileSource()
        setup()
    }

    override open func setup() {
        label = prefixLabel + " Texture Compute Encoder"
        super.setup()
        setupCompiler()
        setupPipelines()
        updateSize()
    }

    open func setupCompiler() {
        compilerSubscription = compiler.onUpdatePublisher.sink { [weak self] in
            guard let self = self else { return }
            

            self.source = nil
            self.source = self.compileSource()
            self.setupPipelines()
            self.delegate?.updated(textureComputeSystem: self)
        }
    }

    open func setupPipelines() {
        guard let source = source else { return }
        guard let library = setupLibrary(source) else { return }
        setupPipelines(library)
    }

    override open func update() {
        updateUniforms()
        super.update()
    }

    override open func update(_ commandBuffer: MTLCommandBuffer) {
        super.update(commandBuffer)
    }

    open func inject(source: inout String) {
        injectDefines(source: &source, defines: defines)
        injectConstants(source: &source, constants: constants)
        injectComputeConstants(source: &source)
    }

    func compileSource() -> String? {
        if let source = source {
            return source
        } else {
            do {
                guard var source = ComputeIncludeSource.get() else { return nil }

                let shaderSource = try compiler.parse(pipelineURL)
                inject(source: &source)
                source += shaderSource

                if let params = parseParameters(source: source, key: "\(prefixLabel.titleCase.replacingOccurrences(of: " ", with: ""))Uniforms") {
                    parameters.setFrom(params)
                    uniforms = UniformBuffer(device: device, parameters: parameters)
                    objectWillChange.send()
                }

                self.source = source
                return source
            } catch {
                print("\(prefixLabel) TextureComputeError: Failed to compile source - \(error.localizedDescription)")
            }
            return nil
        }
    }

    func setupLibrary(_ source: String) -> MTLLibrary? {
        do {
            return try device.makeLibrary(source: source, options: .none)
        } catch {
            print("\(prefixLabel) TextureComputeError: Failed to setup MTLLibrary - \(error.localizedDescription)")
        }
        return nil
    }

    open func setupPipelines(_ library: MTLLibrary) {
        do {
            resetPipeline = try createResetPipeline(library: library, kernel: "\(prefixLabel.camelCase)Reset")
            updatePipeline = try createUpdatePipeline(library: library, kernel: "\(prefixLabel.camelCase)Update")
            reset()
        } catch {
            print("\(prefixLabel) TextureComputeError: Failed to setup Pipelines - \(error.localizedDescription)")
        }
    }

    open func createResetPipeline(library: MTLLibrary, kernel: String) throws -> MTLComputePipelineState? {
        guard let kernelFunction = library.makeFunction(name: kernel) else { return nil }
        let descriptor = MTLComputePipelineDescriptor()
        descriptor.computeFunction = kernelFunction
        descriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
        let result = try device.makeComputePipelineState(descriptor: descriptor, options: [])
        return result.0
    }

    open func createUpdatePipeline(library: MTLLibrary, kernel: String) throws -> MTLComputePipelineState? {
        guard let kernelFunction = library.makeFunction(name: kernel) else { return nil }
        let descriptor = MTLComputePipelineDescriptor()
        descriptor.computeFunction = kernelFunction
        descriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
        let result = try device.makeComputePipelineState(descriptor: descriptor, options: [])
        return result.0
    }

    func updateSize() {
        guard let txDsx = textureDescriptors.first else { return }
        if txDsx.depth > 1 {
            parameters.set("Size", [txDsx.width, txDsx.height, txDsx.depth])
        } else if txDsx.height > 1 {
            parameters.set("Size", [txDsx.width, txDsx.height])
        } else if txDsx.width > 1 {
            parameters.set("Size", txDsx.width)
        }
    }

    func updateUniforms() {
        guard let uniforms = uniforms else { return }
        uniforms.update()
    }

    override open func bind(_ computeEncoder: MTLComputeCommandEncoder) -> Int {
        bindUniforms(computeEncoder)
        return super.bind(computeEncoder)
    }

    open func bindUniforms(_ computeEncoder: MTLComputeCommandEncoder) {
        guard let uniforms = uniforms else { return }
        computeEncoder.setBuffer(uniforms.buffer, offset: uniforms.offset, index: ComputeBufferIndex.Uniforms.rawValue)
    }

    public func set(_ name: String, _ value: [Float]) {
        let count = value.count
        if count == 1 {
            set(name, value[0])
        } else if count == 2 {
            set(name, simd_make_float2(value[0], value[1]))
        } else if count == 3 {
            set(name, simd_make_float3(value[0], value[1], value[2]))
        } else if count == 4 {
            set(name, simd_make_float4(value[0], value[1], value[2], value[3]))
        }
    }

    public func set(_ name: String, _ value: [Int]) {
        let count = value.count
        if count == 1 {
            set(name, value[0])
        } else if count == 2 {
            set(name, simd_make_int2(Int32(value[0]), Int32(value[1])))
        } else if count == 3 {
            set(name, simd_make_int3(Int32(value[0]), Int32(value[1]), Int32(value[2])))
        } else if count == 4 {
            set(name, simd_make_int4(Int32(value[0]), Int32(value[1]), Int32(value[2]), Int32(value[3])))
        }
    }

    public func set(_ name: String, _ value: Float) {
        if let param = parameters.get(name) as? FloatParameter {
            param.value = value
        } else {
            parameters.append(FloatParameter(name, value))
        }
    }

    public func set(_ name: String, _ value: simd_float2) {
        if let param = parameters.get(name) as? Float2Parameter {
            param.value = value
        } else {
            parameters.append(Float2Parameter(name, value))
        }
    }

    public func set(_ name: String, _ value: simd_float3) {
        if let param = parameters.get(name) as? Float3Parameter {
            param.value = value
        } else {
            parameters.append(Float3Parameter(name, value))
        }
    }

    public func set(_ name: String, _ value: simd_float4) {
        if let param = parameters.get(name) as? Float4Parameter {
            param.value = value
        } else {
            parameters.append(Float4Parameter(name, value))
        }
    }

    public func set(_ name: String, _ value: Int) {
        if let param = parameters.get(name) as? IntParameter {
            param.value = value
        } else {
            parameters.append(IntParameter(name, value))
        }
    }

    public func set(_ name: String, _ value: simd_int2) {
        if let param = parameters.get(name) as? Int2Parameter {
            param.value = value
        } else {
            parameters.append(Int2Parameter(name, value))
        }
    }

    public func set(_ name: String, _ value: simd_int3) {
        if let param = parameters.get(name) as? Int3Parameter {
            param.value = value
        } else {
            parameters.append(Int3Parameter(name, value))
        }
    }

    public func set(_ name: String, _ value: simd_int4) {
        if let param = parameters.get(name) as? Int4Parameter {
            param.value = value
        } else {
            parameters.append(Int4Parameter(name, value))
        }
    }

    public func set(_ name: String, _ value: Bool) {
        if let param = parameters.get(name) as? BoolParameter {
            param.value = value
        } else {
            parameters.append(BoolParameter(name, value))
        }
    }

    public func set(_ name: String, _ value: simd_float2x2) {
        if let param = parameters.get(name) as? Float2x2Parameter {
            param.value = value
        } else {
            parameters.append(Float2x2Parameter(name, value))
        }
    }

    public func set(_ name: String, _ value: simd_float3x3) {
        if let param = parameters.get(name) as? Float3x3Parameter {
            param.value = value
        } else {
            parameters.append(Float3x3Parameter(name, value))
        }
    }

    public func set(_ name: String, _ value: simd_float4x4) {
        if let param = parameters.get(name) as? Float4x4Parameter {
            param.value = value
        } else {
            parameters.append(Float4x4Parameter(name, value))
        }
    }

    public func get(_ name: String) -> Parameter? {
        return parameters.get(name)
    }
}
