//
//  Material.swift
//  Satin
//
//  Created by Reza Ali on 7/24/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Combine
import Metal
import simd

public protocol MaterialDelegate: AnyObject {
    func updated(material: Material)
}

public struct DepthBias: Codable, Equatable {
    var bias: Float
    var slope: Float
    var clamp: Float

    public init(bias: Float, slope: Float, clamp: Float) {
        self.bias = bias
        self.slope = slope
        self.clamp = clamp
    }
}

open class Material: Codable, ObservableObject, ParameterGroupDelegate {
    @Published open var id: String = UUID().uuidString

    var prefix: String {
        var result = String(describing: type(of: self)).replacingOccurrences(of: "Material", with: "")
        if let bundleName = Bundle(for: type(of: self)).displayName, bundleName != result {
            result = result.replacingOccurrences(of: bundleName, with: "")
        }
        result = result.replacingOccurrences(of: ".", with: "")
        return result
    }

    public lazy var label: String = prefix

    public var vertexDescriptor: MTLVertexDescriptor {
        get { configuration.vertexDescriptor }
        set { configuration.vertexDescriptor = newValue }
    }

    private var parametersSubscription: AnyCancellable?

    public private(set) var shader: Shader? {
        didSet {
            if shader != oldValue, let shader = shader {
                setupShaderConfiguration(shader)
                setupShaderParametersSubscription(shader)
            }
        }
    }

    public var sourceRGBBlendFactor: MTLBlendFactor {
        get { configuration.blending.sourceRGBBlendFactor }
        set { configuration.blending.sourceRGBBlendFactor = newValue }
    }

    public var sourceAlphaBlendFactor: MTLBlendFactor {
        get { configuration.blending.sourceAlphaBlendFactor }
        set { configuration.blending.sourceAlphaBlendFactor = newValue }
    }

    public var destinationRGBBlendFactor: MTLBlendFactor {
        get { configuration.blending.destinationRGBBlendFactor }
        set { configuration.blending.destinationRGBBlendFactor = newValue }
    }

    public var destinationAlphaBlendFactor: MTLBlendFactor {
        get { configuration.blending.destinationAlphaBlendFactor }
        set { configuration.blending.destinationAlphaBlendFactor = newValue }
    }

    public var rgbBlendOperation: MTLBlendOperation {
        get { configuration.blending.rgbBlendOperation }
        set { configuration.blending.rgbBlendOperation = newValue }
    }

    public var alphaBlendOperation: MTLBlendOperation {
        get { configuration.blending.alphaBlendOperation }
        set { configuration.blending.alphaBlendOperation = newValue }
    }

    private var configuration = RenderingConfiguration() {
        didSet {
            if configuration != oldValue, let shader = shader {
                setupShaderConfiguration(shader)
            }
        }
    }

    public var uniforms: UniformBuffer?

    public private(set) lazy var parameters: ParameterGroup = {
        let params = ParameterGroup(label)
        params.delegate = self
        return params
    }() {
        didSet {
            parameters.delegate = self
            uniformsNeedsUpdate = true
        }
    }

    public private(set) var vertexTextures: [VertexTextureIndex: MTLTexture?] = [:]
    public private(set) var fragmentTextures: [FragmentTextureIndex: MTLTexture?] = [:]

    public internal(set) var isClone = false
    public weak var delegate: MaterialDelegate?

    public var pipeline: MTLRenderPipelineState? {
        shader?.pipeline
    }

    public var shadowPipeline: MTLRenderPipelineState? {
        shader?.shadowPipeline
    }

    public var context: Context? {
        didSet {
            if context != nil, context != oldValue {
                setup()
            }
        }
    }

    public var instancing: Bool {
        get { configuration.instancing }
        set { configuration.instancing = newValue }
    }

    public var castShadow: Bool {
        get { configuration.castShadow }
        set { configuration.castShadow = newValue }
    }

    public var receiveShadow: Bool {
        get { configuration.receiveShadow }
        set { configuration.receiveShadow = newValue }
    }

    public var lighting: Bool {
        get { configuration.lighting }
        set { configuration.lighting = newValue }
    }

    public var shadowCount: Int {
        get { configuration.shadowCount }
        set { configuration.shadowCount = newValue }
    }

    public var lightCount: Int {
        get { configuration.lightCount }
        set { configuration.lightCount = newValue }
    }

    public var blending: Blending {
        get { configuration.blending.type }
        set { configuration.blending.type = newValue }
    }

    public var depthClipMode: MTLDepthClipMode = .clip
    public var depthStencilState: MTLDepthStencilState?
    public var depthCompareFunction: MTLCompareFunction = .greaterEqual {
        didSet {
            if oldValue != depthCompareFunction {
                depthNeedsUpdate = true
            }
        }
    }

    public var depthWriteEnabled = true {
        didSet {
            if oldValue != depthWriteEnabled {
                depthNeedsUpdate = true
            }
        }
    }

    private var uniformsNeedsUpdate = false
    private var depthNeedsUpdate = false

