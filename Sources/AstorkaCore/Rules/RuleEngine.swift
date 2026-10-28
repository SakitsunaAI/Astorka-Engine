import Foundation

public protocol RuleEngineDelegate: AnyObject {
    func ruleEngineDidRequestSceneChange(to sceneId: String)
    func ruleEngineDidRequestSoundPlay(soundId: String, volume: Float)
    func ruleEngineDidRequestHaptic(type: HapticType)
    func ruleEngineDidRequestUIUpdate(elementId: String, property: String, value: String)
    func ruleEngineDidPrintCLI(text: String, color: String?)
    func ruleEngineDidSpawnSprite(name: String, x: Double, y: Double, texture: String)
    func ruleEngineDidDestroySprite(spriteId: String)
}

public final class RuleEngine: @unchecked Sendable {
    public private(set) var variables: [String: VariableValue] = [:]
    public var dataTables: [String: DataTable] = [:]
    public var activeRules: [EventRule] = []
    public let evaluator: ExpressionEvaluator
    public weak var delegate: RuleEngineDelegate?

    public init(evaluator: ExpressionEvaluator = ExpressionEvaluator()) {
        self.evaluator = evaluator
    }

    /// Initializes variables
    public func loadVariables(_ vars: [GameVariable]) {
        for v in vars {
            variables[v.name] = v.initialValue
        }
    }

    /// Loads data tables
    public func loadDataTables(_ tables: [DataTable]) {
        for t in tables {
            dataTables[t.id] = t
        }
    }

    /// Reads variable value
    public func getVariable(_ name: String) -> VariableValue {
        let clean = name.hasPrefix("$") ? String(name.dropFirst()) : name
        if let val = variables[clean] { return val }
        if let key = variables.keys.first(where: { $0.lowercased() == clean.lowercased() }) {
            return variables[key]!
        }
        return .number(0)
    }

    /// Sets variable value and dispatches variable changed triggers
    public func setVariable(_ name: String, to value: VariableValue) {
        let clean = name.hasPrefix("$") ? String(name.dropFirst()) : name
        let matchedKey = variables.keys.first(where: { $0.lowercased() == clean.lowercased() }) ?? clean
        variables[matchedKey] = value
        dispatchTrigger(.onVariableChanged(variableName: matchedKey))
    }

    /// Dispatches a trigger to active rules and executes matching ones
    @discardableResult
    public func dispatchTrigger(_ trigger: RuleTrigger) -> Int {
        var executedCount = 0
        for rule in activeRules where rule.isEnabled {
            if matchesTrigger(rule.trigger, incoming: trigger) {
                if evaluateConditions(rule.conditions) {
                    executeActions(rule.actions)
                    executedCount += 1
                }
            }
        }
        return executedCount
    }

    private func matchesTrigger(_ ruleTrigger: RuleTrigger, incoming: RuleTrigger) -> Bool {
        switch (ruleTrigger, incoming) {
        case (.onGameStart, .onGameStart): return true
        case (.onSceneLoaded, .onSceneLoaded): return true
        case (.onTurnStart, .onTurnStart): return true
        case (.onTurnEnd, .onTurnEnd): return true
        case (.onButtonClick(let a), .onButtonClick(let b)): return a == b
        case (.onElementHover(let a), .onElementHover(let b)): return a == b
        case (.onCardPlay(let s1, let t1), .onCardPlay(let s2, let t2)): return s1 == s2 && t1 == t2
        case (.onVariableChanged(let a), .onVariableChanged(let b)): return a == b
        case (.onTimerTick(let a), .onTimerTick(let b)): return a == b
        case (.onCLICommand(let a), .onCLICommand(let b)): return a.lowercased() == b.lowercased()
        case (.onKeyPressed(let a), .onKeyPressed(let b)): return a.lowercased() == b.lowercased()
        case (.custom(let a), .custom(let b)): return a == b
        default: return false
        }
    }

    public func evaluateConditions(_ conditions: [RuleCondition]) -> Bool {
        for cond in conditions {
            switch cond {
            case .compareVariable(let variable, let op, let valueExpr):
                if variable.contains(">=") || variable.contains("<=") || variable.contains("==") || variable.contains("!=") || variable.contains(">") || variable.contains("<") {
                    if !evaluator.evaluateCondition(variable, variables: variables) {
                        return false
                    }
                } else {
                    let current = getVariable(variable)
                    let expected = evaluator.evaluate(valueExpr, variables: variables)
                    if !compareValues(current, op: op, expected: expected) {
                        return false
                    }
                }
            case .randomChance(let percentage):
                let roll = Double.random(in: 0...100)
                if roll > percentage {
                    return false
                }
            case .tableHasRow(let tableId, let column, let value):
                guard let table = dataTables[tableId] else { return false }
                if table.findRow(where: column, equals: value) == nil {
                    return false
                }
            case .isTurn(let phase):
                let currentPhase = getVariable("Turn_Phase").asString
                if currentPhase.lowercased() != phase.lowercased() {
                    return false
                }
            case .elementTextMatches(let elementId, let expected):
                let currentText = getVariable("UI_\(elementId)_Text").asString
                if currentText != expected {
                    return false
                }
            }
        }
        return true
    }

