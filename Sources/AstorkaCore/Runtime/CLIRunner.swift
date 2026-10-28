import Foundation

public final class CLIRunner {
    public let runtime: AstorkaGameRuntime
    private var isRunning: Bool = false

    public init(project: GameProject) {
        self.runtime = AstorkaGameRuntime(project: project)
        setupCLIOutput()
    }

    private func setupCLIOutput() {
        runtime.onPrintCLI = { text, color in
            let ansiColor: String
            switch color?.lowercased() {
            case "cyan": ansiColor = "\u{001B}[36m"
            case "green": ansiColor = "\u{001B}[32m"
            case "yellow": ansiColor = "\u{001B}[33m"
            case "red": ansiColor = "\u{001B}[31m"
            case "magenta": ansiColor = "\u{001B}[35m"
            case "blue": ansiColor = "\u{001B}[34m"
            default: ansiColor = "\u{001B}[37m"
            }
            print("\(ansiColor)\(text)\u{001B}[0m")
        }
    }

    /// Starts the interactive game loop in the terminal
    public func startInteractiveLoop() {
        isRunning = true
        printBanner()

        while isRunning {
            renderCurrentState()
            print("\u{001B}[33mAstorka CLI > \u{001B}[0m", terminator: "")
            fflush(stdout)

            guard let line = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                break
            }

            if line.lowercased() == "exit" || line.lowercased() == "quit" {
                print("\u{001B}[31m[Astorka CLI] Exiting game...\u{001B}[0m")
                isRunning = false
                break
            }

            processInput(line)
        }
    }

    private func printBanner() {
        print("\u{001B}[1;36m")
        print("=================================================================")
        print("  ASTORKA ENGINE: NATIVE macOS NO-CODE RUNTIME (CLI MODE)")
        print("  Project: \(runtime.project.title) v\(runtime.project.version)")
        print("  Author:  \(runtime.project.author)")
        print("=================================================================")
        print("\u{001B}[0m")
    }

    public func renderCurrentState() {
        guard let scene = runtime.currentScene else { return }

        print("\n\u{001B}[1;35m--- [ Scene: \(scene.name) ] ---\u{001B}[0m")

        // 1. Print variables
        let vars = runtime.ruleEngine.variables
        if !vars.isEmpty {
            var varSummary: [String] = []
            for (key, val) in vars.sorted(by: { $0.key < $1.key }) {
                varSummary.append("\u{001B}[32m\(key):\u{001B}[0m \u{001B}[1m\(val.asString)\u{001B}[0m")
            }
            print("📊 STATS: \(varSummary.joined(separator: " | "))")
        }

        // 2. HUD / Information Labels
        let labels = scene.uiElements.filter { $0.isVisible && ($0.type == .label || $0.type == .gaugeBar || $0.type == .dialogueBox) }
        if !labels.isEmpty {
            print("\n📋 GAUGES & PANELS:")
            for lbl in labels {
                var display = runtime.ruleEngine.evaluator.interpolate(lbl.text, variables: vars)
                if let binding = lbl.bindingVariable, let val = vars[binding] {
                    display = "\(lbl.text) \(val.asString)"
                }
                print("  • \u{001B}[36m\(display)\u{001B}[0m")
            }
        }

        // 3. Clickable Action Buttons
        let buttons = scene.uiElements.filter { $0.isVisible && $0.isEnabled && $0.type == .button }
        print("\n🎮 AVAILABLE ACTIONS:")
        if buttons.isEmpty {
            print("  (No actions available)")
        } else {
            for (idx, btn) in buttons.enumerated() {
                let btnText = runtime.ruleEngine.evaluator.interpolate(btn.text.isEmpty ? btn.name : btn.text, variables: vars)
                print("  [\(idx + 1)] \u{001B}[1;37m\(btnText)\u{001B}[0m (ID: \(btn.id))")
            }
        }
        print("  [exit] Quit Game\n")
    }

    private func processInput(_ input: String) {
        guard let scene = runtime.currentScene else { return }

        let buttons = scene.uiElements.filter { $0.isVisible && $0.isEnabled && $0.type == .button }

        if let idx = Int(input), idx >= 1 && idx <= buttons.count {
            let chosen = buttons[idx - 1]
            let btnText = chosen.text.isEmpty ? chosen.name : chosen.text
            print("\u{001B}[34m▶ [Action Selected]: \(btnText)\u{001B}[0m")
            runtime.audioManager.playSound("click")
            runtime.ruleEngine.dispatchTrigger(.onButtonClick(elementId: chosen.id))
            return
        }

        let executed = runtime.ruleEngine.dispatchTrigger(.onCLICommand(command: input))
        if executed == 0 {
            if let matched = buttons.first(where: { $0.id.lowercased() == input.lowercased() }) {
                runtime.ruleEngine.dispatchTrigger(.onButtonClick(elementId: matched.id))
            } else {
                print("\u{001B}[31m[!] Unknown command or action number: '\(input)'\u{001B}[0m")
            }
        }
    }
}
