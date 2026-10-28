import SwiftUI
import AstorkaCore

private struct ChoiceEditorWrapper: Identifiable {
    let id = UUID()
    let mode: FormulaEditorMode
}

public struct ChoicesEditorView: View {
    @ObservedObject var state: AppState

    @State private var activeEditorWrapper: ChoiceEditorWrapper? = nil
    @State private var testExecutionMessage: String? = nil
    @State private var testExecutionIsError: Bool = false
    @State private var hoveredChoiceId: String? = nil

    public init(state: AppState) {
        self.state = state
    }

    public var body: some View {
        ZStack {
            AstorkaTheme.bgDark.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Top Header & Action Bar
                topHeaderBar

                // MARK: - Live Variables Pills Bar
                variablesBar

                // MARK: - Test Execution Alert Banner
                if let testMsg = testExecutionMessage {
                    HStack(spacing: 10) {
                        Image(systemName: testExecutionIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .foregroundColor(testExecutionIsError ? AstorkaTheme.amberNeon : AstorkaTheme.emeraldNeon)
                        Text(testMsg)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                        Spacer()
                        Button {
                            withAnimation { testExecutionMessage = nil }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(testExecutionIsError ? Color(red: 0.35, green: 0.15, blue: 0.05) : Color(red: 0.05, green: 0.25, blue: 0.15))
                    .overlay(Divider().background((testExecutionIsError ? AstorkaTheme.amberNeon : AstorkaTheme.emeraldNeon).opacity(0.4)), alignment: .bottom)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // MARK: - Choices Content Area
                if let scene = state.currentScene {
                    let buttons = scene.uiElements.filter { $0.type == .button }
                    if buttons.isEmpty {
                        emptyChoicesView
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 14) {
                                ForEach(buttons) { btn in
                                    let matchedRule = scene.rules.first { $0.trigger == .onButtonClick(elementId: btn.id) }
                                    choiceCard(button: btn, rule: matchedRule)
                                }
                            }
                            .padding(24)
                        }
                    }
                }
            }
        }
        .sheet(item: $activeEditorWrapper) { wrapper in
            FormulaEditorSheet(state: state, mode: wrapper.mode) {
                activeEditorWrapper = nil
            }
        }
    }

    // MARK: - Top Header Bar

    private var topHeaderBar: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AstorkaTheme.cyanNeon.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "function")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AstorkaTheme.cyanNeon)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("CHOICES & FORMULAS (NO-CODE)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("DECISION ENGINE")
                        .astorkaBadge(color: AstorkaTheme.cyanNeon)
                }
                Text("Craft game decisions, condition checks, and math formulas (e.g. cash += item_price * 5 / 10).")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Button {
                activeEditorWrapper = ChoiceEditorWrapper(mode: .new)
            } label: {
                Label("Add Choice & Formula", systemImage: "plus.circle.fill")
                    .font(.system(size: 12, weight: .bold))
            }
            .buttonStyle(AstorkaGlowButtonStyle(color: AstorkaTheme.cyanNeon))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(AstorkaTheme.surfaceDark)
        .overlay(Divider().background(AstorkaTheme.borderSubtle), alignment: .bottom)
    }

    // MARK: - Variables Bar

    private var variablesBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.caption2)
                    .foregroundColor(AstorkaTheme.amberNeon)
                Text("LIVE VARIABLES:")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(AstorkaTheme.amberNeon)
            }

            if state.project.globalVariables.isEmpty {
                Text("No variables yet. Variables are automatically detected and updated by your formulas!")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.45))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(state.project.globalVariables) { gv in
                            HStack(spacing: 5) {
                                Text("$\(gv.name)")
                                    .fontWeight(.bold)
                                Text("=")
                                    .foregroundColor(.white.opacity(0.5))
                                Text(gv.initialValue.asString)
                                    .foregroundColor(AstorkaTheme.emeraldNeon)
                            }
                            .font(.system(size: 11, design: .monospaced))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.06)))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(AstorkaTheme.borderSubtle, lineWidth: 1))
                            .foregroundColor(.white)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 9)
        .background(AstorkaTheme.panelHeader)
        .overlay(Divider().background(AstorkaTheme.borderSubtle), alignment: .bottom)
    }

    // MARK: - Empty State

    private var emptyChoicesView: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Circle()
                    .fill(AstorkaTheme.cyanNeon.opacity(0.08))
                    .frame(width: 90, height: 90)
                Image(systemName: "list.bullet.rectangle.portrait")
                    .font(.system(size: 40))
                    .foregroundColor(AstorkaTheme.cyanNeon)
            }

            Text("No Choices In This Scene Yet")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Text("Choices allow players to sell items, fight enemies, upgrade businesses, or make story decisions.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 460)

            Button {
                activeEditorWrapper = ChoiceEditorWrapper(mode: .new)
            } label: {
                Label("Create First Choice & Formula", systemImage: "plus")
                    .font(.system(size: 13, weight: .bold))
            }
            .buttonStyle(AstorkaGlowButtonStyle(color: AstorkaTheme.cyanNeon))
            .padding(.top, 6)

            Spacer()
        }
        .padding(32)
    }

    // MARK: - Choice Card

    private func choiceCard(button: UIElement, rule: EventRule?) -> some View {
        let isHovered = hoveredChoiceId == button.id

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                // Shortcut badge
                Text(String(button.text.prefix(2)).trimmingCharacters(in: .whitespaces))
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundColor(.black)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AstorkaTheme.cyanNeon)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(button.text)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Text("Choice ID: \(button.id)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                // "Edit Formula & Choice" Button
                Button {
                    let choice = reconstructChoice(button: button, rule: rule)
                    activeEditorWrapper = ChoiceEditorWrapper(mode: .edit(choice))
                } label: {
                    Label("Edit Formula", systemImage: "pencil.line")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(AstorkaGlowButtonStyle(color: AstorkaTheme.cyanNeon))
                .help("Edit choice label, math formulas, and unlock condition")

                // "Test Choice Now" Interactive Simulation Button
                Button {
                    testExecuteChoice(rule: rule)
                } label: {
                    Label("Test Choice Now", systemImage: "bolt.fill")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(AstorkaGlassButtonStyle())
                .help("Simulate this choice immediately with current project variables")

                // Delete Button
                Button {
                    deleteChoice(buttonId: button.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(AstorkaTheme.redNeon.opacity(0.8))
                }
                .buttonStyle(.plain)
                .padding(6)
                .background(Circle().fill(Color.white.opacity(0.06)))
                .help("Delete Choice")
            }

            // Formulas & Conditions pills
            VStack(alignment: .leading, spacing: 8) {
                if let rule = rule {
                    // Condition
                    if !rule.conditions.isEmpty {
                        HStack(spacing: 6) {
                            Text("CONDITION:")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(AstorkaTheme.amberNeon)
                            ForEach(rule.conditions.indices, id: \.self) { idx in
                                let c = rule.conditions[idx]
                                switch c {
                                case .compareVariable(let v, let op, let val):
                                    Text("\(v) \(op.rawValue) \(val)")
                                        .font(.system(size: 11, design: .monospaced))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(AstorkaTheme.amberNeon.opacity(0.12)))
                                        .overlay(Capsule().stroke(AstorkaTheme.amberNeon.opacity(0.4), lineWidth: 1))
                                        .foregroundColor(AstorkaTheme.amberNeon)
                                default:
                                    EmptyView()
                                }
                            }
                        }
                    }

                    // Actions / Formulas
                    HStack(spacing: 8) {
                        Text("FORMULAS:")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(AstorkaTheme.emeraldNeon)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(rule.actions.indices, id: \.self) { idx in
                                    let action = rule.actions[idx]
                                    switch action {
                                    case .modifyVariable(let v, let op, let expr):
                                        HStack(spacing: 4) {
                                            Image(systemName: "function")
                                                .font(.caption2)
                                            Text("\(v) \(op.rawValue) \(expr)")
                                        }
                                        .font(.system(size: 11, design: .monospaced))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(RoundedRectangle(cornerRadius: 6).fill(AstorkaTheme.emeraldNeon.opacity(0.12)))
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AstorkaTheme.emeraldNeon.opacity(0.4), lineWidth: 1))
                                        .foregroundColor(AstorkaTheme.emeraldNeon)

                                    case .setVariable(let v, let expr):
                                        Text("\(v) = \(expr)")
                                            .font(.system(size: 11, design: .monospaced))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(RoundedRectangle(cornerRadius: 6).fill(AstorkaTheme.cyanNeon.opacity(0.12)))
                                            .foregroundColor(AstorkaTheme.cyanNeon)

                                    case .playSound(let soundId, _):
                                        HStack(spacing: 4) {
                                            Image(systemName: "speaker.wave.2.fill")
                                            Text(soundId)
                                        }
                                        .font(.system(size: 10))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(Color.white.opacity(0.08)))
                                        .foregroundColor(.white.opacity(0.7))

                                    default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(18)
        .astorkaCard(isHovered: isHovered, cornerRadius: 14)
        .onHover { h in
            hoveredChoiceId = h ? button.id : nil
        }
    }

    // MARK: - Reconstruct GameChoice for Editing

    private func reconstructChoice(button: UIElement, rule: EventRule?) -> GameChoice {
        var conditionStr = ""
        var formulaStr = ""
        var secondaryFormulaStr = ""
        var messageStr = ""
        var soundStr = "coin"

        if let rule = rule {
            for cond in rule.conditions {
                switch cond {
                case .compareVariable(let v, let op, let val):
                    conditionStr = "\(v) \(op.rawValue) \(val)"
                default: break
                }
            }

            var formulaIndex = 0
            for action in rule.actions {
                switch action {
                case .modifyVariable(let v, let op, let expr):
                    let stmt = "\(v) \(op.rawValue) \(expr)"
                    if formulaIndex == 0 {
                        formulaStr = stmt
                        formulaIndex += 1
                    } else if formulaIndex == 1 {
                        secondaryFormulaStr = stmt
                        formulaIndex += 1
                    }
                case .setVariable(let v, let expr):
                    let stmt = "\(v) = \(expr)"
                    if formulaIndex == 0 {
                        formulaStr = stmt
                        formulaIndex += 1
                    } else if formulaIndex == 1 {
                        secondaryFormulaStr = stmt
                        formulaIndex += 1
                    }
                case .printCLI(let text, _):
                    messageStr = text.replacingOccurrences(of: "📦 ", with: "")
                case .playSound(let soundId, _):
                    soundStr = soundId
                default: break
                }
            }
        }

        return GameChoice(
            id: button.id,
            label: button.text.isEmpty ? button.name : button.text,
            shortcut: String(button.text.prefix(1)),
            condition: conditionStr,
            formula: formulaStr,
            secondaryFormula: secondaryFormulaStr,
            message: messageStr,
            sound: soundStr
        )
    }

    // MARK: - Live In-Editor Test Execution

    private func testExecuteChoice(rule: EventRule?) {
        guard let rule = rule else { return }
        let evaluator = ExpressionEvaluator()

        var currentVars: [String: VariableValue] = [:]
        for gv in state.project.globalVariables {
            currentVars[gv.name] = gv.initialValue
        }

        // 1. Check Condition
        for cond in rule.conditions {
            switch cond {
            case .compareVariable(let v, let op, let val):
                let isMet: Bool
                if v.contains(">=") || v.contains("<=") || v.contains("==") || v.contains("!=") || v.contains(">") || v.contains("<") {
                    isMet = evaluator.evaluateCondition(v, variables: currentVars)
                } else {
                    let cur = currentVars[v] ?? .number(0)
                    let exp = evaluator.evaluate(val, variables: currentVars)
                    switch op {
                    case .greaterOrEqual: isMet = cur.asNumber >= exp.asNumber
                    case .lessOrEqual: isMet = cur.asNumber <= exp.asNumber
                    case .equal: isMet = cur.asString == exp.asString
                    case .notEqual: isMet = cur.asString != exp.asString
                    case .greaterThan: isMet = cur.asNumber > exp.asNumber
                    case .lessThan: isMet = cur.asNumber < exp.asNumber
                    default: isMet = true
                    }
                }

                if !isMet {
                    let curVal = currentVars[v]?.asString ?? "0"
                    withAnimation {
                        testExecutionIsError = true
                        testExecutionMessage = "🔒 Condition not met! Requires [\(v) \(op.rawValue) \(val)] (Current: \(v)=\(curVal))"
                    }
                    state.liveRuntime?.audioManager.playSound("hit")
                    return
                }
            default: break
            }
        }

        // 2. Execute Formulas & Record Changes
        var executedActions: [String] = []
        for action in rule.actions {
            switch action {
            case .modifyVariable(let v, let op, let expr):
                let clean = v.hasPrefix("$") ? String(v.dropFirst()) : v
                let before = currentVars[clean]?.asNumber ?? 0
                evaluator.executeStatement("\(clean) \(op.rawValue) \(expr)", variables: &currentVars)
                let after = currentVars[clean]?.asNumber ?? 0
                let delta = after - before
                let deltaStr = delta >= 0 ? "+\(formatNum(delta))" : "\(formatNum(delta))"
                executedActions.append("\(clean): \(formatNum(before)) ➔ \(formatNum(after)) (\(deltaStr))")

            case .setVariable(let v, let expr):
                let clean = v.hasPrefix("$") ? String(v.dropFirst()) : v
                evaluator.executeStatement("\(clean) = \(expr)", variables: &currentVars)
                let val = currentVars[clean]?.asString ?? "0"
                executedActions.append("\(clean) = \(val)")

            default: break
            }
        }

        // 3. Update globalVariables in project so Live Variables Bar reflects changes!
        for (k, val) in currentVars {
            if let idx = state.project.globalVariables.firstIndex(where: { $0.name.lowercased() == k.lowercased() }) {
                state.project.globalVariables[idx].initialValue = val
            }
        }

        // Sound & Haptic
        state.liveRuntime?.audioManager.playSound("coin", volume: 1.0)
        state.liveRuntime?.inputManager.triggerHaptic(type: .generic)

        withAnimation {
            testExecutionIsError = false
            testExecutionMessage = "⚡ Test Success! Simulated: \(executedActions.joined(separator: ", "))"
        }

        state.objectWillChange.send()
    }

    private func formatNum(_ n: Double) -> String {
        if n.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(n))
        } else {
            return String(format: "%.2f", n)
        }
    }

    private func deleteChoice(buttonId: String) {
        guard var scene = state.currentScene else { return }
        scene.uiElements.removeAll { $0.id == buttonId }
        scene.rules.removeAll { $0.trigger == .onButtonClick(elementId: buttonId) }
        state.currentScene = scene
        state.objectWillChange.send()
    }
}
