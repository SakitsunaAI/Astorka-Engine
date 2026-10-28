import Foundation
import Metal
import MetalKit
import simd

public struct MetalVertex {
    public var position: simd_float2
    public var uv: simd_float2
    public var color: simd_float4

    public init(position: simd_float2, uv: simd_float2, color: simd_float4) {
        self.position = position
        self.uv = uv
        self.color = color
    }
}

public struct FrameUniforms {
    public var viewportSize: simd_float2
    public var time: Float
    public var postProcessMode: Int32

    public init(viewportSize: simd_float2, time: Float, postProcessMode: Int32 = 0) {
        self.viewportSize = viewportSize
        self.time = time
        self.postProcessMode = postProcessMode
    }
}

public final class Metal2DRenderer: @unchecked Sendable {
    public let device: MTLDevice
    public let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState?
    private var samplerState: MTLSamplerState?
    public let textRenderer: TextRenderer

    // 1x1 solid white texture for drawing solid colors with Metal
    private var defaultWhiteTexture: MTLTexture?

    public init?(device: MTLDevice? = MTLCreateSystemDefaultDevice()) {
        guard let dev = device, let queue = dev.makeCommandQueue() else {
            return nil
        }
        self.device = dev
        self.commandQueue = queue
        self.textRenderer = TextRenderer(device: dev)

        setupPipeline()
        setupDefaultTexture()
    }

