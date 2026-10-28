import Foundation
import Metal
import CoreGraphics
import CoreText
import AppKit

public final class TextRenderer: @unchecked Sendable {
    private let device: MTLDevice
    private var textureCache: [String: MTLTexture] = [:]

    public init(device: MTLDevice) {
        self.device = device
    }

    /// Converts text to a high-resolution GPU texture with CoreText (Retina-ready)
    public func createTextTexture(
        text: String,
        fontSize: CGFloat = 18.0,
        textColor: NSColor = .white,
        maxWidth: CGFloat = 800
    ) -> (texture: MTLTexture?, size: CGSize) {
        let cacheKey = "\(text)_\(fontSize)_\(textColor.hexValue)"
        if let cached = textureCache[cacheKey] {
            return (cached, CGSize(width: CGFloat(cached.width) / 2.0, height: CGFloat(cached.height) / 2.0))
        }

        let font = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        let attrString = NSAttributedString(string: text.isEmpty ? " " : text, attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)

        let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRangeMake(0, attrString.length),
            nil,
            CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
            nil
        )

        let scale: CGFloat = 2.0 // 2x for Retina displays
        let pixelWidth = max(Int(ceil(suggestedSize.width * scale)), 4)
        let pixelHeight = max(Int(ceil(suggestedSize.height * scale)), 4)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: pixelWidth * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return (nil, .zero)
        }

        context.scaleBy(x: scale, y: scale)
        let path = CGPath(rect: CGRect(origin: .zero, size: suggestedSize), transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attrString.length), path, nil)
        CTFrameDraw(frame, context)

        guard let pixelData = context.data else { return (nil, .zero) }

        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: pixelWidth,
            height: pixelHeight,
            mipmapped: false
        )
        desc.usage = [.shaderRead]

        guard let texture = device.makeTexture(descriptor: desc) else { return (nil, .zero) }

        texture.replace(
            region: MTLRegionMake2D(0, 0, pixelWidth, pixelHeight),
            mipmapLevel: 0,
            withBytes: pixelData,
            bytesPerRow: pixelWidth * 4
        )

        textureCache[cacheKey] = texture
        return (texture, suggestedSize)
    }
}

private extension NSColor {
    var hexValue: String {
        guard let rgb = usingColorSpace(.sRGB) else { return "000000" }
        return String(format: "%02X%02X%02X", Int(rgb.redComponent * 255), Int(rgb.greenComponent * 255), Int(rgb.blueComponent * 255))
    }
}
