import SwiftUI
import AstorkaCore

public enum FormulaEditorMode: Equatable {
    case new
    case edit(GameChoice)

    public var isNew: Bool {
        if case .new = self { return true }
        return false
    }
}

public struct FormulaEditorSheet: View {
    @ObservedObject var state: AppState
    let mode: FormulaEditorMode
    let onDismiss: () -> Void

    @State private var choiceId: String = ""
    @State private var choiceLabel: String = ""
    @State private var choiceShortcut: String = ""
    @State private var choiceCondition: String = ""
    @State private var choiceFormula: String = "cash += item_price * 5 / 10"
    @State private var choiceSecondaryFormula: String = "raw_materials -= 5"
    @State private var choiceMessage: String = "Transaction completed!"
    @State private var choiceSound: String = "coin"

    // Focused formula field for quick-insert buttons
    @State private var activeFormulaTarget: ActiveFormulaTarget = .primary

    // Live Test simulation output inside the sheet
    @State private var simulatedLog: String? = nil

    private enum ActiveFormulaTarget {
        case condition
        case primary
        case secondary
    }

    public init(state: AppState, mode: FormulaEditorMode, onDismiss: @escaping () -> Void) {
        self.state = state
        self.mode = mode
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerBar

            // Main Editor Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Choice Identity Section
                    identitySection

                    // Condition Formula Section
                    conditionFormulaSection

                    // Primary Revenue/Gain Formula Section
                    primaryFormulaSection

                    // Secondary Cost/Deduction Formula Section
                    secondaryFormulaSection

                    // Quick-Insert Math Palette
                    quickInsertPaletteSection

                    // Audio & Feedback Message Section
                    feedbackSection

                    // In-Editor Test Simulator
                    testSimulatorSection
                }
                .padding(24)
            }

            // Footer Action Bar
            footerBar
        }
        .frame(width: 720, height: 740)
        .background(AstorkaTheme.surfaceDark)
        .onAppear {
            setupInitialState()
        }
    }

    // MARK: - Initial State

    private func setupInitialState() {
        switch mode {
        case .new:
            choiceId = "choice_\(UUID().uuidString.prefix(6))"
            choiceLabel = "1. Sell Processed Ore"
            choiceShortcut = "1"
            choiceCondition = "raw_materials >= 5"
            choiceFormula = "cash += item_price * 5 / 10"
            choiceSecondaryFormula = "raw_materials -= 5"
            choiceMessage = "Sold materials at 50% market value!"
            choiceSound = "coin"
        case .edit(let choice):
            choiceId = choice.id
            choiceLabel = choice.label
            choiceShortcut = choice.shortcut
            choiceCondition = choice.condition
            choiceFormula = choice.formula
            choiceSecondaryFormula = choice.secondaryFormula
            choiceMessage = choice.message
            choiceSound = choice.sound
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AstorkaTheme.cyanNeon.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "function")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AstorkaTheme.cyanNeon)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(modeTitle)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)

                    Text("LIVE MATH EVALUATOR")
                        .astorkaBadge(color: AstorkaTheme.emeraldNeon)
                }

                Text("Declarative formulas for RPG stats, trade prices, and game choices. Zero code required.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(AstorkaTheme.panelHeader)
        .overlay(Divider().background(AstorkaTheme.borderSubtle), alignment: .bottom)
    }

    private var modeTitle: String {
        switch mode {
        case .new: return "CREATE NEW FORMULA & CHOICE"
        case .edit: return "EDIT CHOICE FORMULAS"
        }
    }

    // MARK: - Choice Identity

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CHOICE LABEL & KEY SHORTCUT")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(AstorkaTheme.cyanNeon)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Display Title (Terminal & Button Text)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("e.g. 1. Sell Raw Materials", text: $choiceLabel)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(10)
                        .background(AstorkaTheme.cardDark)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AstorkaTheme.borderSubtle, lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Shortcut Key")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("1", text: $choiceShortcut)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .frame(width: 80)
                        .padding(10)
                        .background(AstorkaTheme.cardDark)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AstorkaTheme.borderSubtle, lineWidth: 1))
                }
            }
        }
        .padding(14)
        .astorkaCard(isHovered: false, cornerRadius: 10)
    }

    // MARK: - Condition Formula

    private var conditionFormulaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(AstorkaTheme.amberNeon)
                    Text("UNLOCK CONDITION (LOGIC GATE)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(AstorkaTheme.amberNeon)
                }

                Spacer()

                // Live Condition Status Badge
                conditionLiveBadge
            }

            Text("The choice is only clickable/selectable when this condition evaluates to true.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            TextField("e.g. raw_materials >= 5 or cash >= 100", text: $choiceCondition)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .padding(10)
                .background(AstorkaTheme.cardDark)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(activeFormulaTarget == .condition ? AstorkaTheme.amberNeon : AstorkaTheme.borderSubtle, lineWidth: 1.5))
                .onTapGesture { activeFormulaTarget = .condition }

            // Condition Presets
            HStack(spacing: 6) {
                Text("Helper Presets:")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)

                presetChip("raw_materials >= 5") { choiceCondition = "raw_materials >= 5" }
                presetChip("cash >= 200") { choiceCondition = "cash >= 200" }
                presetChip("level >= 2") { choiceCondition = "level >= 2" }
                presetChip("Clear (Always Available)") { choiceCondition = "" }
            }
        }
        .padding(14)
        .astorkaCard(isHovered: false, cornerRadius: 10)
    }

    @ViewBuilder
    private var conditionLiveBadge: some View {
        if choiceCondition.trimmingCharacters(in: .whitespaces).isEmpty {
            Text("🟢 ALWAYS UNLOCKED")
                .astorkaBadge(color: AstorkaTheme.emeraldNeon)
        } else {
            let vars = currentVariableMap()
            let isMet = ExpressionEvaluator().evaluateCondition(choiceCondition, variables: vars)
            if isMet {
                HStack(spacing: 4) {
                    Circle().fill(AstorkaTheme.emeraldNeon).frame(width: 6, height: 6)
                    Text("CURRENTLY UNLOCKED (TRUE)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(AstorkaTheme.emeraldNeon)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(AstorkaTheme.emeraldNeon.opacity(0.12)))
            } else {
                HStack(spacing: 4) {
                    Circle().fill(AstorkaTheme.redNeon).frame(width: 6, height: 6)
                    Text("CURRENTLY LOCKED (FALSE)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(AstorkaTheme.redNeon)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(AstorkaTheme.redNeon.opacity(0.12)))
            }
        }
    }

    // MARK: - Primary Formula (Revenue / Output)

    private var primaryFormulaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "plus.forwardslash.minus")
                        .foregroundStyle(AstorkaTheme.emeraldNeon)
                    Text("PRIMARY FORMULA (OUTPUT / GAIN)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(AstorkaTheme.emeraldNeon)
                }

                Spacer()

                Text("TARGET MUTATION")
                    .astorkaBadge(color: AstorkaTheme.emeraldNeon)
            }

            Text("Calculates and applies stats, gold, XP, or items. Supports variable multiplication, division, and functions.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            TextField("e.g. cash += item_price * 5 / 10", text: $choiceFormula)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .padding(10)
                .background(AstorkaTheme.cardDark)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(activeFormulaTarget == .primary ? AstorkaTheme.emeraldNeon : AstorkaTheme.borderSubtle, lineWidth: 1.5))
                .onTapGesture { activeFormulaTarget = .primary }

            // Live Calculation Inspector Box
            liveCalculationBox(for: choiceFormula)
        }
        .padding(14)
        .astorkaCard(isHovered: false, cornerRadius: 10)
    }

    // MARK: - Secondary Formula (Cost / Resource Deduction)

    private var secondaryFormulaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(AstorkaTheme.amberNeon)
                    Text("SECONDARY FORMULA (COST / DEDUCTION)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(AstorkaTheme.amberNeon)
                }

                Spacer()

                Text("RESOURCE DEDUCTION")
                    .astorkaBadge(color: AstorkaTheme.amberNeon)
            }

            Text("Optional cost or resource consumption (e.g. raw_materials -= 5 or energy -= 10).")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            TextField("e.g. raw_materials -= 5", text: $choiceSecondaryFormula)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .padding(10)
                .background(AstorkaTheme.cardDark)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(activeFormulaTarget == .secondary ? AstorkaTheme.amberNeon : AstorkaTheme.borderSubtle, lineWidth: 1.5))
                .onTapGesture { activeFormulaTarget = .secondary }

            if !choiceSecondaryFormula.trimmingCharacters(in: .whitespaces).isEmpty {
                liveCalculationBox(for: choiceSecondaryFormula)
            }
        }
        .padding(14)
        .astorkaCard(isHovered: false, cornerRadius: 10)
    }

    // MARK: - Live Calculation Box

    @ViewBuilder
    private func liveCalculationBox(for formulaStr: String) -> some View {
        let trimmed = formulaStr.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            let calculation = computeFormulaPreview(formulaStr)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: calculation.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(calculation.isValid ? AstorkaTheme.emeraldNeon : AstorkaTheme.amberNeon)
                    Text("LIVE SIMULATION PREVIEW:")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(calculation.isValid ? AstorkaTheme.emeraldNeon : AstorkaTheme.amberNeon)
                    Spacer()
                }

                HStack(spacing: 12) {
                    Text(calculation.previewText)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)

                    Spacer()

                    if let breakdown = calculation.breakdown {
                        Text(breakdown)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(AstorkaTheme.cyanNeon)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.03))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(calculation.isValid ? AstorkaTheme.emeraldNeon.opacity(0.3) : AstorkaTheme.amberNeon.opacity(0.3), lineWidth: 1))
            )
        }
    }

    // MARK: - Quick-Insert Math Palette

    private var quickInsertPaletteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "keyboard.fill")
                        .foregroundStyle(AstorkaTheme.cyanNeon)
                    Text("FORMULA BUILDER PALETTE (CLICK TO INSERT INTO FORMULA)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(AstorkaTheme.cyanNeon)
                }

                Spacer()

                Text("TARGET: \(activeTargetName)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            // Variable Insert Buttons
            VStack(alignment: .leading, spacing: 4) {
                Text("Variables in Project:")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(state.project.globalVariables) { gv in
                            Button {
                                insertIntoActiveTarget(gv.name)
                            } label: {
                                HStack(spacing: 3) {
                                    Text("$\(gv.name)")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    Text("(\(gv.initialValue.asString))")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(AstorkaTheme.cyanNeon.opacity(0.12)))
                                .overlay(Capsule().stroke(AstorkaTheme.cyanNeon.opacity(0.35), lineWidth: 1))
                                .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Math Operators & Functions
            HStack(spacing: 6) {
                paletteButton("+=") { insertIntoActiveTarget(" += ") }
                paletteButton("-=") { insertIntoActiveTarget(" -= ") }
                paletteButton("*=") { insertIntoActiveTarget(" *= ") }
                paletteButton("/=") { insertIntoActiveTarget(" /= ") }
                paletteButton("+") { insertIntoActiveTarget(" + ") }
                paletteButton("-") { insertIntoActiveTarget(" - ") }
                paletteButton("*") { insertIntoActiveTarget(" * ") }
                paletteButton("/") { insertIntoActiveTarget(" / ") }
                paletteButton("%") { insertIntoActiveTarget(" % ") }
                paletteButton("( )") { insertIntoActiveTarget("()") }
            }

            HStack(spacing: 6) {
                paletteButton("random(10, 50)") { insertIntoActiveTarget("random(10, 50)") }
                paletteButton("min(a, b)") { insertIntoActiveTarget("min(a, b)") }
                paletteButton("max(a, b)") { insertIntoActiveTarget("max(a, b)") }
                paletteButton("round(x)") { insertIntoActiveTarget("round(x)") }
                paletteButton("floor(x)") { insertIntoActiveTarget("floor(x)") }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AstorkaTheme.cardDark.opacity(0.5))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AstorkaTheme.borderSubtle, lineWidth: 1))
        )
    }

    private var activeTargetName: String {
        switch activeFormulaTarget {
        case .condition: return "Condition"
        case .primary: return "Primary Formula"
        case .secondary: return "Secondary Formula"
        }
    }

    private func paletteButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(AstorkaTheme.borderSubtle, lineWidth: 1))
                .foregroundStyle(Color.white.opacity(0.85))
        }
        .buttonStyle(.plain)
    }

    private func presetChip(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 10, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.05))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AstorkaTheme.borderSubtle, lineWidth: 0.8))
                .foregroundStyle(Color.white.opacity(0.8))
        }
        .buttonStyle(.plain)
    }

    private func insertIntoActiveTarget(_ text: String) {
        switch activeFormulaTarget {
        case .condition:
            choiceCondition.append(text)
        case .primary:
            choiceFormula.append(text)
        case .secondary:
            choiceSecondaryFormula.append(text)
        }
    }

    // MARK: - Feedback & Audio

    private var feedbackSection: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("FEEDBACK LOG MESSAGE (SHOWN TO PLAYER)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)

                TextField("Feedback message...", text: $choiceMessage)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(8)
                    .background(AstorkaTheme.cardDark)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AstorkaTheme.borderSubtle, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("SOUND FX")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)

                Picker("Sound", selection: $choiceSound) {
                    Text("💰 Coin").tag("coin")
                    Text("🔘 Select").tag("select")
                    Text("⚔️ Hit").tag("hit")
                    Text("🏆 Victory").tag("victory")
                    Text("🎒 Pickup").tag("pickup")
                }
                .pickerStyle(.menu)
                .frame(width: 140)
            }
        }
        .padding(14)
        .astorkaCard(isHovered: false, cornerRadius: 10)
    }

    // MARK: - In-Editor Test Simulator

    private var testSimulatorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "play.circle.fill")
                        .foregroundStyle(AstorkaTheme.emeraldNeon)
                    Text("TEST RUN FORMULA NOW (IN-EDITOR)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(AstorkaTheme.emeraldNeon)
                }

                Spacer()

                Button {
                    runInstantTest()
                } label: {
                    Label("Run Test Simulation", systemImage: "bolt.fill")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(AstorkaGlowButtonStyle(color: AstorkaTheme.emeraldNeon))
            }

            if let log = simulatedLog {
                Text(log)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(AstorkaTheme.emeraldNeon)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 6).fill(AstorkaTheme.emeraldNeon.opacity(0.1)))
            }
        }
        .padding(14)
        .astorkaCard(isHovered: false, cornerRadius: 10)
    }

    private func runInstantTest() {
        let evaluator = ExpressionEvaluator()
        var currentVars = currentVariableMap()

        var results: [String] = []

        if !choiceFormula.isEmpty {
            let before = findTargetVariableValue(choiceFormula, vars: currentVars)
            evaluator.executeStatement(choiceFormula, variables: &currentVars)
            let after = findTargetVariableValue(choiceFormula, vars: currentVars)
            results.append("Primary: \(before) ➔ \(after)")
        }

        if !choiceSecondaryFormula.isEmpty {
            let before = findTargetVariableValue(choiceSecondaryFormula, vars: currentVars)
            evaluator.executeStatement(choiceSecondaryFormula, variables: &currentVars)
            let after = findTargetVariableValue(choiceSecondaryFormula, vars: currentVars)
            results.append("Secondary: \(before) ➔ \(after)")
        }

        // Play Sound & Haptic
        state.liveRuntime?.audioManager.playSound(choiceSound, volume: 1.0)
        state.liveRuntime?.inputManager.triggerHaptic(type: .generic)

        withAnimation {
            simulatedLog = "⚡ Executed: \(results.joined(separator: " | "))"
        }
    }

    private func findTargetVariableValue(_ stmt: String, vars: [String: VariableValue]) -> String {
        for op in ["+=", "-=", "*=", "/=", "="] {
            if let r = stmt.range(of: op) {
                let name = String(stmt[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let clean = name.hasPrefix("$") ? String(name.dropFirst()) : name
                return "\(clean)=\(vars[clean]?.asString ?? "0")"
            }
        }
        return "result"
    }

    // MARK: - Footer Action Bar

    private var footerBar: some View {
        HStack(spacing: 12) {
            Button("Cancel") {
                onDismiss()
            }
            .buttonStyle(AstorkaGlassButtonStyle())

            Spacer()

            Button {
                saveChoice()
            } label: {
                Label(mode.isNew ? "Add Choice & Save Formula" : "Update Choice & Formulas", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 13, weight: .bold))
            }
            .buttonStyle(AstorkaGlowButtonStyle(color: AstorkaTheme.cyanNeon))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(AstorkaTheme.panelHeader)
        .overlay(Divider().background(AstorkaTheme.borderSubtle), alignment: .top)
    }

    private func saveChoice() {
        let choice = GameChoice(
            id: choiceId,
            label: choiceLabel,
            shortcut: choiceShortcut,
            condition: choiceCondition,
            formula: choiceFormula,
            secondaryFormula: choiceSecondaryFormula,
            message: choiceMessage,
            sound: choiceSound
        )

        switch mode {
        case .new:
            state.addGameChoice(choice)
        case .edit:
            state.updateGameChoice(choice)
        }

        onDismiss()
    }

    // MARK: - Helpers

    private func currentVariableMap() -> [String: VariableValue] {
        var map: [String: VariableValue] = [:]
        for gv in state.project.globalVariables {
            map[gv.name] = gv.initialValue
        }
        return map
    }

    private struct FormulaCalculationPreview {
        let isValid: Bool
        let previewText: String
        let breakdown: String?
    }

    private func computeFormulaPreview(_ stmt: String) -> FormulaCalculationPreview {
        let operators = ["+=", "-=", "*=", "/=", "="]
        for op in operators {
            if let range = stmt.range(of: op) {
                var varName = String(stmt[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                if varName.hasPrefix("$") { varName = String(varName.dropFirst()) }
                let expr = String(stmt[range.upperBound...]).trimmingCharacters(in: .whitespaces)

                let currentVars = currentVariableMap()
                let currentVal = currentVars[varName]?.asNumber ?? 0.0
                let evaluated = ExpressionEvaluator().evaluate(expr, variables: currentVars).asNumber

                let finalVal: Double
                switch op {
                case "+=": finalVal = currentVal + evaluated
                case "-=": finalVal = currentVal - evaluated
                case "*=": finalVal = currentVal * evaluated
                case "/=": finalVal = evaluated != 0 ? currentVal / evaluated : currentVal
                default:   finalVal = evaluated
                }

                let delta = finalVal - currentVal
                let deltaStr = delta >= 0 ? "+\(formatNumber(delta))" : "\(formatNumber(delta))"
                let preview = "$\(varName): \(formatNumber(currentVal)) ➔ \(formatNumber(finalVal)) (\(deltaStr))"
                let breakdown = "[\(expr) = \(formatNumber(evaluated))]"

                return FormulaCalculationPreview(isValid: true, previewText: preview, breakdown: breakdown)
            }
        }

        return FormulaCalculationPreview(
            isValid: false,
            previewText: "Format: variable += expression (e.g. cash += item_price * 5 / 10)",
            breakdown: nil
        )
    }

    private func formatNumber(_ num: Double) -> String {
        if num.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(num))
        } else {
            return String(format: "%.2f", num)
        }
    }
}
