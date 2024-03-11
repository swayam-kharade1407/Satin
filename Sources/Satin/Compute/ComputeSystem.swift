//
//  ComputeSystem.swift
//
//
//  Created by Reza Ali on 1/9/24.
//

import Foundation
import Combine

import Metal
import simd

public protocol ComputeSystemDelegate: AnyObject {
    func updated(computeSystem: ComputeSystem)
}

open class ComputeSystem: ComputeShaderDelegate, ObservableObject {
    public internal(set) lazy var label = prefix

    internal var prefix: String {
        var prefix = String(describing: type(of: self)).replacingOccurrences(of: "ComputeSystem", with: "")
        if let bundleName = Bundle(for: type(of: self)).displayName, bundleName != prefix {
            prefix = prefix.replacingOccurrences(of: bundleName, with: "")
        }
        prefix = prefix.replacingOccurrences(of: ".", with: "")
        return prefix
    }

    public weak var delegate: ComputeSystemDelegate?

    public var index: Int { _index }
    public var srcIndex: Int { _index }
    public var dstIndex: Int { (_index + 1) % feedbackCount }
    public var feedbackCount: Int { feedback ? 2 : 1 }

    public var preUpdate: ((_ computeEncoder: MTLComputeCommandEncoder, _ offset: inout Int) -> Void)?
    public var preReset: ((_ computeEncoder: MTLComputeCommandEncoder, _ offset: inout Int) -> Void)?
    public var preCompute: ((_ computeEncoder: MTLComputeCommandEncoder, _ offset: inout Int) -> Void)?

    public internal(set) var shader: ComputeShader? {
        didSet {
            if shader != oldValue, let shader = shader {
                reset()
                setupShaderConfiguration(shader)
                setupShaderParametersSubscription(shader)
            }
        }
    }

    public var resetPipeline: MTLComputePipelineState? {
        shader?.resetPipeline
    }

    public var updatePipeline: MTLComputePipelineState? {
        shader?.updatePipeline
    }

    open var defines: [ShaderDefine] {
        get { configuration.defines }
        set { configuration.defines = newValue }
    }

    open var constants: [String] {
        get { configuration.constants }
        set { configuration.constants = newValue }
    }

    public private(set) var uniforms: UniformBuffer?
    private var uniformsNeedsUpdate = true

    public var device: MTLDevice
    public var pipelineURL: URL
    public var feedback: Bool { didSet { reset() } }
    public var live: Bool { didSet { shader?.live = live } }

    public internal(set) var parameters = ParameterGroup()

    private var configuration = ComputeConfiguration() {
        didSet {
            if configuration != oldValue, let shader = shader {
                setupShaderConfiguration(shader)
            }
        }
    }

    internal var _reset = true
    internal var _index = 0
    internal var _count = 0
    internal var _useDispatchThreads = false

    internal var parametersSubscription: AnyCancellable?

    public init(device: MTLDevice, pipelineURL: URL, feedback: Bool, live: Bool) {
        self.device = device
        self.pipelineURL = pipelineURL
        self.feedback = feedback
        self.live = live

        setup()
    }

    public init(device: MTLDevice, pipelinesURL: URL, feedback: Bool, live: Bool) {
        pipelineURL = pipelinesURL
        self.device = device
        self.feedback = feedback
        self.live = live

        pipelineURL = pipelineURL.appendingPathComponent(prefix).appendingPathComponent("Shaders.metal")

        setup()
    }

    open func setup() {
        setupFeatures()
        setupShader()
        setupUniforms()
    }

    open func update() {
        updateShader()
        updateUniforms()
    }

    // MARK: - Features

