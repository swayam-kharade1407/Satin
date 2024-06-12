//
//  Shader.swift
//  Satin
//
//  Created by Reza Ali on 1/26/22.
//

import Combine
import Foundation
import Metal

open class Shader {
    // MARK: - Main Pipeline

    open var pipelineOptions: MTLPipelineOption = [.bindingInfo, .bufferTypeInfo]
    open var pipelineReflection: MTLRenderPipelineReflection? {
        didSet {
            guard let pipelineReflection else { return }
            for binding in pipelineReflection.vertexBindings {
                if binding.index == VertexBufferIndex.VertexUniforms.rawValue {
                    vertexWantsVertexUniforms = binding.isUsed
                }
                if binding.index == VertexBufferIndex.MaterialUniforms.rawValue {
                    vertexWantsMaterialUniforms = binding.isUsed
                }
            }

            for binding in pipelineReflection.fragmentBindings {
                if binding.index == FragmentBufferIndex.VertexUniforms.rawValue {
                    fragmentWantsVertexUniforms = binding.isUsed
                }

                if binding.index == FragmentBufferIndex.MaterialUniforms.rawValue {
                    fragmentWantsMaterialUniforms = binding.isUsed
                }
            }
        }
    }

    public internal(set) var pipeline: MTLRenderPipelineState?
    public internal(set) var error: Error?

    // MARK: - Shadow Pipeline

    open var shadowPipelineOptions: MTLPipelineOption = [.bindingInfo, .bufferTypeInfo]
    open var shadowPipelineReflection: MTLRenderPipelineReflection?

    public internal(set) var shadowPipeline: MTLRenderPipelineState?
    public internal(set) var shadowError: Error?

    public internal(set) var vertexWantsVertexUniforms: Bool = false
    public internal(set) var vertexWantsMaterialUniforms: Bool = false

    public internal(set) var fragmentWantsVertexUniforms: Bool = false
    public internal(set) var fragmentWantsMaterialUniforms: Bool = false

    // MARK: - Blending

    public var configuration: ShaderConfiguration {
        didSet {
            if configuration != oldValue {
                definesNeedsUpdate = true
                constantsNeedsUpdate = true
                shadowPipelineNeedsUpdate = true
                pipelineNeedsUpdate = true
                parametersNeedsUpdate = true
            }
        }
    }

    var libraryURL: URL? {
        get { configuration.libraryURL }
        set { configuration.libraryURL = newValue }
    }

    open var constants: [String] {
        get { configuration.rendering.constants }
        set { configuration.rendering.constants = newValue }
    }

    open var defines: [ShaderDefine] {
        get { configuration.rendering.defines }
        set { configuration.rendering.defines = newValue }
    }

    // MARK: - Blending

    public var blending: Blending {
        get { configuration.rendering.blending.type }
        set { configuration.rendering.blending.type = newValue }
    }

    public var sourceRGBBlendFactor: MTLBlendFactor {
        get { configuration.rendering.blending.sourceRGBBlendFactor }
        set { configuration.rendering.blending.sourceRGBBlendFactor = newValue }
    }

    public var sourceAlphaBlendFactor: MTLBlendFactor {
        get { configuration.rendering.blending.sourceAlphaBlendFactor }
        set { configuration.rendering.blending.sourceAlphaBlendFactor = newValue }
    }

    public var destinationRGBBlendFactor: MTLBlendFactor {
        get { configuration.rendering.blending.destinationRGBBlendFactor }
        set { configuration.rendering.blending.destinationRGBBlendFactor = newValue }
    }

    public var destinationAlphaBlendFactor: MTLBlendFactor {
        get { configuration.rendering.blending.destinationRGBBlendFactor }
        set { configuration.rendering.blending.destinationRGBBlendFactor = newValue }
    }

    public var rgbBlendOperation: MTLBlendOperation {
        get { configuration.rendering.blending.rgbBlendOperation }
        set { configuration.rendering.blending.rgbBlendOperation = newValue }
    }

    public var alphaBlendOperation: MTLBlendOperation {
        get { configuration.rendering.blending.alphaBlendOperation }
        set { configuration.rendering.blending.alphaBlendOperation = newValue }
    }

    // MARK: - Instancing

    public var instancing: Bool {
        get { configuration.rendering.instancing }
        set { configuration.rendering.instancing = newValue }
    }

    // MARK: - Lighting

    public var lighting: Bool {
        get { configuration.rendering.lighting }
        set { configuration.rendering.lighting = newValue }
    }

    public var lightCount: Int {
        get { configuration.rendering.lightCount }
        set { configuration.rendering.lightCount = newValue }
    }

    // MARK: - Shadows

    public var castShadow: Bool {
        get { configuration.rendering.castShadow }
        set { configuration.rendering.castShadow = newValue }
    }

    public var receiveShadow: Bool {
        get { configuration.rendering.receiveShadow }
        set { configuration.rendering.receiveShadow = newValue }
    }

