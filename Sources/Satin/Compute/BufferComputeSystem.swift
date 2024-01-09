//
//  BufferComputeSystem.swift
//  Satin
//
//  Created by Reza Ali on 4/13/20.
//

import Combine
import Metal
import simd

public protocol BufferComputeSystemDelegate: AnyObject {
    func updated(bufferComputeSystem: BufferComputeSystem)
}

open class BufferComputeSystem: ObservableObject {
    public private(set) lazy var label = prefix

    private var prefix: String {
        var prefix = String(describing: type(of: self)).replacingOccurrences(of: "BufferComputeSystem", with: "")
        prefix = prefix.replacingOccurrences(of: "ComputeSystem", with: "")
        if let bundleName = Bundle(for: type(of: self)).displayName, bundleName != prefix {
            prefix = prefix.replacingOccurrences(of: bundleName, with: "")
        }
        prefix = prefix.replacingOccurrences(of: ".", with: "")
        return prefix
    }

    public var count = 0 {
        didSet {
            if count != oldValue {
                _reset = true
                _setupBuffers = true
                _updateSize = true
            }
        }
    }

    public weak var delegate: BufferComputeSystemDelegate?

    public var feedback: Bool {
        didSet {
            _reset = true
            _setupBuffers = true
        }
    }

    public var index: Int { pong() }
    public var bufferCount: Int { feedback ? 2 : 1 }

    public private(set) var buffers: [ParameterGroup] = [] {
        didSet {
            _setupBuffers = true
        }
    }

    public var bufferMap: [String: [MTLBuffer]] = [:]
    public var bufferOrder: [String] = []

    public var preUpdate: ((_ computeEncoder: MTLComputeCommandEncoder, _ bufferOffset: Int) -> Void)?
    public var preReset: ((_ computeEncoder: MTLComputeCommandEncoder, _ bufferOffset: Int) -> Void)?
    public var preCompute: ((_ computeEncoder: MTLComputeCommandEncoder, _ bufferOffset: Int) -> Void)?

    public var device: MTLDevice

    private var parametersSubscription: AnyCancellable?
    private var bufferParametersSubscription: AnyCancellable?