    private func setupFeatures() {
        _useDispatchThreads = false
        if #available(macOS 10.15, iOS 13, tvOS 13, visionOS 1.0, *) {
            if device.supportsFamily(.common3) || device.supportsFamily(.apple4) || device.supportsFamily(.apple5) || device.supportsFamily(.mac1) || device.supportsFamily(.mac2) {
                _useDispatchThreads = true
            }
        } else {
#if os(macOS)
            if device.supportsFeatureSet(.macOS_GPUFamily1_v1) || device.supportsFeatureSet(.macOS_GPUFamily2_v1) {
                _useDispatchThreads = true
            }
#elseif os(iOS) || os(tvOS) || os(visionOS)
            if device.supportsFeatureSet(.iOS_GPUFamily4_v1) || device.supportsFeatureSet(.iOS_GPUFamily5_v1) {
                _useDispatchThreads = true
            }
#endif
        }
    }

    // MARK: - Shader

    open func createShader() -> ComputeShader {
        let shader = ComputeShader(label: label, pipelineURL: pipelineURL, live: live)
        shader.delegate = self
        return shader
    }

    internal func updated(shader: ComputeShader) {
        print("updated shader: \(shader.label)")
        reset()
        delegate?.updated(computeSystem: self)
    }

    internal func setupShader() {
        if shader == nil { shader = createShader() }
        shader?.device = device
    }

    internal func setupShaderConfiguration(_ shader: ComputeShader) {
        shader.configuration.compute = configuration
    }

    internal func updateShader() {
        if shader == nil { setupShader() }
        shader?.update()
    }

    internal func setupShaderParametersSubscription(_ shader: ComputeShader) {
        parametersSubscription = shader.parametersPublisher.sink { [weak self] parameters in
            self?.updateParameters(parameters)
        }
    }

    // MARK: - Update

    open func update(_ commandBuffer: MTLCommandBuffer) {
        update()
    }

    open func update(_ computeEncoder: MTLComputeCommandEncoder) {
        update()
    }

    // MARK: - Reset

    open func reset() {
        _reset = true
        resetIndex()
    }

    open func resetIndex() {
        _index = 0
    }

    // MARK: - Dispatch

    internal func dispatch(_ computeEncoder: MTLComputeCommandEncoder, _ pipeline: MTLComputePipelineState) {
#if os(macOS) || os(iOS) || os(visionOS)
        if _useDispatchThreads {
            dispatchThreads(computeEncoder, pipeline)
        } else {
            dispatchThreadgroups(computeEncoder, pipeline)
        }
#elseif os(tvOS)
        _dispatchThreadgroups(computeEncoder, pipeline)
#endif
    }

#if os(macOS) || os(iOS) || os(visionOS)
    open func dispatchThreads(_ computeEncoder: MTLComputeCommandEncoder, _ pipeline: MTLComputePipelineState) {}
#endif

    open func dispatchThreadgroups(_ computeEncoder: MTLComputeCommandEncoder, _ pipeline: MTLComputePipelineState) {}

    // MARK: - Ping / Pong

    internal func swapSrdDstIndex() {
        _index = (_index + 1) % feedbackCount
    }

    // MARK: - Uniforms

    internal func setupUniforms() {
        guard parameters.size > 0 else { return }
        uniforms = UniformBuffer(device: device, parameters: parameters)
        uniformsNeedsUpdate = false
    }

    internal func updateUniforms() {
        if uniformsNeedsUpdate { setupUniforms() }
        uniforms?.update()
    }

    open func bindUniforms(_ computeEncoder: MTLComputeCommandEncoder) {
        guard let uniforms = uniforms else { return }
        computeEncoder.setBuffer(uniforms.buffer, offset: uniforms.offset, index: ComputeBufferIndex.Uniforms.rawValue)
    }

    // MARK: - Parameters

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
        parameters.set(name, value)
    }

    public func set(_ name: String, _ value: simd_float2) {
        parameters.set(name, value)
    }

    public func set(_ name: String, _ value: simd_float3) {
        parameters.set(name, value)
    }

    public func set(_ name: String, _ value: simd_float4) {
        parameters.set(name, value)
    }

    public func set(_ name: String, _ value: simd_float2x2) {
        parameters.set(name, value)
    }

    public func set(_ name: String, _ value: simd_float3x3) {
        parameters.set(name, value)
    }

    public func set(_ name: String, _ value: simd_float4x4) {
        parameters.set(name, value)
    }

    public func set(_ name: String, _ value: Int) {
        parameters.set(name, value)
    }

    public func set(_ name: String, _ value: simd_int2) {
        parameters.set(name, value)
    }

    public func set(_ name: String, _ value: simd_int3) {
        parameters.set(name, value)
    }

    public func set(_ name: String, _ value: simd_int4) {
        parameters.set(name, value)
    }

    public func set(_ name: String, _ value: Bool) {
        parameters.set(name, value)
    }

    public func get(_ name: String) -> (any Parameter)? {
        parameters.get(name)
    }

    internal func updateParameters(_ newParameters: ParameterGroup) {
        parameters.setFrom(newParameters)
        parameters.label = newParameters.label
        uniformsNeedsUpdate = true
        objectWillChange.send()
        delegate?.updated(computeSystem: self)
    }

    deinit {
        shader = nil
        delegate = nil
    }
}