    public var depthBias: DepthBias?
    public var onBind: ((_ renderEncoder: MTLRenderCommandEncoder) -> Void)?
    public var onUpdate: (() -> Void)?

    public required init() {}

    public init(shader: Shader) {
        self.shader = shader
        label = shader.label

        configuration = shader.configuration.rendering
        parametersSubscription = shader.parametersPublisher.sink { [weak self] parameters in
            self?.updateParameters(parameters)
        }
    }

    // MARK: - CodingKeys

    public enum CodingKeys: String, CodingKey {
        case label

        case blending
        case sourceRGBBlendFactor
        case sourceAlphaBlendFactor
        case destinationRGBBlendFactor
        case destinationAlphaBlendFactor
        case rgbBlendOperation
        case alphaBlendOperation

        case depthWriteEnabled
        case depthCompareFunction
        case depthBias

        case castShadow
        case receiveShadow

        case parameters
    }

    // MARK: - Decode

    public required init(from decoder: Decoder) throws {
        try decode(from: decoder)
    }

    public func decode(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        label = try values.decode(String.self, forKey: .label)

        blending = try values.decode(Blending.self, forKey: .blending)
        sourceRGBBlendFactor = try values.decode(MTLBlendFactor.self, forKey: .sourceRGBBlendFactor)
        sourceAlphaBlendFactor = try values.decode(MTLBlendFactor.self, forKey: .sourceAlphaBlendFactor)
        destinationRGBBlendFactor = try values.decode(MTLBlendFactor.self, forKey: .destinationRGBBlendFactor)
        destinationAlphaBlendFactor = try values.decode(MTLBlendFactor.self, forKey: .destinationAlphaBlendFactor)
        rgbBlendOperation = try values.decode(MTLBlendOperation.self, forKey: .rgbBlendOperation)
        alphaBlendOperation = try values.decode(MTLBlendOperation.self, forKey: .alphaBlendOperation)

        depthWriteEnabled = try values.decode(Bool.self, forKey: .depthWriteEnabled)
        depthCompareFunction = try values.decode(MTLCompareFunction.self, forKey: .depthCompareFunction)
        depthBias = try values.decode(DepthBias?.self, forKey: .depthBias)

        castShadow = try values.decode(Bool.self, forKey: .castShadow)
        receiveShadow = try values.decode(Bool.self, forKey: .receiveShadow)

        parameters = try values.decode(ParameterGroup.self, forKey: .parameters)
    }

    // MARK: - Encode

    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(label, forKey: .label)

        try container.encode(blending, forKey: .blending)
        try container.encode(sourceRGBBlendFactor, forKey: .sourceRGBBlendFactor)
        try container.encode(sourceAlphaBlendFactor, forKey: .sourceAlphaBlendFactor)
        try container.encode(destinationRGBBlendFactor, forKey: .destinationRGBBlendFactor)
        try container.encode(destinationAlphaBlendFactor, forKey: .destinationAlphaBlendFactor)
        try container.encode(rgbBlendOperation, forKey: .rgbBlendOperation)
        try container.encode(alphaBlendOperation, forKey: .alphaBlendOperation)

        try container.encode(depthWriteEnabled, forKey: .depthWriteEnabled)
        try container.encode(depthCompareFunction, forKey: .depthCompareFunction)
        try container.encode(depthBias, forKey: .depthBias)

        try container.encode(castShadow, forKey: .castShadow)
        try container.encode(receiveShadow, forKey: .receiveShadow)

