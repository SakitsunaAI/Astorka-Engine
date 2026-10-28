import Testing
import Foundation
@testable import AstorkaCore

@Suite("AstorkaCore Engine Tests")
struct AstorkaCoreTests {

    @Test("ExpressionEvaluator math and variable evaluation test")
    func testExpressionEvaluator() {
        let evaluator = ExpressionEvaluator()
        let vars: [String: VariableValue] = [
            "Gold": .number(100),
            "Damage": .number(25),
            "Name": .string("Hero")
        ]

        // Arithmetic and variable substitution
        let result1 = evaluator.evaluate("$Gold + 50", variables: vars)
        #expect(result1.asNumber == 150)

        let result2 = evaluator.evaluate("$Damage * 2", variables: vars)
        #expect(result2.asNumber == 50)

        // String interpolation
        let textResult = evaluator.interpolate("Welcome, {$Name}! You have {$Gold} gold in your pouch.", variables: vars)
        #expect(textResult == "Welcome, Hero! You have 100 gold in your pouch.")

        // min / max / clamp functions
        let clampResult = evaluator.evaluate("clamp(150, 0, 100)", variables: vars)
        #expect(clampResult.asNumber == 100)
    }

    @Test("DataTable row query and filtering test")
    func testDataTable() {
        let table = DataTable(
            id: "Cards",
            name: "Cards",
            columns: [
                DataColumn(name: "name", type: .string),
                DataColumn(name: "cost", type: .number)
            ],
            rows: [
                ["name": .string("Fireball"), "cost": .number(3)],
                ["name": .string("Ice Shield"), "cost": .number(2)]
            ]
        )

        let found = table.findRow(where: "name", equals: "Fireball")
        #expect(found != nil)
        #expect(found?["cost"]?.asNumber == 3)
    }

    @Test("RuleEngine trigger and action dispatch test")
    func testRuleEngine() {
        let engine = RuleEngine()
        engine.loadVariables([
            GameVariable(name: "Mana", initialValue: .number(20)),
            GameVariable(name: "Enemy_HP", initialValue: .number(50))
        ])

        // Rule: On button click, if Mana >= 5, subtract 5 from Mana and 15 from Enemy_HP
        let rule = EventRule(
            name: "Cast Spell",
            trigger: .onButtonClick(elementId: "btn_spell"),
            conditions: [
                .compareVariable(variable: "Mana", op: .greaterOrEqual, valueExpr: "5")
            ],
            actions: [
                .modifyVariable(variable: "Mana", op: .subtract, expr: "5"),
                .modifyVariable(variable: "Enemy_HP", op: .subtract, expr: "15")
            ]
        )
        engine.activeRules = [rule]

        let executed = engine.dispatchTrigger(.onButtonClick(elementId: "btn_spell"))
        #expect(executed == 1)
        #expect(engine.getVariable("Mana").asNumber == 15)
        #expect(engine.getVariable("Enemy_HP").asNumber == 35)
    }

    @Test("GameProject JSON Serialization and Sample Generation")
    func testProjectJSON() throws {
        let deckbuilder = GameTemplates.createDeckbuilderTemplate()
        let tycoon = GameTemplates.createManagementSimTemplate()
        let dungeon = GameTemplates.createTextRPGTemplate()

        let deckData = try deckbuilder.toJSONData()
        let tycoonData = try tycoon.toJSONData()
        let dungeonData = try dungeon.toJSONData()

        let restored = try GameProject.fromJSONData(deckData)
        #expect(restored.title == deckbuilder.title)
        #expect(restored.globalVariables.count == deckbuilder.globalVariables.count)
        #expect(restored.scenes.count == deckbuilder.scenes.count)

        let examplesURL = URL(fileURLWithPath: "Examples")
        try? FileManager.default.createDirectory(at: examplesURL, withIntermediateDirectories: true)
        try? deckData.write(to: examplesURL.appendingPathComponent("Deckbuilder.json"))
        try? tycoonData.write(to: examplesURL.appendingPathComponent("Tycoon.json"))
        try? dungeonData.write(to: examplesURL.appendingPathComponent("DungeonRPG.json"))
    }
}
