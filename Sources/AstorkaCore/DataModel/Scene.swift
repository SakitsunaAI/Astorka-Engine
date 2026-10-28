import Foundation

public enum SceneType: String, Codable, Sendable {
    case uiCanvas    // For UI, cards, and simulation games
    case world2D     // For 2D grids, maps, and sprites
    case cliTerminal // For pure text, terminal, and CLI games
    case hybrid      // For combined 2D scene with UI overlay
}

public struct GameScene: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var type: SceneType
    public var backgroundColor: UIColorRGBA
    public var uiElements: [UIElement]
    public var sprites: [Sprite2D]
    public var rules: [EventRule]

    public init(
        id: String = UUID().uuidString,
        name: String,
        type: SceneType = .hybrid,
        backgroundColor: UIColorRGBA = UIColorRGBA(r: 0.08, g: 0.09, b: 0.12, a: 1.0),
        uiElements: [UIElement] = [],
        sprites: [Sprite2D] = [],
        rules: [EventRule] = []
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.backgroundColor = backgroundColor
        self.uiElements = uiElements
        self.sprites = sprites
        self.rules = rules
    }
}
