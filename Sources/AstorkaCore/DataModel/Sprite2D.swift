import Foundation

public struct Sprite2D: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public var rotation: Double // Derece
    public var scaleX: Double
    public var scaleY: Double
    public var zIndex: Int
    public var textureName: String
    public var tintColor: UIColorRGBA
    public var opacity: Float
    public var isVisible: Bool
    public var tag: String
    public var customProperties: [String: String]

    public init(
        id: String = UUID().uuidString,
        name: String,
        x: Double = 0,
        y: Double = 0,
        width: Double = 64,
        height: Double = 64,
        rotation: Double = 0,
        scaleX: Double = 1.0,
        scaleY: Double = 1.0,
        zIndex: Int = 0,
        textureName: String = "",
        tintColor: UIColorRGBA = .white,
        opacity: Float = 1.0,
        isVisible: Bool = true,
        tag: String = "",
        customProperties: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.rotation = rotation
        self.scaleX = scaleX
        self.scaleY = scaleY
        self.zIndex = zIndex
        self.textureName = textureName
        self.tintColor = tintColor
        self.opacity = opacity
        self.isVisible = isVisible
        self.tag = tag
        self.customProperties = customProperties
    }
}
