import Foundation
import CoreGraphics

public final class AstorkaGameRuntime: @unchecked Sendable, RuleEngineDelegate {
    public let project: GameProject
    public let ruleEngine: RuleEngine
    public let audioManager: AudioManager
    public let inputManager: InputManager

    public private(set) var currentScene: GameScene?
    public var onSceneChanged: ((GameScene) -> Void)?
    public var onPrintCLI: ((String, String?) -> Void)?

    public init(project: GameProject) {
        self.project = project
        self.ruleEngine = RuleEngine()
        self.audioManager = AudioManager.shared
        self.inputManager = InputManager.shared

        self.ruleEngine.delegate = self
        setupProject()
    }

    private func setupProject() {
        ruleEngine.loadVariables(project.globalVariables)
        ruleEngine.loadDataTables(project.dataTables)

        // Determine and load the initial scene
        let initialScene = project.scenes.first { $0.id == project.initialSceneId } ?? project.scenes.first
        if let scene = initialScene {
            loadScene(scene)
        }

        // Trigger game start event
        ruleEngine.dispatchTrigger(.onGameStart)
    }

    public func loadScene(_ scene: GameScene) {
        self.currentScene = scene
        // Load scene rules and global rules into the rule engine
        self.ruleEngine.activeRules = project.globalRules + scene.rules
        self.ruleEngine.dispatchTrigger(.onSceneLoaded)
        self.onSceneChanged?(scene)
    }

    public func handleUserClick(at point: CGPoint, viewportSize: CGSize) {
        guard let scene = currentScene else { return }

        // Find topmost clickable UI element
        for element in scene.uiElements.reversed() where element.isVisible && element.isEnabled {
            let rect = calculateElementRect(element, in: viewportSize)
            if rect.contains(point) {
                // Trigger macOS Force Touch haptic & play sound
                inputManager.triggerHaptic(type: .generic)
                audioManager.playSound("click", volume: 0.8)

                // Dispatch click trigger
                ruleEngine.dispatchTrigger(.onButtonClick(elementId: element.id))
                return
            }
        }
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

    // MARK: - RuleEngineDelegate

    public func ruleEngineDidRequestSceneChange(to sceneId: String) {
        if let target = project.scenes.first(where: { $0.id == sceneId || $0.name.lowercased() == sceneId.lowercased() }) {
            loadScene(target)
        }
    }

    public func ruleEngineDidRequestSoundPlay(soundId: String, volume: Float) {
        audioManager.playSound(soundId, volume: volume)
    }

    public func ruleEngineDidRequestHaptic(type: HapticType) {
        inputManager.triggerHaptic(type: type)
    }

    public func ruleEngineDidRequestUIUpdate(elementId: String, property: String, value: String) {
        guard var scene = currentScene else { return }
        if let idx = scene.uiElements.firstIndex(where: { $0.id == elementId }) {
            if property == "text" {
                scene.uiElements[idx].text = value
            } else if property == "value" {
                scene.uiElements[idx].customProperties["value"] = value
            }
            self.currentScene = scene
        }
    }

    public func ruleEngineDidPrintCLI(text: String, color: String?) {
        onPrintCLI?(text, color)
    }

    public func ruleEngineDidSpawnSprite(name: String, x: Double, y: Double, texture: String) {
        guard var scene = currentScene else { return }
        let sprite = Sprite2D(name: name, x: x, y: y, textureName: texture)
        scene.sprites.append(sprite)
        self.currentScene = scene
    }

    public func ruleEngineDidDestroySprite(spriteId: String) {
        guard var scene = currentScene else { return }
        scene.sprites.removeAll { $0.id == spriteId }
        self.currentScene = scene
    }
}