    public private(set) var shader: ComputeShader? {
        didSet {
            if shader != oldValue, let shader = shader {
                setupShaderConfiguration(shader)
                setupShaderParametersSubscription(shader)
                setupShaderBufferParametersSubscription(shader)
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

    public var pipelineURL: URL
    public var parameters = ParameterGroup()

    private var configuration = ComputeConfiguration() {
        didSet {
            if configuration != oldValue, let shader = shader {
                setupShaderConfiguration(shader)
            }
        }
    }

    private var _reset = true
    private var _setupBuffers = false
    private var _updateSize: Bool = true

    private var _index = 0
    private var _count = 0
    private var _useDispatchThreads = false

    public init(device: MTLDevice, pipelineURL: URL, count: Int, feedback: Bool = false) {
        self.device = device
        self.pipelineURL = pipelineURL
        self.count = count
        self.feedback = feedback
        _count = count

        setup()
    }

    public init(device: MTLDevice, pipelinesURL: URL, count: Int, feedback: Bool = false) {
        pipelineURL = pipelinesURL
        self.device = device
        self.count = count
        self.feedback = feedback
        _count = count

        pipelineURL = pipelineURL.appendingPathComponent(prefix).appendingPathComponent("Shaders.metal")

        setup()
    }

    open func setup() {
        if count <= 0 { fatalError("Compute System count: \(count) must be greater than zero!") }

        setupFeatures()
        setupShader()
        setupUniforms()
        setupBuffers()
    }

    open func update() {
        updateShader()
        updateUniforms()
        updateBuffers()
        updateSize()
    }

    // MARK: - Features

    private func setupFeatures() {
        _useDispatchThreads = false
        if #available(macOS 10.15, iOS 13, tvOS 13, *) {
            if device.supportsFamily(.common3) || device.supportsFamily(.apple4) || device.supportsFamily(.apple5) || device.supportsFamily(.mac1) || device.supportsFamily(.mac2) {
                _useDispatchThreads = true
            }
        } else {
            #if os(macOS)
            if device.supportsFeatureSet(.macOS_GPUFamily1_v1) || device.supportsFeatureSet(.macOS_GPUFamily2_v1) {
                _useDispatchThreads = true
            }
            #elseif os(iOS)
            if device.supportsFeatureSet(.iOS_GPUFamily4_v1) || device.supportsFeatureSet(.iOS_GPUFamily5_v1) {
                _useDispatchThreads = true
            }
            #endif
        }
    }

    // MARK: - Shader

    open func createShader() -> ComputeShader {
        SourceComputeShader(label: label, pipelineURL: pipelineURL)
    }

    open func setupShader() {
        if shader == nil { shader = createShader() }
        shader?.device = device
    }

    open func setupShaderConfiguration(_ shader: ComputeShader) {
        shader.configuration.compute = configuration
    }

    open func setupShaderParametersSubscription(_ shader: ComputeShader) {
        parametersSubscription = shader.parametersPublisher.sink { [weak self] parameters in
            self?.updateParameters(parameters)
        }
    }

    open func setupShaderBufferParametersSubscription(_ shader: ComputeShader) {
        bufferParametersSubscription = shader.buffersPublisher.sink { [weak self] buffers in
            self?.setBuffers(buffers)
        }
    }

    open func updateShader() {
        if shader == nil { setupShader() }
        shader?.update()
    }

    // MARK: - deinit

    deinit {
        shader = nil
        delegate = nil

        buffers = []
        bufferMap = [:]
        bufferOrder = []
    }

    // MARK: - Buffers

    public func setBuffers(_ buffers: [ParameterGroup]) {
        self.buffers = buffers
    }

    func setupBuffers() {
        bufferMap = [:]
        bufferOrder = []
        for param in buffers {
            let stride = param.stride
            if stride > 0 {
                let label = param.label
                bufferMap[label] = []
                bufferOrder.append(label)
                var buffers: [MTLBuffer] = []
                for i in 0 ..< bufferCount {
                    if let buffer = device.makeBuffer(length: stride * count, options: [.storageModePrivate]) {
                        buffer.label = param.label + " \(i)"
                        buffers.append(buffer)
                    }
                }
                bufferMap[label] = buffers
            }
        }
    }

    func updateBuffers() {
        if _setupBuffers {
            setupBuffers()
            _index = 0
            _setupBuffers = false
            _count = count
        }
    }

    public func getBuffer(_ label: String) -> MTLBuffer? {
        if let buffers = bufferMap[label] {
            return buffers[pong()]
        }
        return nil
    }

    // MARK: - Reset

    open func reset() {
        _reset = true
        _setupBuffers = true
    }

    // MARK: - Update

    public func update(_ commandBuffer: MTLCommandBuffer) {
        update()

        if bufferMap.count > 0, let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
            computeEncoder.label = label

            bindUniforms(computeEncoder)

            if _reset, let pipeline = resetPipeline {
                computeEncoder.setComputePipelineState(pipeline)
                for i in 0 ..< bufferCount {
                    let offset = bindBuffers(computeEncoder, i, ComputeBufferIndex.Custom0.rawValue)
                    preReset?(computeEncoder, offset)
                    preCompute?(computeEncoder, offset)
                    dispatch(computeEncoder, pipeline)
                }
                _reset = false
            }

            if let pipeline = updatePipeline {
                computeEncoder.setComputePipelineState(pipeline)
                let offset = bindBuffers(computeEncoder, ComputeBufferIndex.Custom0.rawValue)
                preUpdate?(computeEncoder, offset)
                preCompute?(computeEncoder, offset)
                dispatch(computeEncoder, pipeline)
                pingPong()
            }

            computeEncoder.endEncoding()
        }
    }

    private func bindBuffers(_ computeEncoder: MTLComputeCommandEncoder, _ offset: Int) -> Int {
        var indexOffset = offset
        if feedback {
            for key in bufferOrder {
                if let buffers = bufferMap[key] {
                    let inBuffer = buffers[ping()]
                    let outBuffer = buffers[pong()]
                    computeEncoder.setBuffer(inBuffer, offset: 0, index: indexOffset)
                    indexOffset += 1
                    computeEncoder.setBuffer(outBuffer, offset: 0, index: indexOffset)
                    indexOffset += 1
                }
            }
        } else {
            for key in bufferOrder {
                if let buffers = bufferMap[key] {
                    computeEncoder.setBuffer(buffers[ping()], offset: 0, index: indexOffset)
                    indexOffset += 1
                }
            }
        }
        return indexOffset
    }

    private func bindBuffers(_ computeEncoder: MTLComputeCommandEncoder, _ index: Int, _ offset: Int) -> Int {
        var indexOffset = offset
        if feedback {
            for key in bufferOrder {
                if let buffers = bufferMap[key] {
                    let inBuffer = buffers[ping(index)]
                    let outBuffer = buffers[pong(index)]
                    computeEncoder.setBuffer(inBuffer, offset: 0, index: indexOffset)
                    indexOffset += 1
                    computeEncoder.setBuffer(outBuffer, offset: 0, index: indexOffset)
                    indexOffset += 1
                }
            }
        } else {
            for key in bufferOrder {
                if let buffers = bufferMap[key] {
                    computeEncoder.setBuffer(buffers[ping(index)], offset: 0, index: indexOffset)
                    indexOffset += 1
                }
            }
        }
        return indexOffset
    }

    // MARK: - Dispatch

    private func dispatch(_ computeEncoder: MTLComputeCommandEncoder, _ pipeline: MTLComputePipelineState) {
        #if os(iOS) || os(macOS)
        if _useDispatchThreads {
            _dispatchThreads(computeEncoder, pipeline)
        } else {
            _dispatchThreadgroups(computeEncoder, pipeline)
        }
        #elseif os(tvOS)
        _dispatchThreadgroups(computeEncoder, pipeline)
        #endif
    }

    #if os(iOS) || os(macOS)
    private func _dispatchThreads(_ computeEncoder: MTLComputeCommandEncoder, _ pipeline: MTLComputePipelineState) {
        let gridSize = MTLSizeMake(_count, 1, 1)
        var threadGroupSize = pipeline.maxTotalThreadsPerThreadgroup
        threadGroupSize = threadGroupSize > _count ? _count : threadGroupSize
        let threadsPerThreadgroup = MTLSizeMake(threadGroupSize, 1, 1)
        computeEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadsPerThreadgroup)
    }
    #endif