        try container.encode(parameters, forKey: .parameters)
    }

    open func setup() {
        setupDepthStencilState()
        setupShader()
        setupUniforms()
    }

    func setupDepthStencilState() {
        guard let context = context, context.depthPixelFormat != .invalid else { return }
        let depthStateDesciptor = MTLDepthStencilDescriptor()
        depthStateDesciptor.depthCompareFunction = depthCompareFunction
        depthStateDesciptor.isDepthWriteEnabled = depthWriteEnabled
        depthStencilState = context.device.makeDepthStencilState(descriptor: depthStateDesciptor)
        depthNeedsUpdate = false
    }

    // MARK: - Shader

    open func createShader() -> Shader {
        SourceShader(
            label: label,
            pipelineURL: getPipelinesMaterialsURL(label)!.appendingPathComponent("Shaders.metal")
        )
    }

    open func setupShader() {
        if shader == nil {
            shader = createShader()
            isClone = false
        } else if let shader = shader, isClone, shader.configuration.rendering != configuration {
            self.shader = shader.clone()
            isClone = false
        }

        shader?.context = context
    }

    open func setupShaderConfiguration(_ shader: Shader) {
        shader.configuration.rendering = configuration
    }

    open func setupShaderParametersSubscription(_ shader: Shader) {
        parametersSubscription = shader.parametersPublisher.sink { [weak self] parameters in
            self?.updateParameters(parameters)
        }
    }

    open func setupUniforms() {
        guard let context = context, parameters.size > 0 else { return }
        uniforms = UniformBuffer(device: context.device, parameters: parameters)
        uniformsNeedsUpdate = false
    }

    open func update() {
        updateDepth()
        updateShader()
        updateUniforms()
        onUpdate?()
    }

    open func updateShader() {
        if shader == nil { setupShader() }
        shader?.update()
    }

    open func updateDepth() {
        if depthNeedsUpdate { setupDepthStencilState() }
    }

    open func updateUniforms() {
        if uniformsNeedsUpdate { setupUniforms() }
        uniforms?.update()
    }

    open func encode(_ commandBuffer: MTLCommandBuffer) {}

    open func bindPipeline(renderEncoderState: RenderEncoderState, shadow: Bool) {
        guard let pipeline = shadow ? shadowPipeline : pipeline else { return }
        renderEncoderState.pipeline = pipeline
    }

    open func bindUniforms(renderEncoderState: RenderEncoderState, shadow: Bool) {
        renderEncoderState.vertexMaterialUniforms = uniforms
        if !shadow { renderEncoderState.fragmentMaterialUniforms = uniforms }
    }

    open func bindDepthStates(renderEncoderState: RenderEncoderState) {
        renderEncoderState.depthStencilState = depthStencilState
        renderEncoderState.depthBias = depthBias
        renderEncoderState.depthClipMode = depthClipMode
    }

    open func bindTextures(renderEncoderState: RenderEncoderState) {
        for (index, texture) in vertexTextures {
            renderEncoderState.setVertexTexture(texture, index: index)
        }

        for (index, texture) in fragmentTextures {
            renderEncoderState.setFragmentTexture(texture, index: index)
        }
    }

    open func bind(renderEncoderState: RenderEncoderState, shadow: Bool) {
        bindUniforms(renderEncoderState: renderEncoderState, shadow: shadow)
        bindDepthStates(renderEncoderState: renderEncoderState)
        bindTextures(renderEncoderState: renderEncoderState)
        bindPipeline(renderEncoderState: renderEncoderState, shadow: shadow)
        onBind?(renderEncoderState.renderEncoder)
    }


    public func set(_ texture: MTLTexture?, index: VertexTextureIndex) {
        if let texture = texture {
            vertexTextures[index] = texture
        } else {
            vertexTextures.removeValue(forKey: index)
        }
    }

    public func set(_ texture: MTLTexture?, index: FragmentTextureIndex) {
        if let texture = texture {
            fragmentTextures[index] = texture
        } else {
            fragmentTextures.removeValue(forKey: index)
        }
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

    public func setParameters(from incomingParams: ParameterGroup) {
        parameters = incomingParams.clone()
    }

    public func setParameters(from material: Material) {
        parameters = material.parameters.clone()
    }

    public func get(_ name: String) -> (any Parameter)? {
        return parameters.get(name)
    }

    deinit {
        parameters.delegate = nil
        delegate = nil
        shader = nil
    }

    open func clone() -> Material {
        let clone: Material = type(of: self).init()
        clone.isClone = true
        cloneProperties(clone: clone)
        return clone
    }

    public func cloneProperties(clone: Material) {
        clone.label = label
        clone.vertexDescriptor = vertexDescriptor
        clone.instancing = instancing
        clone.lighting = lighting
        clone.lightCount = lightCount

        clone.delegate = delegate
        clone.parameters = parameters.clone()

        clone.onUpdate = onUpdate
        clone.onBind = onBind

        clone.blending = blending
        clone.sourceRGBBlendFactor = sourceRGBBlendFactor
        clone.sourceAlphaBlendFactor = sourceAlphaBlendFactor
        clone.destinationRGBBlendFactor = destinationRGBBlendFactor
        clone.destinationAlphaBlendFactor = destinationAlphaBlendFactor
        clone.rgbBlendOperation = rgbBlendOperation
        clone.alphaBlendOperation = alphaBlendOperation

        clone.depthStencilState = depthStencilState
        clone.depthCompareFunction = depthCompareFunction
        clone.depthWriteEnabled = depthWriteEnabled
    }
}

public extension Material {
    func added(parameter: any Parameter, from: ParameterGroup) {
        uniformsNeedsUpdate = true
        objectWillChange.send()
    }

    func removed(parameter: any Parameter, from: ParameterGroup) {
        uniformsNeedsUpdate = true
        objectWillChange.send()
    }

    func loaded(group: ParameterGroup) {
        uniformsNeedsUpdate = true
        objectWillChange.send()
    }

    func saved(group: ParameterGroup) {}

    func cleared(group: ParameterGroup) {
        uniformsNeedsUpdate = true
        objectWillChange.send()
    }

    func update(parameter: any Parameter, from: ParameterGroup) {
        objectWillChange.send()
    }
}

public extension Material {
    func updateParameters(_ newParameters: ParameterGroup) {
        parameters.setFrom(newParameters)
        parameters.label = newParameters.label
        uniformsNeedsUpdate = true
        objectWillChange.send()
        delegate?.updated(material: self)
    }
}

//extension Material: Hashable {
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//    }
//}

extension Material: Equatable {
    public static func == (lhs: Material, rhs: Material) -> Bool {
        return lhs === rhs
    }
}
