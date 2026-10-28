import Foundation
import AppKit
import GameController

public final class InputManager: @unchecked Sendable {
    public static let shared = InputManager()

    public var mousePosition: CGPoint = .zero
    public var isMouseDown: Bool = false
    public var isRightMouseDown: Bool = false
    public var activeKeys: Set<String> = []

    public var onKeyPressed: ((String) -> Void)?
    public var onMouseClicked: ((CGPoint) -> Void)?
    public var onGamepadButton: ((String) -> Void)?

    public init() {
        setupGameControllers()
    }

    /// macOS Trackpad Force Touch Haptik Geri Bildirimi
    public func triggerHaptic(type: HapticType) {
        let pattern: NSHapticFeedbackManager.FeedbackPattern
        switch type {
        case .generic:
            pattern = .generic
        case .alignment:
            pattern = .alignment
        case .levelChange:
            pattern = .levelChange
        }
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .default)
    }

    private func setupGameControllers() {
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notif in
            if let controller = notif.object as? GCController {
                self?.configureController(controller)
            }
        }

        for controller in GCController.controllers() {
            configureController(controller)
        }
    }

    private func configureController(_ controller: GCController) {
        if let gamepad = controller.extendedGamepad {
            gamepad.buttonA.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.onGamepadButton?("ButtonA") }
            }
            gamepad.buttonB.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.onGamepadButton?("ButtonB") }
            }
            gamepad.buttonX.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.onGamepadButton?("ButtonX") }
            }
            gamepad.buttonY.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.onGamepadButton?("ButtonY") }
            }
            gamepad.dpad.up.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.onGamepadButton?("DpadUp") }
            }
            gamepad.dpad.down.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.onGamepadButton?("DpadDown") }
            }
        }
    }

    public func handleKeyDown(key: String) {
        activeKeys.insert(key.lowercased())
        onKeyPressed?(key)
    }

    public func handleKeyUp(key: String) {
        activeKeys.remove(key.lowercased())
    }

    public func handleMouseDown(at point: CGPoint) {
        mousePosition = point
        isMouseDown = true
        onMouseClicked?(point)
    }

    public func handleMouseUp(at point: CGPoint) {
        mousePosition = point
        isMouseDown = false
    }

    public func handleMouseMove(to point: CGPoint) {
        mousePosition = point
    }
}
