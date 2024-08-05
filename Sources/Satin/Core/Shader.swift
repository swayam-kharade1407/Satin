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

    public internal(set) var pipelines: [Context: MTLRenderPipelineState] = [:]
    public internal(set) var error: Error?

    open var pipelineOptions: MTLPipelineOption = [.argumentInfo, .bufferTypeInfo]
    open var pipelineReflection: MTLRenderPipelineReflection? {
        didSet {
            guard let pipelineReflection else { return }

            for binding in pipelineReflection.vertexBindings where binding.type == .buffer {
                if binding.index == VertexBufferIndex.VertexUniforms.rawValue {
                    vertexWantsVertexUniforms = binding.isUsed
                }

                if binding.index == VertexBufferIndex.MaterialUniforms.rawValue {
                    vertexWantsMaterialUniforms = binding.isUsed
                }
            }

            for binding in pipelineReflection.fragmentBindings where binding.type == .buffer {
                if binding.index == FragmentBufferIndex.VertexUniforms.rawValue {
                    fragmentWantsVertexUniforms = binding.isUsed
                }

                if binding.index == FragmentBufferIndex.MaterialUniforms.rawValue {
                    fragmentWantsMaterialUniforms = binding.isUsed
                }
            }
        }
    }

    // MARK: - Shadow Pipeline

    open var shadowPipelineOptions: MTLPipelineOption = [.argumentInfo, .bufferTypeInfo]
    open var shadowPipelineReflection: MTLRenderPipelineReflection?

    public internal(set) var shadowPipelines: [Context: MTLRenderPipelineState] = [:]
    public internal(set) var shadowError: Error?

    public internal(set) var vertexWantsVertexUniforms: Bool = false
    public internal(set) var vertexWantsMaterialUniforms: Bool = false

    public internal(set) var fragmentWantsVertexUniforms: Bool = false
    public internal(set) var fragmentWantsMaterialUniforms: Bool = false

    public var context: Context? {
        didSet {
            if context != nil, context != oldValue {
                setup()
            }
        }
    }

    // MARK: - Configurations

    public internal(set) var configurations: [Context: ShaderConfiguration] = [:]

    public internal(set) var configuration: ShaderConfiguration

    var libraryURL: URL? {
        get {
            configuration.libraryURL
        }
        set {
            if configuration.libraryURL != newValue {
                configuration.libraryURL = newValue
                configurationNeedsUpdate = true
            }
        }
    }

    open var constants: [String] {
        get {
            configuration.rendering.constants
        }
        set {
            if configuration.constants != newValue {
                configuration.constants = newValue
                configurationNeedsUpdate = true
            }
        }
    }

    open var defines: [ShaderDefine] {
        get {
            configuration.rendering.defines
        }
        set {
            if configuration.defines != newValue {
                configuration.defines = newValue
                configurationNeedsUpdate = true
            }
        }
    }

    // MARK: - Blending

    public var blending: Blending {
        get {
            configuration.rendering.blending.type
        }
        set {
            if configuration.rendering.blending.type != newValue {
                configuration.rendering.blending.type = newValue
                configurationNeedsUpdate = true
            }
        }
    }

    public var sourceRGBBlendFactor: MTLBlendFactor {
        get {
            configuration.rendering.blending.sourceRGBBlendFactor
        }
        set {
            if configuration.rendering.blending.sourceRGBBlendFactor != newValue {
                configuration.rendering.blending.sourceRGBBlendFactor = newValue
                configurationNeedsUpdate = true
            }
        }
    }

    public var sourceAlphaBlendFactor: MTLBlendFactor {
        get {
            configuration.rendering.blending.sourceAlphaBlendFactor
        }
        set {
            if configuration.rendering.blending.sourceAlphaBlendFactor != newValue {
                configuration.rendering.blending.sourceAlphaBlendFactor = newValue
                configurationNeedsUpdate = true
            }
        }
    }

    public var destinationRGBBlendFactor: MTLBlendFactor {
        get {
            configuration.rendering.blending.destinationRGBBlendFactor
        }
        set {
            if configuration.rendering.blending.destinationRGBBlendFactor != newValue {
                configuration.rendering.blending.destinationRGBBlendFactor = newValue
                configurationNeedsUpdate = true
            }
        }
    }

    public var destinationAlphaBlendFactor: MTLBlendFactor {
        get {
            configuration.rendering.blending.destinationRGBBlendFactor
        }
        set {
            if configuration.rendering.blending.destinationRGBBlendFactor != newValue {
                configuration.rendering.blending.destinationRGBBlendFactor = newValue
                configurationNeedsUpdate = true
            }
        }
    }

    public var rgbBlendOperation: MTLBlendOperation {
        get {
            configuration.rendering.blending.rgbBlendOperation
        }
        set {
            if configuration.rendering.blending.rgbBlendOperation != newValue {
                configuration.rendering.blending.rgbBlendOperation = newValue
                configurationNeedsUpdate = true
            }
        }
    }

    public var alphaBlendOperation: MTLBlendOperation {
        get {
            configuration.rendering.blending.alphaBlendOperation
        }
        set {
            if configuration.rendering.blending.alphaBlendOperation != newValue {
                configuration.rendering.blending.alphaBlendOperation = newValue
                configurationNeedsUpdate = true
            }
        }
    }

    // MARK: - Instancing

    public var instancing: Bool {
        get {
            configuration.rendering.instancing
        }
        set {
            if configuration.rendering.instancing != newValue {
                configuration.rendering.instancing = newValue
                configurationNeedsUpdate = true
            }
        }
    }

    // MARK: - Lighting

    public var lighting: Bool {
        get {
            configuration.rendering.lighting
        }
        set {
            if configuration.rendering.lighting != newValue {
                configuration.rendering.lighting = newValue
                configurationNeedsUpdate = true
            }
        }
    }

    public var lightCount: Int {
        get {
            configuration.rendering.lightCount
        }
        set {
            if configuration.rendering.lightCount != newValue {
                configuration.rendering.lightCount = newValue
                configurationNeedsUpdate = true
            }
        }
    }

    // MARK: - Shadows

    public var castShadow: Bool {
        get {
            configuration.rendering.castShadow
        }
        set {
            if configuration.rendering.castShadow != newValue {
                configuration.rendering.castShadow = newValue
                configurationNeedsUpdate = true
            }
        }
    }

    public var receiveShadow: Bool {
        get {
            configuration.rendering.receiveShadow
        }
        set {
            if configuration.rendering.receiveShadow != newValue {
                configuration.rendering.receiveShadow = newValue
                configurationNeedsUpdate = true
            }
        }
    }

    public var shadowCount: Int {
        get {
            configuration.rendering.shadowCount
        }
        set {
            if configuration.rendering.shadowCount != newValue {
                configuration.rendering.shadowCount = newValue
                configurationNeedsUpdate = true
            }
        }
    }

    public var vertexDescriptor: MTLVertexDescriptor {
        get {
            configuration.rendering.vertexDescriptor
        }
        set {
            if configuration.rendering.vertexDescriptor != newValue {
                configuration.rendering.vertexDescriptor = newValue
                configurationNeedsUpdate = true
            }
        }
    }

    public var vertexFunctionName: String {
        get {
            configuration.vertexFunctionName
        }
        set {
            if configuration.vertexFunctionName != newValue {
                configuration.vertexFunctionName = newValue
                configurationNeedsUpdate = true
            }
        }
    }

    public var shadowFunctionName: String {
        get {
            configuration.shadowFunctionName
        }
        set {
            if configuration.shadowFunctionName != newValue {
                configuration.shadowFunctionName = newValue
                configurationNeedsUpdate = true
            }
        }
    }

    public var fragmentFunctionName: String {
        get {
            configuration.fragmentFunctionName
        }
        set {
            if configuration.fragmentFunctionName != newValue {
                configuration.fragmentFunctionName = newValue
                configurationNeedsUpdate = true
            }
        }
    }

    public var label: String {
        get {
            configuration.label
        }
        set {
            if configuration.label != newValue {
                configuration.label = newValue
                configurationNeedsUpdate = true
                parametersNeedsUpdate = true
            }
        }
    }

    public var configurationNeedsUpdate = true {
        didSet {
            if configurationNeedsUpdate {
                configurations.removeAll()
                pipelines.removeAll()
                shadowPipelines.removeAll()
            }
        }
    }

    public var definesNeedsUpdate = true {
        didSet {
            if definesNeedsUpdate {
                configurationNeedsUpdate = true
            }
        }
    }

    public var constantsNeedsUpdate = true {
        didSet {
            if constantsNeedsUpdate {
                configurationNeedsUpdate = true
            }
        }
    }

    public var shadowPipelineNeedsUpdate = false
    public var pipelineNeedsUpdate = true
    public var parametersNeedsUpdate = true

    public let parametersPublisher = PassthroughSubject<ParameterGroup, Never>()

    public var parameters: ParameterGroup? {
        didSet {
            if let parameters {
                parametersPublisher.send(parameters)
            }
        }
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
        updateDefines()
        updateConstants()

        setupConfiguration()

        setupPipeline()
        setupShadowPipeline()
        updateParameters()
    }

    func update() {
        updateDefines()
        updateConstants()

        updateConfiguration()

        updatePipeline()
        updateShadowPipeline()
        updateParameters()
    }

    // MARK: - Configuration

    func setupConfiguration() {
        guard let context = context, configurations[context] == nil else { return }

        configuration.context = context
        configurations[context] = configuration

        pipelineNeedsUpdate = true

        if configuration.rendering.castShadow {
            shadowPipelineNeedsUpdate = true
        }

        configurationNeedsUpdate = false
    }

    func updateConfiguration() {
        if configurationNeedsUpdate {
            setupConfiguration()
        }
    }

    // MARK: - Defines

    open func getDefines() -> [ShaderDefine] {
        return []
    }

    func updateDefines() {
        guard definesNeedsUpdate else { return }
        defines = getDefines()
        definesNeedsUpdate = false
    }

    // MARK: - Constants

    open func getConstants() -> [String] {
        []
    }

    func updateConstants() {
        guard constantsNeedsUpdate else { return }
        constants = getConstants()
        constantsNeedsUpdate = false
    }

    // MARK: - Parameters

    func updateParameters() {
        guard parametersNeedsUpdate else { return }
        do {
            if let pipelineParameters = try ShaderPipelineCache.getPipelineParameters(configuration: configuration) {
                parameters = pipelineParameters
            }
        } catch {
            print("\(label) Shader Parameters: \(error.localizedDescription)")
            if let url = configuration.pipelineURL {
                print("\(label) Shader Path: \(url.path)")
            }
        }

        parametersNeedsUpdate = false
    }

    // MARK: - Pipelines

    open func getPipeline(renderContext: Context, shadow: Bool) -> MTLRenderPipelineState? {
        shadow ? shadowPipelines[renderContext] : pipelines[renderContext]
    }

    func updatePipeline() {
        if pipelineNeedsUpdate {
            setupPipeline()
        }
    }

    open func makePipeline() throws -> (pipeline: MTLRenderPipelineState?, reflection: MTLRenderPipelineReflection?) {
        try ShaderPipelineCache.getPipeline(configuration: configuration)
    }

    func setupPipeline() {
        guard let context, pipelines[context] == nil else { return }
        do {
            let result = try makePipeline()
            pipelines[context] = result.pipeline
            pipelineReflection = result.reflection
            error = nil
        } catch {
            print("\(label) Shader Pipeline: \(error.localizedDescription)")
            if let url = configuration.pipelineURL {
                print("\(label) Shader Path: \(url.path)")
            }
            self.error = error
            pipelineReflection = nil
            pipelines[context] = nil
        }
        pipelineNeedsUpdate = false
    }

    func updateShadowPipeline() {
        if shadowPipelineNeedsUpdate {
            setupShadowPipeline()
        }
    }

    open func makeShadowPipeline() throws -> MTLRenderPipelineState? {
        try ShaderPipelineCache.getShadowPipeline(configuration: configuration)
    }

    func setupShadowPipeline() {
        guard let context, shadowPipelines[context] == nil, castShadow else { return }
        do {
            shadowPipelines[context] = try makeShadowPipeline()
            shadowError = nil
        } catch {
            print("\(label) Shadow Shader Pipeline: \(error.localizedDescription)")
            if let url = configuration.pipelineURL {
                print("\(label) Shader Path: \(url.path)")
            }
            shadowError = error
            shadowPipelines[context] = nil
        }

        shadowPipelineNeedsUpdate = false
    }

    deinit {
        configurations.removeAll()

        pipelines.removeAll()
        pipelineReflection = nil
        error = nil

        shadowPipelines.removeAll()
        shadowPipelineReflection = nil
        shadowError = nil
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
