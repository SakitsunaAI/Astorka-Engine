import Foundation

/// Choice & Action Decision Model
/// Designed for creators building menu options, choices, and game logic without code.
/// Generates CLI terminal choices, UI buttons, and rules from a single declarative form.
public struct GameChoice: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var label: String               // e.g. "1. Sell Raw Materials"
    public var shortcut: String            // e.g. "1" or "sell"
    public var condition: String           // e.g. "raw_materials >= 5"
    public var formula: String             // e.g. "cash += item_price * 5 / 10"
    public var secondaryFormula: String    // e.g. "raw_materials -= 5"
    public var message: String             // e.g. "Processed and sold 5 raw materials!"
    public var sound: String               // e.g. "coin"

    public init(
        id: String = "choice_\(UUID().uuidString.prefix(6))",
        label: String,
        shortcut: String = "",
        condition: String = "",
        formula: String = "",
        secondaryFormula: String = "",
        message: String = "",
        sound: String = "coin"
    ) {
        self.id = id
        self.label = label
        self.shortcut = shortcut.isEmpty ? String(label.prefix(1)) : shortcut
        self.condition = condition
        self.formula = formula
        self.secondaryFormula = secondaryFormula
        self.message = message
        self.sound = sound
    }

    /// Converts this choice into an EventRule automatically
    public func toEventRule() -> EventRule {
        var actions: [RuleAction] = []

        // Execute formulas
        if !formula.isEmpty {
            actions.append(parseFormulaToAction(formula))
        }
        if !secondaryFormula.isEmpty {
            actions.append(parseFormulaToAction(secondaryFormula))
        }

        if !message.isEmpty {
            actions.append(.printCLI(text: "📦 " + message, color: "green"))
        }

        if !sound.isEmpty {
            actions.append(.playSound(soundId: sound, volume: 1.0))
        }

        actions.append(.triggerHaptic(type: .levelChange))

        var conditions: [RuleCondition] = []
        if !condition.trimmingCharacters(in: .whitespaces).isEmpty {
            conditions.append(parseCondition(condition))
        }

        return EventRule(
            id: id,
            name: label,
            trigger: .onButtonClick(elementId: id),
            conditions: conditions,
            actions: actions
        )
    }

    private func parseCondition(_ cond: String) -> RuleCondition {
        let trimmed = cond.trimmingCharacters(in: .whitespacesAndNewlines)
        let ops: [(String, ComparisonOperator)] = [
            (">=", .greaterOrEqual),
            ("<=", .lessOrEqual),
            ("==", .equal),
            ("!=", .notEqual),
            (">", .greaterThan),
            ("<", .lessThan)
        ]
        for (symbol, compOp) in ops {
            if let range = trimmed.range(of: symbol) {
                var varName = String(trimmed[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                if varName.hasPrefix("$") { varName = String(varName.dropFirst()) }
                let expr = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                return .compareVariable(variable: varName, op: compOp, valueExpr: expr)
            }
        }
        return .compareVariable(variable: trimmed, op: .equal, valueExpr: "true")
    }

    private func parseFormulaToAction(_ form: String) -> RuleAction {
        let operators = ["+=", "-=", "*=", "/=", "="]
        for op in operators {
            if let range = form.range(of: op) {
                var varName = String(form[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                if varName.hasPrefix("$") { varName = String(varName.dropFirst()) }
                let expr = String(form[range.upperBound...]).trimmingCharacters(in: .whitespaces)

                let mathOp: MathOperator
                switch op {
                case "+=": mathOp = .add
                case "-=": mathOp = .subtract
                case "*=": mathOp = .multiply
                case "/=": mathOp = .divide
                default:   mathOp = .set
                }
                return .modifyVariable(variable: varName, op: mathOp, expr: expr)
            }
        }
        return .setVariable(variable: "Temp", expr: form)
    }
}
