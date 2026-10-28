import SwiftUI
import AstorkaCore

public struct LivePlaytestView: View {
    @ObservedObject var state: AppState

    @State private var terminalInput: String = ""
    @State private var hoveredChoiceId: String? = nil
    @State private var terminalScrollTarget: String = "bottom"

    public init(state: AppState) {
        self.state = state
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Studio Playtest Control Bar
            playtestControlBar

            // Body: CLI or UI
            if state.project.type == .cli {
                cliTerminalPlaytestView()
            } else {
                uiCanvasPlaytestView()
            }
        }
        .background(AstorkaTheme.bgDark)
    }

    // MARK: - Playtest Control Bar

    private var playtestControlBar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(AstorkaTheme.emeraldNeon.opacity(0.3))
                        .frame(width: 18, height: 18)
                    Circle()
                        .fill(AstorkaTheme.emeraldNeon)
                        .frame(width: 8, height: 8)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(state.project.type == .cli ? "CLI TERMINAL RUNTIME" : "UI CANVAS RUNTIME")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)

                        Text("ACTIVE")
                            .astorkaBadge(color: AstorkaTheme.emeraldNeon)
                    }

                    Text("Engine running at 120 FPS • Scene: \(state.currentScene?.name ?? "Default")")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Quick Stats HUD in Bar
            if let runtime = state.liveRuntime, !runtime.ruleEngine.variables.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(runtime.ruleEngine.variables.sorted(by: { $0.key < $1.key }).prefix(4)), id: \.key) { k, v in
                        HStack(spacing: 4) {
                            Text("$\(k):")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(AstorkaTheme.cyanNeon)
                            Text(v.asString)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AstorkaTheme.cardDark)
                                .overlay(Capsule().stroke(AstorkaTheme.borderSubtle, lineWidth: 1))
                        )
                    }
                }
            }

            HStack(spacing: 10) {
                Button {
                    state.consoleLogs.removeAll()
                } label: {
                    Label("Clear Log", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(AstorkaGlassButtonStyle())

                Button {
                    state.startPlaytest()
                } label: {
                    Label("Restart", systemImage: "arrow.clockwise")
                        .font(.caption.bold())
                }
                .buttonStyle(AstorkaGlassButtonStyle())

                Button {
                    state.stopPlaytest()
                    state.activeTab = (state.project.type == .cli) ? .choices : .canvas
                } label: {
                    Label("Stop / Back to Editor", systemImage: "stop.fill")
                        .font(.caption.bold())
                }
                .buttonStyle(AstorkaGlowButtonStyle(color: AstorkaTheme.redNeon))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AstorkaTheme.surfaceDark)
        .overlay(Divider().background(AstorkaTheme.borderSubtle), alignment: .bottom)
    }

    // MARK: - CLI Terminal Game View

    @ViewBuilder
    private func cliTerminalPlaytestView() -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                // Window Header Bar
                terminalTitleBar

                // Monospace Terminal Body
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            terminalAsciiBanner

                            if let runtime = state.liveRuntime {
                                terminalVariablesHUD(vars: runtime.ruleEngine.variables)

                                if let scene = runtime.currentScene {
                                    let buttons = scene.uiElements.filter { $0.type == .button && $0.isVisible }
                                    terminalChoicesView(buttons: buttons)
                                }
                            }

                            terminalExecutionLogs

                            // Bottom Anchor
                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding(20)
                    }
                    .background(Color(red: 0.03, green: 0.04, blue: 0.05))
                    .onChange(of: state.consoleLogs.count) { _, _ in
                        withAnimation {
                            proxy.scrollTo("bottom")
                        }
                    }
                }

                // Interactive Terminal Command Input
                terminalInputBar
            }
            .frame(maxWidth: 960, maxHeight: 680)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(
                            colors: [AstorkaTheme.cyanNeon.opacity(0.4), AstorkaTheme.purpleNeon.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: AstorkaTheme.cyanNeon.opacity(0.12), radius: 30, y: 12)
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AstorkaTheme.bgDark)
    }

    private var terminalTitleBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Circle().fill(Color(red: 1.0, green: 0.36, blue: 0.36)).frame(width: 12, height: 12)
                Circle().fill(Color(red: 1.0, green: 0.76, blue: 0.2)).frame(width: 12, height: 12)
                Circle().fill(Color(red: 0.2, green: 0.86, blue: 0.44)).frame(width: 12, height: 12)
            }

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "terminal.fill")
                    .font(.caption2)
                    .foregroundStyle(AstorkaTheme.cyanNeon)
                Text("astorka-cli-vm ~ \(state.project.title).astorkaproject")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.8))
            }

            Spacer()

            Text("UTF-8 • Metal Core")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AstorkaTheme.panelHeader)
        .overlay(Divider().background(AstorkaTheme.borderSubtle), alignment: .bottom)
    }

    private var terminalAsciiBanner: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("┌────────────────────────────────────────────────────────────────────────┐")
                .foregroundStyle(AstorkaTheme.cyanNeon.opacity(0.6))
            HStack {
                Text("│")
                    .foregroundStyle(AstorkaTheme.cyanNeon.opacity(0.6))
                Text("  ASTORKA ENGINE: NATIVE CLI VIRTUAL RUNTIME")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(AstorkaTheme.cyanNeon)
                Spacer()
                Text("v1.0.0 │")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(AstorkaTheme.cyanNeon.opacity(0.6))
            }
            HStack {
                Text("│")
                    .foregroundStyle(AstorkaTheme.cyanNeon.opacity(0.6))
                Text("  Title: \(state.project.title)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white)
                Spacer()
                Text("│")
                    .foregroundStyle(AstorkaTheme.cyanNeon.opacity(0.6))
            }
            Text("└────────────────────────────────────────────────────────────────────────┘")
                .foregroundStyle(AstorkaTheme.cyanNeon.opacity(0.6))
        }
    }

    @ViewBuilder
    private func terminalVariablesHUD(vars: [String: VariableValue]) -> some View {
        if !vars.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "gauge.with.needle")
                        .foregroundStyle(AstorkaTheme.amberNeon)
                    Text("GAME STATE & ECONOMY VARIABLES:")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(AstorkaTheme.amberNeon)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                    ForEach(vars.sorted(by: { $0.key < $1.key }), id: \.key) { key, val in
                        HStack {
                            Text("$\(key)")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.8))
                            Spacer()
                            Text(val.asString)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(AstorkaTheme.emeraldNeon)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AstorkaTheme.cardDark)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AstorkaTheme.borderSubtle, lineWidth: 1))
                        )
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.02))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.06), lineWidth: 1))
            )
        }
    }

    @ViewBuilder
    private func terminalChoicesView(buttons: [UIElement]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "hand.tap.fill")
                    .foregroundStyle(AstorkaTheme.cyanNeon)
                Text("AVAILABLE DECISIONS & ACTIONS:")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }

            if buttons.isEmpty {
                Text("  (No choices configured in this scene. Add choices in the Choices Tab!)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(buttons.enumerated()), id: \.offset) { idx, btn in
                        let isHovered = hoveredChoiceId == btn.id
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                state.handlePlaytestClick(elementId: btn.id)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Text("[\(idx + 1)]")
                                    .font(.system(size: 13, weight: .black, design: .monospaced))
                                    .foregroundStyle(isHovered ? AstorkaTheme.cyanNeon : AstorkaTheme.amberNeon)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill((isHovered ? AstorkaTheme.cyanNeon : AstorkaTheme.amberNeon).opacity(0.15))
                                    )

                                Text(btn.text.isEmpty ? btn.name : btn.text)
                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(.white)

                                Spacer()

                                Text("CLICK OR PRESS [\(idx + 1)]")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(isHovered ? AstorkaTheme.cyanNeon : Color.white.opacity(0.3))

                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundStyle(isHovered ? AstorkaTheme.cyanNeon : Color.white.opacity(0.4))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isHovered ? AstorkaTheme.cardDarkHover : AstorkaTheme.cardDark)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isHovered ? AstorkaTheme.cyanNeon : AstorkaTheme.borderSubtle, lineWidth: isHovered ? 1.5 : 1)
                            )
                            .shadow(color: isHovered ? AstorkaTheme.cyanNeon.opacity(0.25) : Color.clear, radius: 8)
                        }
                        .buttonStyle(.plain)
                        .onHover { h in
                            hoveredChoiceId = h ? btn.id : nil
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var terminalExecutionLogs: some View {
        if !state.consoleLogs.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Divider().background(AstorkaTheme.borderSubtle)

                HStack {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundStyle(AstorkaTheme.emeraldNeon)
                    Text("LIVE EXECUTION LOG:")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(AstorkaTheme.emeraldNeon)
                    Spacer()
                }
                .padding(.top, 4)

                ForEach(Array(state.consoleLogs.enumerated()), id: \.offset) { _, log in
                    HStack(alignment: .top, spacing: 6) {
                        Text("›")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(AstorkaTheme.emeraldNeon)
                        Text(log)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.9))
                    }
                }
            }
        }
    }

    private var terminalInputBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Text("astorka-cli")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(AstorkaTheme.cyanNeon)
                Text("❯")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(AstorkaTheme.amberNeon)
            }

            TextField("Type choice number (e.g. 1) or command and press Enter...", text: $terminalInput)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.white)
                .onSubmit {
                    processTerminalCommand(terminalInput)
                    terminalInput = ""
                }

            Button {
                processTerminalCommand(terminalInput)
                terminalInput = ""
            } label: {
                Label("Execute", systemImage: "return")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
            }
            .buttonStyle(AstorkaGlowButtonStyle(color: AstorkaTheme.cyanNeon))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AstorkaTheme.panelHeader)
        .overlay(Divider().background(AstorkaTheme.borderSubtle), alignment: .top)
    }

    private func processTerminalCommand(_ cmd: String) {
        guard let runtime = state.liveRuntime, let scene = runtime.currentScene else { return }
        let trimmed = cmd.trimmingCharacters(in: .whitespacesAndNewlines)
        let buttons = scene.uiElements.filter { $0.type == .button && $0.isVisible }

        if let idx = Int(trimmed), idx >= 1 && idx <= buttons.count {
            state.handlePlaytestClick(elementId: buttons[idx - 1].id)
        } else if let matched = buttons.first(where: { $0.id.lowercased() == trimmed.lowercased() || $0.text.lowercased().contains(trimmed.lowercased()) }) {
            state.handlePlaytestClick(elementId: matched.id)
        } else if !trimmed.isEmpty {
            state.consoleLogs.append("⚠️ Command not recognized: '\(trimmed)'. Type 1, 2, 3... to trigger a choice.")
        }
    }

    // MARK: - UI & 2D Game View

    @ViewBuilder
    private func uiCanvasPlaytestView() -> some View {
        HSplitView {
            // Left: Game Canvas Viewport
            VStack {
                if let runtime = state.liveRuntime, let scene = runtime.currentScene {
                    VStack(spacing: 20) {
                        // Floating Glass HUD
                        HStack(spacing: 12) {
                            ForEach(runtime.ruleEngine.variables.sorted(by: { $0.key < $1.key }), id: \.key) { key, val in
                                HStack(spacing: 6) {
                                    Text("$\(key):")
                                        .font(.caption.bold())
                                        .foregroundStyle(AstorkaTheme.cyanNeon)
                                    Text(val.asString)
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.white)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(AstorkaTheme.cardDark.opacity(0.85))
                                        .overlay(Capsule().stroke(AstorkaTheme.borderSubtle, lineWidth: 1))
                                )
                            }
                        }
                        .padding(.top, 16)

                        Spacer()

                        // Render Screen
                        ZStack {
                            ForEach(scene.uiElements.filter { $0.isVisible }) { el in
                                playtestElement(el, runtime: runtime)
                            }
                        }
                        .frame(width: 760, height: 480)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(
                                    red: Double(scene.backgroundColor.r),
                                    green: Double(scene.backgroundColor.g),
                                    blue: Double(scene.backgroundColor.b)
                                ))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AstorkaTheme.borderSubtle, lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.6), radius: 24, y: 12)

                        Spacer()
                    }
                }
            }
            .frame(minWidth: 540, maxWidth: .infinity)
            .background(AstorkaTheme.bgDark)

            // Right: Live Game Log
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "terminal.fill")
                        .foregroundStyle(AstorkaTheme.emeraldNeon)
                    Text("LIVE EVENT & RULE LOG")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.8))
                    Spacer()
                }
                .padding(14)
                .background(AstorkaTheme.panelHeader)
                .overlay(Divider().background(AstorkaTheme.borderSubtle), alignment: .bottom)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(state.consoleLogs.enumerated()), id: \.offset) { _, log in
                            HStack(alignment: .top, spacing: 6) {
                                Text("❯")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(AstorkaTheme.emeraldNeon)
                                Text(log)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.9))
                            }
                        }
                    }
                    .padding(14)
                }
                .background(Color(red: 0.04, green: 0.05, blue: 0.07))
            }
            .frame(minWidth: 280, maxWidth: 360)
        }
    }

    @ViewBuilder
    private func playtestElement(_ element: UIElement, runtime: AstorkaGameRuntime) -> some View {
        let vars = runtime.ruleEngine.variables

        Group {
            switch element.type {
            case .button:
                Button {
                    state.handlePlaytestClick(elementId: element.id)
                } label: {
                    Text(runtime.ruleEngine.evaluator.interpolate(element.text.isEmpty ? element.name : element.text, variables: vars))
                        .font(.system(size: CGFloat(element.style.fontSize), weight: .bold))
                        .frame(width: CGFloat(element.width), height: CGFloat(element.height))
                }
                .buttonStyle(AstorkaGlowButtonStyle(color: AstorkaTheme.cyanNeon))

            case .label:
                Text(resolveLabelText(element: element, runtime: runtime))
                    .font(.system(size: CGFloat(element.style.fontSize), weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: CGFloat(element.width), height: CGFloat(element.height))

            case .cardView:
                Button {
                    state.handlePlaytestClick(elementId: element.id)
                } label: {
                    VStack(spacing: 8) {
                        Text("🃏").font(.system(size: 32))
                        Text(element.text.isEmpty ? "Card" : element.text)
                            .font(.system(size: 13, weight: .bold))
                    }
                    .frame(width: CGFloat(element.width), height: CGFloat(element.height))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [AstorkaTheme.amberNeon.opacity(0.8), Color.orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .foregroundColor(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(radius: 8)
                }
                .buttonStyle(.plain)

            default:
                EmptyView()
            }
        }
        .offset(x: CGFloat(element.x), y: CGFloat(element.y))
    }

    private func resolveLabelText(element: UIElement, runtime: AstorkaGameRuntime) -> String {
        let vars = runtime.ruleEngine.variables
        var text = runtime.ruleEngine.evaluator.interpolate(element.text, variables: vars)
        if let binding = element.bindingVariable, let val = vars[binding] {
            text = "\(element.text) \(val.asString)"
        }
        return text
    }
}
