import Foundation
import AppKit
import MetalKit
import AstorkaCore

final class GameView: MTKView {
    var runtime: AstorkaGameRuntime?

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        // Convert AppKit coordinates (bottom-left (0,0)) to Metal coordinates (top-left (0,0))
        let flippedY = bounds.height - loc.y
        runtime?.handleUserClick(at: CGPoint(x: loc.x, y: flippedY), viewportSize: bounds.size)
    }

    override func keyDown(with event: NSEvent) {
        if let chars = event.characters {
            runtime?.inputManager.handleKeyDown(key: chars)
            _ = runtime?.ruleEngine.dispatchTrigger(.onKeyPressed(key: chars))
        }
    }

    override func keyUp(with event: NSEvent) {
        if let chars = event.characters {
            runtime?.inputManager.handleKeyUp(key: chars)
        }
    }
}

final class GameViewController: NSViewController, MTKViewDelegate {
    var renderer: Metal2DRenderer?
    var runtime: AstorkaGameRuntime!
    var gameView: GameView!
    var startTime: Date = Date()

    override func loadView() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("No hardware supporting Metal was found!")
        }

        self.renderer = Metal2DRenderer(device: device)
        self.gameView = GameView(frame: NSRect(x: 0, y: 0, width: 1280, height: 800), device: device)
        self.gameView.delegate = self
        self.gameView.colorPixelFormat = .bgra8Unorm
        self.gameView.preferredFramesPerSecond = 120 // 120Hz Apple ProMotion frame rate
        self.gameView.runtime = self.runtime

        self.view = gameView
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let scene = runtime.currentScene,
              let renderPassDesc = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable else { return }

        let elapsed = Float(Date().timeIntervalSince(startTime))
        renderer?.renderScene(
            scene: scene,
            variables: runtime.ruleEngine.variables,
            viewportSize: view.bounds.size,
            time: elapsed,
            postProcessMode: 0,
            renderPassDescriptor: renderPassDesc,
            drawable: drawable
        )
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var viewController: GameViewController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        var project: GameProject = GameTemplates.createDeckbuilderTemplate()

        // 1. Is there a command line argument?
        if CommandLine.arguments.count > 1 {
            let path = CommandLine.arguments[1]
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
               let loaded = try? GameProject.fromJSONData(data) {
                project = loaded
            }
        }
        // 2. Is there an embedded game.json in .app bundle?
        else if let bundleURL = Bundle.main.url(forResource: "game", withExtension: "json"),
                let data = try? Data(contentsOf: bundleURL),
                let loaded = try? GameProject.fromJSONData(data) {
            project = loaded
        }

        let runtime = AstorkaGameRuntime(project: project)

        viewController = GameViewController()
        viewController.runtime = runtime

        let windowSize = NSSize(width: project.windowWidth, height: project.windowHeight)
        let rect = NSRect(x: 100, y: 100, width: windowSize.width, height: windowSize.height)

        window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "\(project.title) - Astorka Engine (Metal 120Hz)"
        window.contentViewController = viewController
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
