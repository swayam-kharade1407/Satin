//
//  TextureComputeSystem.swift
//  Satin
//
//  Created by Reza Ali on 7/22/20.
//

import Metal

open class TextureComputeSystem: ComputeSystem {
    override var prefix: String {
        var prefix = String(describing: type(of: self)).replacingOccurrences(of: "TextureComputeSystem", with: "")
        prefix = prefix.replacingOccurrences(of: "ComputeSystem", with: "")
        if let bundleName = Bundle(for: type(of: self)).displayName, bundleName != prefix {
            prefix = prefix.replacingOccurrences(of: bundleName, with: "")
        }
        prefix = prefix.replacingOccurrences(of: ".", with: "")
        return prefix
    }

    public var textureDescriptors: [MTLTextureDescriptor] {
        didSet {
            resetTextures()
        }
    }

    public var srcTexture: MTLTexture? {
        textures[srcIndex]
    }

    public var dstTexture: MTLTexture? {
        textures[dstIndex]
    }

    public var srcTextures: [MTLTexture] {
        var results: [MTLTexture] = []
        var textureIndex = 0
        for _ in textureDescriptors {
            results.append(textures[textureIndex + srcIndex])
            textureIndex += feedbackCount
        }
        return results
    }

    public var dstTextures: [MTLTexture] {
        var results: [MTLTexture] = []
        var textureIndex = 0
        for _ in textureDescriptors {
            results.append(textures[textureIndex + dstIndex])
            textureIndex += feedbackCount
        }
        return results
    }

    public var textures: [MTLTexture] = []
    private var _setupSize = true
    private var _setupTextures = true
    private var _setupDescriptors = true

    public init(device: MTLDevice, pipelineURL: URL, textureDescriptors: [MTLTextureDescriptor], feedback: Bool = false, live: Bool = false) {
        self.textureDescriptors = textureDescriptors
        super.init(device: device, pipelineURL: pipelineURL, feedback: feedback, live: live)
    }

    public init(device: MTLDevice, pipelinesURL: URL, textureDescriptors: [MTLTextureDescriptor], feedback: Bool = false, live: Bool = false) {
        self.textureDescriptors = textureDescriptors
        super.init(device: device, pipelinesURL: pipelinesURL, feedback: feedback, live: live)
    }

    override open func setup() {
        super.setup()
        setupDescriptor()
        setupTextures()
        setupSize()
    }

    override open func update() {
        updateDescriptor()
        updateTextures()
        updateSize()
        super.update()
    }

    // MARK: - Descriptors

    private func setupDescriptor() {
        for textureDescriptor in textureDescriptors {
            if !textureDescriptor.usage.contains(.shaderWrite) {
                textureDescriptor.usage = [textureDescriptor.usage, .shaderWrite]
            }
            if feedback, !textureDescriptor.usage.contains(.shaderRead) {
                textureDescriptor.usage = [textureDescriptor.usage, .shaderRead]
            }
        }

        _setupDescriptors = false
    }

    private func updateDescriptor() {
        if _setupDescriptors {
            setupDescriptor()
        }
    }

    // MARK: - Textures

    open func setupTextures() {
        textures = []

        for textureDescriptor in textureDescriptors {
            for i in 0 ..< feedbackCount {
                if let texture = device.makeTexture(descriptor: textureDescriptor) {
                    texture.label = label + " Texture \(i)"
                    textures.append(texture)
                }
            }
        }

        _index = 0
        _setupTextures = false
    }

    private func updateTextures() {
        if _setupTextures {
            setupTextures()
        }
    }

    // MARK: - Size

    private func setupSize() {
        guard let txDsx = textureDescriptors.first else { return }

        if txDsx.textureType == .type1D {
            parameters.set("Size", txDsx.width)
        }
        else if txDsx.textureType == .type2D {
            parameters.set("Size", [txDsx.width, txDsx.height])
        }
        else if txDsx.textureType == .type3D {
            parameters.set("Size", [txDsx.width, txDsx.height, txDsx.depth])
        }

        _setupSize = false
    }

    private func updateSize() {
        if _setupSize {
            setupSize()
        }
    }

    // MARK: - Reset