    public var shadowCount: Int {
        get { configuration.rendering.shadowCount }
        set { configuration.rendering.shadowCount = newValue }
    }

    public var vertexDescriptor: MTLVertexDescriptor {
        get { configuration.rendering.vertexDescriptor }
        set { configuration.rendering.vertexDescriptor = newValue }
    }

    public var vertexFunctionName: String {
        get { configuration.vertexFunctionName }
        set { configuration.vertexFunctionName = newValue }
    }

    public var shadowFunctionName: String {
        get { configuration.shadowFunctionName }
        set { configuration.shadowFunctionName = newValue }
    }

    public var fragmentFunctionName: String {
        get { configuration.fragmentFunctionName }
        set { configuration.fragmentFunctionName = newValue }
    }

    public var context: Context? {
        didSet {
            if context != nil, context != oldValue {
                setup()
            }
        }
    }

    public var label: String {
        get {
            configuration.label
        }
        set {
            configuration.label = newValue
        }
    }

    public var definesNeedsUpdate = false
    public var constantsNeedsUpdate = false

    public var shadowPipelineNeedsUpdate = false
    public var pipelineNeedsUpdate = true
    public var parametersNeedsUpdate = true

    public let parametersPublisher = PassthroughSubject<ParameterGroup, Never>()

    public var parameters = ParameterGroup() {
        didSet { parametersPublisher.send(parameters) }
    }

    public required init(configuration: ShaderConfiguration) {
        self.configuration = configuration
    }

    public init(
        label: String,
        vertexFunctionName: String? = nil,
        fragmentFunctionName: String? = nil,
        shadowFunctionName: String? = nil,
        libraryURL: URL? = nil,
        pipelineURL: URL? = nil
    ) {
        configuration = ShaderConfiguration(
            label: label,
            vertexFunctionName: vertexFunctionName ?? label.camelCase + "Vertex",
            fragmentFunctionName: fragmentFunctionName ?? label.camelCase + "Fragment",
            shadowFunctionName: shadowFunctionName ?? label.camelCase + "ShadowVertex",
            libraryURL: libraryURL,
            pipelineURL: pipelineURL
        )
    }

    func setup() {
        configuration.context = context

        setupDefines()
        setupConstants()

        setupPipeline()
        setupShadowPipeline()
        setupParameters()
    }

    func update() {
        updateDefines()
        updateConstants()

        updatePipeline()
        updateShadowPipeline()
        updateParameters()
    }

    open func getDefines() -> [ShaderDefine] {
        return []
    }

    func setupDefines() {
        defines = getDefines()
        definesNeedsUpdate = false
    }

    func updateDefines() {
        if definesNeedsUpdate { setupDefines() }
    }

    open func getConstants() -> [String] {
        []
    }

    func setupConstants() {
        constants = getConstants()
        constantsNeedsUpdate = false
    }

    func updateConstants() {
        if constantsNeedsUpdate { setupConstants() }
    }

    func updatePipeline() {
        if pipelineNeedsUpdate { setupPipeline() }
    }

    func updateShadowPipeline() {
        if shadowPipelineNeedsUpdate { setupShadowPipeline() }
    }

    func updateParameters() {
        if parametersNeedsUpdate { setupParameters() }
    }

    deinit {
        pipeline = nil
        pipelineReflection = nil
        error = nil

        shadowPipeline = nil
        shadowPipelineReflection = nil
        shadowError = nil
    }

    open func makePipeline() throws -> (pipeline: MTLRenderPipelineState?, reflection: MTLRenderPipelineReflection?) {
        try ShaderPipelineCache.getPipeline(configuration: configuration)
    }

    func setupPipeline() {
        do {
            let result = try makePipeline()
            pipeline = result.pipeline
            pipelineReflection = result.reflection
            error = nil
        } catch {
            print("\(label) Shader Pipeline: \(error.localizedDescription)")
            self.error = error
            pipeline = nil
            pipelineReflection = nil
        }
        pipelineNeedsUpdate = false
    }

    func setupShadowPipeline() {
        guard castShadow else { return }

        do {
            shadowPipeline = try ShaderPipelineCache.getShadowPipeline(configuration: configuration)
            shadowError = nil
        } catch {
            print("\(label) Shadow Shader Pipeline: \(error.localizedDescription)")
            shadowError = error
            shadowPipeline = nil
        }

        shadowPipelineNeedsUpdate = false
    }

    func setupParameters() {
        do {
            if let pipelineParameters = try ShaderPipelineCache.getPipelineParameters(configuration: configuration) {
                parameters = pipelineParameters
            }
        } catch {
            print("\(label) Shader Parameters: \(error.localizedDescription)")
        }

        parametersNeedsUpdate = false
    }

    public func clone() -> Shader {
        print("Cloning Shader: \(label)")
        let clone: Shader = type(of: self).init(configuration: configuration)
        return clone
    }
}

extension Shader: Equatable {
    public static func == (lhs: Shader, rhs: Shader) -> Bool {
        return lhs === rhs
    }
}