    private func compareValues(_ left: VariableValue, op: ComparisonOperator, expected: VariableValue) -> Bool {
        switch op {
        case .equal:
            return left.asString == expected.asString
        case .notEqual:
            return left.asString != expected.asString
        case .greaterThan:
            return left.asNumber > expected.asNumber
        case .lessThan:
            return left.asNumber < expected.asNumber
        case .greaterOrEqual:
            return left.asNumber >= expected.asNumber
        case .lessOrEqual:
            return left.asNumber <= expected.asNumber
        case .contains:
            return left.asString.contains(expected.asString)
        }
    }

    public func executeActions(_ actions: [RuleAction]) {
        for action in actions {
            switch action {
            case .setVariable(let variable, let expr):
                let evaluated = evaluator.evaluate(expr, variables: variables)
                let clean = variable.hasPrefix("$") ? String(variable.dropFirst()) : variable
                let matchedKey = variables.keys.first(where: { $0.lowercased() == clean.lowercased() }) ?? clean
                variables[matchedKey] = evaluated
                delegate?.ruleEngineDidRequestUIUpdate(elementId: matchedKey, property: "value", value: evaluated.asString)
                delegate?.ruleEngineDidPrintCLI(text: "📊 [\(matchedKey)] = \(evaluated.asString)", color: "cyan")

            case .modifyVariable(let variable, let op, let expr):
                let current = getVariable(variable).asNumber
                let delta = evaluator.evaluate(expr, variables: variables).asNumber
                let newNum: Double
                switch op {
                case .set: newNum = delta
                case .add: newNum = current + delta
                case .subtract: newNum = current - delta
                case .multiply: newNum = current * delta
                case .divide: newNum = delta != 0 ? current / delta : current
                }
                let clean = variable.hasPrefix("$") ? String(variable.dropFirst()) : variable
                let matchedKey = variables.keys.first(where: { $0.lowercased() == clean.lowercased() }) ?? clean
                variables[matchedKey] = .number(newNum)
                delegate?.ruleEngineDidRequestUIUpdate(elementId: matchedKey, property: "value", value: String(newNum))
                let deltaSign = (newNum - current) >= 0 ? "+\(formatNumber(newNum - current))" : "\(formatNumber(newNum - current))"
                delegate?.ruleEngineDidPrintCLI(text: "📊 [\(matchedKey)]: \(formatNumber(current)) ➔ \(formatNumber(newNum)) (\(deltaSign))", color: "cyan")

            case .changeScene(let sceneId):
                delegate?.ruleEngineDidRequestSceneChange(to: sceneId)

            case .playSound(let soundId, let volume):
                delegate?.ruleEngineDidRequestSoundPlay(soundId: soundId, volume: volume)

            case .triggerHaptic(let type):
                delegate?.ruleEngineDidRequestHaptic(type: type)

            case .setElementProperty(let elementId, let property, let valueExpr):
                let evaluated = evaluator.evaluate(valueExpr, variables: variables).asString
                delegate?.ruleEngineDidRequestUIUpdate(elementId: elementId, property: property, value: evaluated)

            case .drawCard(let tableId, let targetSlotId):
                if let table = dataTables[tableId], let card = table.randomRow() {
                    let cardName = card["name"]?.asString ?? "Card"
                    delegate?.ruleEngineDidPrintCLI(text: "🃏 [Card Drawn]: \(cardName)", color: "cyan")
                    delegate?.ruleEngineDidRequestUIUpdate(elementId: targetSlotId, property: "card", value: cardName)
                }

            case .printCLI(let text, let color):
                let interpolated = evaluator.interpolate(text, variables: variables)
                delegate?.ruleEngineDidPrintCLI(text: interpolated, color: color)

            case .advanceTurn:
                let currentTurn = getVariable("Turn_Number").asNumber
                variables["Turn_Number"] = .number(currentTurn + 1)
                dispatchTrigger(.onTurnStart)

            case .startTimer(let timerId, let durationSec, let repeats):
                DispatchQueue.global().asyncAfter(deadline: .now() + durationSec) { [weak self] in
                    self?.dispatchTrigger(.onTimerTick(timerId: timerId))
                    if repeats {
                        self?.executeActions([.startTimer(timerId: timerId, durationSec: durationSec, repeats: true)])
                    }
                }

            case .spawnSprite(let name, let x, let y, let texture):
                delegate?.ruleEngineDidSpawnSprite(name: name, x: x, y: y, texture: texture)

            case .destroySprite(let spriteId):
                delegate?.ruleEngineDidDestroySprite(spriteId: spriteId)

            case .showDialogue(let speaker, let text, let choices):
                let interpolated = evaluator.interpolate(text, variables: variables)
                delegate?.ruleEngineDidPrintCLI(text: "💬 [\(speaker)]: \(interpolated)", color: "yellow")
                for (idx, opt) in choices.enumerated() {
                    delegate?.ruleEngineDidPrintCLI(text: "   [\(idx + 1)] \(opt.text)", color: "white")
                }
            }
        }
    }

    private func formatNumber(_ num: Double) -> String {
        if num.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(num))
        } else {
            return String(format: "%.2f", num)
        }
    }
}
