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

    open var pipelineOptions: MTLPipelineOption = [.argumentInfo, .bufferTypeInfo]
    open var pipelineReflection: MTLRenderPipelineReflection?

    public internal(set) var pipeline: MTLRenderPipelineState?
    public internal(set) var error: Error?

    // MARK: - Shadow Pipeline

    open var shadowPipelineOptions: MTLPipelineOption = [.argumentInfo, .bufferTypeInfo]
    open var shadowPipelineReflection: MTLRenderPipelineReflection?

    public internal(set) var shadowPipeline: MTLRenderPipelineState?
    public internal(set) var shadowError: Error?

    // MARK: - Blending

    public var configuration: ShaderConfiguration {
        didSet {
            if configuration != oldValue {
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
        get {
            configuration.constants
        }
        set {
            configuration.constants = newValue
        }
    }

    open var defines: [String: NSObject] {
        get {
            configuration.defines
        }
        set {
            configuration.defines = newValue
        }
    }

    // MARK: - Blending

    public var blending: Blending {
        get { configuration.blending.type }
        set { configuration.blending.type = newValue }
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
        get { configuration.blending.destinationRGBBlendFactor }
        set { configuration.blending.destinationRGBBlendFactor = newValue }
    }

    public var rgbBlendOperation: MTLBlendOperation {
        get { configuration.blending.rgbBlendOperation }
        set { configuration.blending.rgbBlendOperation = newValue }
    }

    public var alphaBlendOperation: MTLBlendOperation {
        get { configuration.blending.alphaBlendOperation }
        set { configuration.blending.alphaBlendOperation = newValue }
    }

    // MARK: - Instancing

    public var instancing: Bool {
        get { configuration.instancing }
        set { configuration.instancing = newValue }
    }

    // MARK: - Lighting

    public var lighting: Bool {
        get { configuration.lighting }
        set { configuration.lighting = newValue }
    }

    public var lightCount: Int {
        get { configuration.lightCount }
        set { configuration.lightCount = newValue }
    }

    // MARK: - Shadows

    public var castShadow: Bool {
        get { configuration.castShadow }
        set { configuration.castShadow = newValue }
    }

    public var receiveShadow: Bool {
        get { configuration.receiveShadow }
        set { configuration.receiveShadow = newValue }
    }

    public var shadowCount: Int {
        get { configuration.shadowCount }
        set { configuration.shadowCount = newValue }
    }

    public var vertexDescriptor: MTLVertexDescriptor {
        get { configuration.vertexDescriptor }
        set { configuration.vertexDescriptor = newValue }
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
            if oldValue != context { setup() }
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

    open func getDefines() -> [String: NSObject] {
        [:]
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

    func setupPipeline() {
        do {
            pipeline = try ShaderCache.getPipeline(configuration: configuration)
            error = nil
        } catch {
            self.error = error
            print("\(label) Shader Pipeline: \(error.localizedDescription)")
            pipeline = nil
        }
        pipelineNeedsUpdate = false
    }

    func setupShadowPipeline() {
        guard castShadow else { return }

        do {
            shadowPipeline = try ShaderCache.getShadowPipeline(configuration: configuration)
            shadowError = nil
        } catch {
            shadowError = error
            print("\(label) Shadow Shader Pipeline: \(error.localizedDescription)")
            shadowPipeline = nil
        }

        shadowPipelineNeedsUpdate = false
    }

    func setupParameters() {
        do {
            if let pipelineParameters = try ShaderCache.getPipelineParameters(configuration: configuration) {
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
