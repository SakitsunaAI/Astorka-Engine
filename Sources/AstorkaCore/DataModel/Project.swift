import Foundation

public enum ProjectType: String, Codable, Sendable, CaseIterable {
    case cli = "CLI / Terminal Game"
    case ui = "UI Game"
    case world2D = "2D World Game"
}

public struct GameProject: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var type: ProjectType
    public var author: String
    public var version: String
    public var initialSceneId: String

    public var windowWidth: Double
    public var windowHeight: Double
    public var targetFPS: Int

    public var globalVariables: [GameVariable]
    public var dataTables: [DataTable]
    public var globalRules: [EventRule]
    public var scenes: [GameScene]

    public init(
        id: String = UUID().uuidString,
        title: String,
        type: ProjectType = .cli,
        author: String = "Astorka Developer",
        version: String = "1.0.0",
        initialSceneId: String = "",
        windowWidth: Double = 1280,
        windowHeight: Double = 800,
        targetFPS: Int = 120,
        globalVariables: [GameVariable] = [],
        dataTables: [DataTable] = [],
        globalRules: [EventRule] = [],
        scenes: [GameScene] = []
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.author = author
        self.version = version
        self.initialSceneId = initialSceneId
        self.windowWidth = windowWidth
        self.windowHeight = windowHeight
        self.targetFPS = targetFPS
        self.globalVariables = globalVariables
        self.dataTables = dataTables
        self.globalRules = globalRules
        self.scenes = scenes
    }

    /// Creates a completely blank, empty project
    public static func empty(title: String = "New Project", type: ProjectType = .cli) -> GameProject {
        let sceneType: SceneType
        switch type {
        case .cli: sceneType = .cliTerminal
        case .ui: sceneType = .uiCanvas
        case .world2D: sceneType = .world2D
        }

        let initialScene = GameScene(
            id: "main_scene",
            name: type == .cli ? "Main Terminal" : "Main Scene",
            type: sceneType,
            uiElements: [],
            sprites: [],
            rules: []
        )

        return GameProject(
            title: title,
            type: type,
            initialSceneId: "main_scene",
            globalVariables: [],
            dataTables: [],
            globalRules: [],
            scenes: [initialScene]
        )
    }

    /// Serialize to JSON data
    public func toJSONData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    /// Deserialize from JSON data
    public static func fromJSONData(_ data: Data) throws -> GameProject {
        let decoder = JSONDecoder()
        return try decoder.decode(GameProject.self, from: data)
    }
}
