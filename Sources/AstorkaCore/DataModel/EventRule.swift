import Foundation

public enum RuleTrigger: Codable, Equatable, Sendable {
    case onGameStart
    case onSceneLoaded
    case onButtonClick(elementId: String)
    case onElementHover(elementId: String)
    case onCardPlay(sourceSlotId: String, targetSlotId: String)
    case onTurnStart
    case onTurnEnd
    case onVariableChanged(variableName: String)
    case onTimerTick(timerId: String)
    case onCLICommand(command: String)
    case onKeyPressed(key: String)
    case custom(name: String)
}

public enum ComparisonOperator: String, Codable, Sendable {
    case equal = "=="
    case notEqual = "!="
    case greaterThan = ">"
    case lessThan = "<"
    case greaterOrEqual = ">="
    case lessOrEqual = "<="
    case contains = "contains"
}

public enum MathOperator: String, Codable, Sendable {
    case set = "="
    case add = "+="
    case subtract = "-="
    case multiply = "*="
    case divide = "/="
}

public enum HapticType: String, Codable, Sendable {
    case generic
    case alignment
    case levelChange
}

public enum RuleCondition: Codable, Equatable, Sendable {
    case compareVariable(variable: String, op: ComparisonOperator, valueExpr: String)
    case randomChance(percentage: Double)
    case tableHasRow(tableId: String, column: String, value: String)
    case isTurn(phase: String)
    case elementTextMatches(elementId: String, expected: String)
}

public struct DialogueOption: Codable, Equatable, Sendable {
    public var text: String
    public var nextRuleOrScene: String

    public init(text: String, nextRuleOrScene: String) {
        self.text = text
        self.nextRuleOrScene = nextRuleOrScene
    }
}

public enum RuleAction: Codable, Equatable, Sendable {
    case setVariable(variable: String, expr: String)
    case modifyVariable(variable: String, op: MathOperator, expr: String)
    case changeScene(sceneId: String)
    case playSound(soundId: String, volume: Float)
    case triggerHaptic(type: HapticType)
    case setElementProperty(elementId: String, property: String, valueExpr: String)
    case drawCard(tableId: String, targetSlotId: String)
    case printCLI(text: String, color: String?)
    case advanceTurn
    case startTimer(timerId: String, durationSec: Double, repeats: Bool)
    case spawnSprite(name: String, x: Double, y: Double, texture: String)
    case destroySprite(spriteId: String)
    case showDialogue(speaker: String, text: String, choices: [DialogueOption])
}

/// No-Code Event Rule: Evaluates conditions on a trigger and executes actions
public struct EventRule: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var isEnabled: Bool
    public var trigger: RuleTrigger
    public var conditions: [RuleCondition]
    public var actions: [RuleAction]

    public init(
        id: String = UUID().uuidString,
        name: String,
        isEnabled: Bool = true,
        trigger: RuleTrigger,
        conditions: [RuleCondition] = [],
        actions: [RuleAction] = []
    ) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.trigger = trigger
        self.conditions = conditions
        self.actions = actions
    }
}