    private func _dispatchThreadgroups(_ computeEncoder: MTLComputeCommandEncoder, _ pipeline: MTLComputePipelineState) {
        let m = pipeline.maxTotalThreadsPerThreadgroup
        let threadsPerThreadgroup = MTLSizeMake(m, 1, 1)
        let threadgroupsPerGrid = MTLSize(width: (count + m - 1) / m, height: 1, depth: 1)
        computeEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
    }

    // MARK: Ping / Pong

    private func ping() -> Int {
        return _index
    }

    private func pong() -> Int {
        return ((_index + 1) % bufferCount)
    }

    private func pingPong() {
        _index = (_index + 1) % bufferCount
    }

    private func ping(_ index: Int) -> Int {
        return (index % bufferCount)
    }

    private func pong(_ index: Int) -> Int {
        return ((index + 1) % bufferCount)
    }

    func updateSize() {
        if _updateSize {
            parameters.set("Count", count)
            _updateSize = false
        }
    }

    // MARK: - Uniforms

    open func setupUniforms() {
        guard uniformsNeedsUpdate, parameters.size > 0 else { return }
        uniforms = UniformBuffer(device: device, parameters: parameters)
        uniformsNeedsUpdate = false
    }

    func updateUniforms() {
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
}

public extension BufferComputeSystem {
    func updateParameters(_ newParameters: ParameterGroup) {
        parameters.setFrom(newParameters)
        parameters.label = newParameters.label
        uniformsNeedsUpdate = true
        objectWillChange.send()
        delegate?.updated(bufferComputeSystem: self)
    }
}
