import Foundation

public enum UIElementType: String, Codable, Sendable {
    case button
    case label
    case gaugeBar
    case cardView
    case cardSlot
    case panel
    case textInput
    case inventoryGrid
    case dialogueBox
    case cliWindow
}

public enum UIAnchor: String, Codable, Sendable {
    case topLeft
    case topCenter
    case topRight
    case centerLeft
    case center
    case centerRight
    case bottomLeft
    case bottomCenter
    case bottomRight
    case stretch
}

public struct UIColorRGBA: Codable, Equatable, Sendable {
    public var r: Float
    public var g: Float
    public var b: Float
    public var a: Float

    public init(r: Float, g: Float, b: Float, a: Float = 1.0) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }

    public static let clear = UIColorRGBA(r: 0, g: 0, b: 0, a: 0)
    public static let white = UIColorRGBA(r: 1, g: 1, b: 1, a: 1)
    public static let black = UIColorRGBA(r: 0, g: 0, b: 0, a: 1)
    public static let red = UIColorRGBA(r: 0.9, g: 0.2, b: 0.2, a: 1)
    public static let green = UIColorRGBA(r: 0.2, g: 0.8, b: 0.3, a: 1)
    public static let blue = UIColorRGBA(r: 0.1, g: 0.5, b: 0.9, a: 1)
    public static let yellow = UIColorRGBA(r: 0.95, g: 0.75, b: 0.1, a: 1)
    public static let darkPanel = UIColorRGBA(r: 0.12, g: 0.14, b: 0.18, a: 0.92)
    public static let accentGold = UIColorRGBA(r: 0.96, g: 0.71, b: 0.22, a: 1)
}

public struct UIStyle: Codable, Equatable, Sendable {
    public var backgroundColor: UIColorRGBA
    public var borderColor: UIColorRGBA
    public var borderWidth: Float
    public var cornerRadius: Float
    public var textColor: UIColorRGBA
    public var fontSize: Float
    public var opacity: Float

    public init(
        backgroundColor: UIColorRGBA = .darkPanel,
        borderColor: UIColorRGBA = .white,
        borderWidth: Float = 1.0,
        cornerRadius: Float = 8.0,
        textColor: UIColorRGBA = .white,
        fontSize: Float = 16.0,
        opacity: Float = 1.0
    ) {
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.textColor = textColor
        self.fontSize = fontSize
        self.opacity = opacity
    }
}

public struct UIElement: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var type: UIElementType
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public var anchor: UIAnchor
    public var zIndex: Int

    public var text: String
    public var subtitle: String
    public var icon: String
    public var bindingVariable: String? // Automatic variable binding (e.g. "Player_HP")
    public var style: UIStyle

    public var isVisible: Bool
    public var isEnabled: Bool

    // Dynamic runtime properties
    public var customProperties: [String: String]

    public init(
        id: String,
        name: String,
        type: UIElementType,
        x: Double = 0,
        y: Double = 0,
        width: Double = 120,
        height: Double = 44,
        anchor: UIAnchor = .center,
        zIndex: Int = 0,
        text: String = "",
        subtitle: String = "",
        icon: String = "",
        bindingVariable: String? = nil,
        style: UIStyle = UIStyle(),
        isVisible: Bool = true,
        isEnabled: Bool = true,
        customProperties: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.anchor = anchor
        self.zIndex = zIndex
        self.text = text
        self.subtitle = subtitle
        self.icon = icon
        self.bindingVariable = bindingVariable
        self.style = style
        self.isVisible = isVisible
        self.isEnabled = isEnabled
        self.customProperties = customProperties
    }
}