    override open func update(_ commandBuffer: MTLCommandBuffer) {
        super.update(commandBuffer)

        if textures.count > 0, let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
            computeEncoder.label = label
            encode(computeEncoder)
            computeEncoder.endEncoding()
        }
    }

    override open func update(_ computeEncoder: MTLComputeCommandEncoder) {
        super.update(computeEncoder)

        if textures.count > 0 {
            encode(computeEncoder)
        }
    }

    // MARK: - Binding & Encoding

    open func bind(_ computeEncoder: MTLComputeCommandEncoder) -> Int {
        bindTextures(computeEncoder, ComputeTextureIndex.Custom0.rawValue)
    }

    private func encode(_ computeEncoder: MTLComputeCommandEncoder) {
        bindUniforms(computeEncoder)
        bindTextures(computeEncoder)

        if _reset, let pipeline = resetPipeline {
            computeEncoder.setComputePipelineState(pipeline)

            for _ in 0 ..< feedbackCount {
                var offset = bind(computeEncoder)
                preReset?(computeEncoder, &offset)
                preCompute?(computeEncoder, &offset)
                dispatch(computeEncoder, pipeline)
                swapSrdDstIndex()
            }

            _reset = false
        }

        if let pipeline = updatePipeline {
            computeEncoder.setComputePipelineState(pipeline)
            var offset = bind(computeEncoder)
            preUpdate?(computeEncoder, &offset)
            preCompute?(computeEncoder, &offset)
            dispatch(computeEncoder, pipeline)
            swapSrdDstIndex()
        }
    }

    private func bindTextures(_ computeEncoder: MTLComputeCommandEncoder, _ offset: Int) -> Int {
        var index = offset
        var textureIndex = 0

        if feedback {
            for _ in textureDescriptors {
                computeEncoder.setTexture(textures[textureIndex + srcIndex], index: index)
                index += 1
                computeEncoder.setTexture(textures[textureIndex + dstIndex], index: index)
                index += 1
                textureIndex += 2
            }
        } else {
            for _ in textureDescriptors {
                computeEncoder.setTexture(textures[textureIndex], index: index)
                textureIndex += 1
                index += 1
            }
        }

        return index
    }

    // MARK: - Dispatching

    open func getThreadsPerGrid(_ texture: MTLTexture) -> MTLSize {
        MTLSize(width: texture.width, height: texture.height, depth: texture.depth)
    }

    open func getThreadGroupsPerGrid(_ texture: MTLTexture, _ pipeline: MTLComputePipelineState) -> MTLSize {
        let threadExecutionWidth = pipeline.threadExecutionWidth
        let maxTotalThreadsPerThreadgroup = pipeline.maxTotalThreadsPerThreadgroup

        if texture.depth > 1 {
            var w = Int(pow(Float(maxTotalThreadsPerThreadgroup), 1.0 / 3.0))
            if w > threadExecutionWidth {
                w = threadExecutionWidth
            }

            let threadgroupsPerGrid = MTLSize(width: (texture.width + w - 1) / w,
                                              height: (texture.height + w - 1) / w,
                                              depth: (texture.depth + w - 1) / w)

            return threadgroupsPerGrid

        } else {
            let w = threadExecutionWidth
            let h = maxTotalThreadsPerThreadgroup / w

            let threadgroupsPerGrid = MTLSize(width: (texture.width + w - 1) / w,
                                              height: (texture.height + h - 1) / h,
                                              depth: 1)

            return threadgroupsPerGrid
        }
    }

    open func getThreadsPerThreadgroup(_ texture: MTLTexture, _ pipeline: MTLComputePipelineState) -> MTLSize {
        let threadExecutionWidth = pipeline.threadExecutionWidth
        let maxTotalThreadsPerThreadgroup = pipeline.maxTotalThreadsPerThreadgroup
        if texture.depth > 1 {
            var w = Int(pow(Float(maxTotalThreadsPerThreadgroup), 1.0 / 3.0))
            if w > threadExecutionWidth {
                w = threadExecutionWidth
            }
            let threadsPerThreadgroup = MTLSizeMake(w, w, w)
            return threadsPerThreadgroup

        } else if texture.height > 1 {
            return MTLSizeMake(threadExecutionWidth, maxTotalThreadsPerThreadgroup / threadExecutionWidth, 1)
        }
        else {
            return MTLSizeMake(threadExecutionWidth, 1, 1)
        }
    }

    #if os(macOS) || os(iOS) || os(visionOS)
    override open func dispatchThreads(_ computeEncoder: MTLComputeCommandEncoder, _ pipeline: MTLComputePipelineState) {
        guard let texture = textures.first else { return }

        let threadPerGrid = getThreadsPerGrid(texture)
        let threadsPerThreadgroup = getThreadsPerThreadgroup(texture, pipeline)

        computeEncoder.dispatchThreads(threadPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
    }
    #endif

    override open func dispatchThreadgroups(_ computeEncoder: MTLComputeCommandEncoder, _ pipeline: MTLComputePipelineState) {
        guard let texture = textures.first else { return }

        let threadsPerThreadGroup = getThreadsPerThreadgroup(texture, pipeline)
        let threadGroupsPerGrid = getThreadGroupsPerGrid(texture, pipeline)

        computeEncoder.dispatchThreadgroups(threadGroupsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
    }

    // MARK: - Reset

    open func resetTextures() {
        reset()
        _setupDescriptors = true
        _setupTextures = true
        _setupSize = true
    }

    // MARK: - Deinit

    deinit {
        textures = []
    }
}