    private func setupPipeline() {
        do {
            let library = try device.makeLibrary(source: MetalShaders.sourceCode, options: nil)
            let vertexFunction = library.makeFunction(name: "vertex_main")
            let fragmentFunction = library.makeFunction(name: "fragment_main")

            let pipelineDesc = MTLRenderPipelineDescriptor()
            pipelineDesc.vertexFunction = vertexFunction
            pipelineDesc.fragmentFunction = fragmentFunction
            pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm

            // Alpha Blending (transparency and smooth edges)
            pipelineDesc.colorAttachments[0].isBlendingEnabled = true
            pipelineDesc.colorAttachments[0].rgbBlendOperation = .add
            pipelineDesc.colorAttachments[0].alphaBlendOperation = .add
            pipelineDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            pipelineDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            pipelineDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
            pipelineDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDesc)

            let samplerDesc = MTLSamplerDescriptor()
            samplerDesc.minFilter = .linear
            samplerDesc.magFilter = .linear
            samplerState = device.makeSamplerState(descriptor: samplerDesc)
        } catch {
            print("⚠️ [Astorka Metal] Failed to create pipeline: \(error)")
        }
    }

    private func setupDefaultTexture() {
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 1, height: 1, mipmapped: false)
        desc.usage = [.shaderRead]
        if let tex = device.makeTexture(descriptor: desc) {
            var whitePixel: UInt32 = 0xFFFFFFFF
            tex.replace(region: MTLRegionMake2D(0, 0, 1, 1), mipmapLevel: 0, withBytes: &whitePixel, bytesPerRow: 4)
            self.defaultWhiteTexture = tex
        }
    }

    /// Renders a scene using Metal Render Command Encoder
    public func renderScene(
        scene: GameScene,
        variables: [String: VariableValue],
        viewportSize: CGSize,
        time: Float,
        postProcessMode: Int32,
        renderPassDescriptor: MTLRenderPassDescriptor,
        drawable: CAMetalDrawable
    ) {
        guard let pipelineState = self.pipelineState,
              let samplerState = self.samplerState,
              let defaultTex = self.defaultWhiteTexture else { return }

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentSamplerState(samplerState, index: 0)

        var uniforms = FrameUniforms(
            viewportSize: simd_float2(Float(viewportSize.width), Float(viewportSize.height)),
            time: time,
            postProcessMode: postProcessMode
        )
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<FrameUniforms>.stride, index: 1)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<FrameUniforms>.stride, index: 1)

        // 1. Render Sprites
        for sprite in scene.sprites where sprite.isVisible {
            drawQuad(
                rect: CGRect(x: sprite.x, y: sprite.y, width: sprite.width, height: sprite.height),
                color: sprite.tintColor,
                texture: defaultTex,
                encoder: encoder
            )
        }

        // 2. Render UI Elements (Panel, Button, Card, Gauge)
        for element in scene.uiElements where element.isVisible {
            drawUIElement(element, variables: variables, viewportSize: viewportSize, encoder: encoder)
        }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    public func drawUIElement(
        _ element: UIElement,
        variables: [String: VariableValue],
        viewportSize: CGSize,
        encoder: MTLRenderCommandEncoder
    ) {
        guard let defaultTex = self.defaultWhiteTexture else { return }

        // Calculate coordinates
        let rect = calculateElementRect(element, in: viewportSize)

        // Panel / Button Background
        drawQuad(rect: rect, color: element.style.backgroundColor, texture: defaultTex, encoder: encoder)

        // Border
        if element.style.borderWidth > 0 {
            drawBorder(rect: rect, width: CGFloat(element.style.borderWidth), color: element.style.borderColor, texture: defaultTex, encoder: encoder)
        }

        // Text Rendering
        var displayText = element.text
        if let binding = element.bindingVariable, let val = variables[binding] {
            displayText = "\(element.text) \(val.asString)"
        }

        if !displayText.isEmpty {
            let textColor = NSColor(
                red: CGFloat(element.style.textColor.r),
                green: CGFloat(element.style.textColor.g),
                blue: CGFloat(element.style.textColor.b),
                alpha: CGFloat(element.style.textColor.a)
            )
            let (tex, size) = textRenderer.createTextTexture(text: displayText, fontSize: CGFloat(element.style.fontSize), textColor: textColor)
            if let textTex = tex {
                let textRect = CGRect(
                    x: rect.midX - size.width / 2.0,
                    y: rect.midY - size.height / 2.0,
                    width: size.width,
                    height: size.height
                )
                drawQuad(rect: textRect, color: .white, texture: textTex, encoder: encoder)
            }
        }
    }

    private func drawBorder(rect: CGRect, width: CGFloat, color: UIColorRGBA, texture: MTLTexture, encoder: MTLRenderCommandEncoder) {
        // Top, bottom, left, right border lines
        drawQuad(rect: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: width), color: color, texture: texture, encoder: encoder)
        drawQuad(rect: CGRect(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width), color: color, texture: texture, encoder: encoder)
        drawQuad(rect: CGRect(x: rect.minX, y: rect.minY, width: width, height: rect.height), color: color, texture: texture, encoder: encoder)
        drawQuad(rect: CGRect(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height), color: color, texture: texture, encoder: encoder)
    }

    private func calculateElementRect(_ element: UIElement, in viewportSize: CGSize) -> CGRect {
        var x = element.x
        var y = element.y

        switch element.anchor {
        case .topLeft: break
        case .topCenter: x += (viewportSize.width - element.width) / 2.0
        case .topRight: x = viewportSize.width - element.width - x
        case .centerLeft: y += (viewportSize.height - element.height) / 2.0
        case .center:
            x += (viewportSize.width - element.width) / 2.0
            y += (viewportSize.height - element.height) / 2.0
        case .centerRight:
            x = viewportSize.width - element.width - x
            y += (viewportSize.height - element.height) / 2.0
        case .bottomLeft: y = viewportSize.height - element.height - y
        case .bottomCenter:
            x += (viewportSize.width - element.width) / 2.0
            y = viewportSize.height - element.height - y
        case .bottomRight:
            x = viewportSize.width - element.width - x
            y = viewportSize.height - element.height - y
        case .stretch:
            return CGRect(x: 0, y: 0, width: viewportSize.width, height: viewportSize.height)
        }

        return CGRect(x: x, y: y, width: element.width, height: element.height)
    }

    public func drawQuad(
        rect: CGRect,
        color: UIColorRGBA,
        texture: MTLTexture,
        encoder: MTLRenderCommandEncoder
    ) {
        let x0 = Float(rect.minX)
        let y0 = Float(rect.minY)
        let x1 = Float(rect.maxX)
        let y1 = Float(rect.maxY)

        let c = simd_float4(color.r, color.g, color.b, color.a)

        let vertices: [MetalVertex] = [
            MetalVertex(position: simd_float2(x0, y0), uv: simd_float2(0, 0), color: c),
            MetalVertex(position: simd_float2(x1, y0), uv: simd_float2(1, 0), color: c),
            MetalVertex(position: simd_float2(x0, y1), uv: simd_float2(0, 1), color: c),

            MetalVertex(position: simd_float2(x1, y0), uv: simd_float2(1, 0), color: c),
            MetalVertex(position: simd_float2(x1, y1), uv: simd_float2(1, 1), color: c),
            MetalVertex(position: simd_float2(x0, y1), uv: simd_float2(0, 1), color: c),
        ]

        encoder.setVertexBytes(vertices, length: MemoryLayout<MetalVertex>.stride * vertices.count, index: 0)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}
