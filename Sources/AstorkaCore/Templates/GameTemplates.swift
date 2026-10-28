import Foundation

public struct GameTemplates {
    /// 1. CARD & DECKBUILDER TEMPLATE (Balatro & Slay the Spire Style)
    public static func createDeckbuilderTemplate() -> GameProject {
        let cardsTable = DataTable(
            id: "Cards",
            name: "Game Cards",
            columns: [
                DataColumn(name: "name", type: .string),
                DataColumn(name: "cost", type: .number),
                DataColumn(name: "chips", type: .number),
                DataColumn(name: "mult", type: .number),
                DataColumn(name: "description", type: .string)
            ],
            rows: [
                ["name": .string("Ace Card"), "cost": .number(1), "chips": .number(50), "mult": .number(2), "description": .string("+50 Chips, x2 Mult")],
                ["name": .string("King of Hearts"), "cost": .number(2), "chips": .number(80), "mult": .number(3), "description": .string("+80 Chips, x3 Mult")],
                ["name": .string("Joker Card"), "cost": .number(3), "chips": .number(120), "mult": .number(5), "description": .string("+120 Chips, x5 Mult")]
            ]
        )

        let initialVariables = [
            GameVariable(name: "Score", initialValue: .number(0), category: "Stats", description: "Current Round Score"),
            GameVariable(name: "Target_Score", initialValue: .number(300), category: "Objectives", description: "Required Target Score"),
            GameVariable(name: "Gold", initialValue: .number(15), category: "Economy", description: "Player Gold"),
            GameVariable(name: "Hands_Left", initialValue: .number(4), category: "Gameplay", description: "Remaining Hands"),
            GameVariable(name: "Discards_Left", initialValue: .number(3), category: "Gameplay", description: "Remaining Discards")
        ]

        let battleScene = GameScene(
            id: "battle_scene",
            name: "Card Table",
            type: .hybrid,
            backgroundColor: UIColorRGBA(r: 0.08, g: 0.12, b: 0.10, a: 1.0), // Deep poker green
            uiElements: [
                UIElement(id: "lbl_score", name: "Score Panel", type: .label, x: 0, y: 50, width: 300, height: 60, anchor: .topCenter, text: "Score:", bindingVariable: "Score"),
                UIElement(id: "lbl_target", name: "Target Panel", type: .label, x: 0, y: 110, width: 300, height: 40, anchor: .topCenter, text: "Target: {$Target_Score}"),
                UIElement(id: "btn_play_card", name: "Play Hand Button", type: .button, x: -160, y: 100, width: 140, height: 50, anchor: .bottomCenter, text: "🃏 Play Hand"),
                UIElement(id: "btn_discard", name: "Discard Button", type: .button, x: 160, y: 100, width: 140, height: 50, anchor: .bottomCenter, text: "♻️ Discard"),
                UIElement(id: "btn_shop", name: "Go to Shop", type: .button, x: 30, y: 30, width: 120, height: 44, anchor: .topRight, text: "🏪 Shop")
            ],
            rules: [
                EventRule(
                    name: "Calculate Score on Card Play",
                    trigger: .onButtonClick(elementId: "btn_play_card"),
                    conditions: [.compareVariable(variable: "Hands_Left", op: .greaterThan, valueExpr: "0")],
                    actions: [
                        .modifyVariable(variable: "Score", op: .add, expr: "random(60, 150)"),
                        .modifyVariable(variable: "Hands_Left", op: .subtract, expr: "1"),
                        .playSound(soundId: "coin", volume: 1.0),
                        .triggerHaptic(type: .levelChange),
                        .printCLI(text: "🃏 Hand played! New Score: {$Score} / {$Target_Score}", color: "cyan")
                    ]
                ),
                EventRule(
                    name: "Victory on Target Score Reached",
                    trigger: .onVariableChanged(variableName: "Score"),
                    conditions: [.compareVariable(variable: "Score", op: .greaterOrEqual, valueExpr: "$Target_Score")],
                    actions: [
                        .playSound(soundId: "victory", volume: 1.0),
                        .triggerHaptic(type: .alignment),
                        .printCLI(text: "🎉 CONGRATULATIONS! Target score cleared and round won!", color: "green"),
                        .modifyVariable(variable: "Gold", op: .add, expr: "10")
                    ]
                )
            ]
        )

        return GameProject(
            title: "Astorka Deckbuilder (Balatro Style)",
            author: "Astorka Studios",
            initialSceneId: "battle_scene",
            globalVariables: initialVariables,
            dataTables: [cardsTable],
            scenes: [battleScene]
        )
    }

    /// 2. MANAGEMENT & SIMULATION TEMPLATE (Tycoon Style)
    public static func createManagementSimTemplate() -> GameProject {
        let variables = [
            GameVariable(name: "Day", initialValue: .number(1), category: "Time"),
            GameVariable(name: "Budget", initialValue: .number(50000), category: "Finance"),
            GameVariable(name: "Reputation", initialValue: .number(60), category: "Reputation"),
            GameVariable(name: "Team_Morale", initialValue: .number(80), category: "Team")
        ]

        let mainScene = GameScene(
            id: "office_scene",
            name: "Manager Office",
            type: .uiCanvas,
            uiElements: [
                UIElement(id: "lbl_budget", name: "Budget", type: .label, x: 40, y: 40, width: 220, height: 40, anchor: .topLeft, text: "Budget: {$Budget} $"),
                UIElement(id: "lbl_day", name: "Day", type: .label, x: 40, y: 90, width: 180, height: 40, anchor: .topLeft, text: "Day: {$Day}"),
                UIElement(id: "btn_scout", name: "Scout Talent", type: .button, x: 0, y: -40, width: 200, height: 48, anchor: .center, text: "🔍 Scout Talent (-$5,000)"),
                UIElement(id: "btn_next_day", name: "Advance Day", type: .button, x: 0, y: 40, width: 200, height: 48, anchor: .center, text: "📅 Advance Day")
            ],
            rules: [
                EventRule(
                    name: "Scout Talent",
                    trigger: .onButtonClick(elementId: "btn_scout"),
                    conditions: [.compareVariable(variable: "Budget", op: .greaterOrEqual, valueExpr: "5000")],
                    actions: [
                        .modifyVariable(variable: "Budget", op: .subtract, expr: "5000"),
                        .modifyVariable(variable: "Reputation", op: .add, expr: "2"),
                        .playSound(soundId: "select", volume: 0.9),
                        .printCLI(text: "🔍 Scout discovered fresh talent! Reputation increased.", color: "cyan")
                    ]
                ),
                EventRule(
                    name: "Advance Day",
                    trigger: .onButtonClick(elementId: "btn_next_day"),
                    actions: [
                        .modifyVariable(variable: "Day", op: .add, expr: "1"),
                        .modifyVariable(variable: "Budget", op: .add, expr: "2500"),
                        .playSound(soundId: "coin", volume: 0.8),
                        .printCLI(text: "📅 Advanced to Day {$Day}. Daily revenue collected: +$2,500", color: "yellow")
                    ]
                )
            ]
        )

        return GameProject(
            title: "Astorka Tycoon (Simulation)",
            initialSceneId: "office_scene",
            globalVariables: variables,
            scenes: [mainScene]
        )
    }

    /// 3. TEXT / CLI RPG ADVENTURE TEMPLATE (Dungeon Crawler)
    public static func createTextRPGTemplate() -> GameProject {
        let variables = [
            GameVariable(name: "HP", initialValue: .number(100), category: "Character"),
            GameVariable(name: "Max_HP", initialValue: .number(100), category: "Character"),
            GameVariable(name: "Gold", initialValue: .number(20), category: "Inventory"),
            GameVariable(name: "Attack", initialValue: .number(15), category: "Character"),
            GameVariable(name: "Enemy_HP", initialValue: .number(50), category: "Combat"),
            GameVariable(name: "Dungeon_Floor", initialValue: .number(1), category: "Progression")
        ]

        let dungeonScene = GameScene(
            id: "dungeon_entrance",
            name: "Dungeon Gate",
            type: .cliTerminal,
            uiElements: [
                UIElement(id: "btn_attack", name: "Attack", type: .button, text: "⚔️ Attack Monster"),
                UIElement(id: "btn_potion", name: "Drink Potion", type: .button, text: "🧪 Drink Health Potion (+30 HP / -10 Gold)"),
                UIElement(id: "btn_next_floor", name: "Next Floor", type: .button, text: "🚪 Descend to Next Floor")
            ],
            rules: [
                EventRule(
                    name: "Attack Enemy",
                    trigger: .onButtonClick(elementId: "btn_attack"),
                    conditions: [.compareVariable(variable: "Enemy_HP", op: .greaterThan, valueExpr: "0")],
                    actions: [
                        .modifyVariable(variable: "Enemy_HP", op: .subtract, expr: "$Attack + random(1, 5)"),
                        .modifyVariable(variable: "HP", op: .subtract, expr: "random(5, 12)"),
                        .playSound(soundId: "hit", volume: 1.0),
                        .triggerHaptic(type: .levelChange),
                        .printCLI(text: "💥 Swung your sword! Monster HP remaining: {$Enemy_HP}", color: "red"),
                        .printCLI(text: "🛡️ Monster struck back! Your HP remaining: {$HP}", color: "yellow")
                    ]
                ),
                EventRule(
                    name: "Defeat Monster",
                    trigger: .onVariableChanged(variableName: "Enemy_HP"),
                    conditions: [.compareVariable(variable: "Enemy_HP", op: .lessOrEqual, valueExpr: "0")],
                    actions: [
                        .playSound(soundId: "victory", volume: 1.0),
                        .modifyVariable(variable: "Gold", op: .add, expr: "25"),
                        .printCLI(text: "🏆 You defeated the monster! Found 25 gold in the chest!", color: "green")
                    ]
                ),
                EventRule(
                    name: "Drink Potion",
                    trigger: .onButtonClick(elementId: "btn_potion"),
                    conditions: [.compareVariable(variable: "Gold", op: .greaterOrEqual, valueExpr: "10")],
                    actions: [
                        .modifyVariable(variable: "Gold", op: .subtract, expr: "10"),
                        .modifyVariable(variable: "HP", op: .add, expr: "30"),
                        .playSound(soundId: "pickup", volume: 1.0),
                        .printCLI(text: "✨ Drank health potion! Restored HP: {$HP}/100", color: "green")
                    ]
                )
            ]
        )

        return GameProject(
            title: "Astorka Dungeon (CLI RPG)",
            initialSceneId: "dungeon_entrance",
            globalVariables: variables,
            scenes: [dungeonScene]
        )
    }

    /// 4. BUSINESS & FACTORY TRADE TEMPLATE (Formula & Choice Driven Simulation)
    public static func createBusinessTradeTemplate() -> GameProject {
        let variables = [
            GameVariable(name: "Cash", initialValue: .number(1500), category: "Finance", description: "Current Cash"),
            GameVariable(name: "Raw_Materials", initialValue: .number(20), category: "Inventory", description: "Warehouse Stock"),
            GameVariable(name: "item_price", initialValue: .number(100), category: "Market", description: "Unit Selling Price"),
            GameVariable(name: "Day", initialValue: .number(1), category: "Time", description: "Current Business Day")
        ]

        let factoryScene = GameScene(
            id: "factory_management",
            name: "Factory & Trade Management",
            type: .hybrid,
            backgroundColor: UIColorRGBA(r: 0.10, g: 0.12, b: 0.16, a: 1.0),
            uiElements: [
                UIElement(id: "lbl_cash", name: "Cash", type: .label, x: 40, y: 40, width: 260, height: 40, anchor: .topLeft, text: "💵 Cash: {$Cash} $"),
                UIElement(id: "lbl_stock", name: "Stock", type: .label, x: 40, y: 85, width: 260, height: 40, anchor: .topLeft, text: "📦 Raw Materials: {$Raw_Materials} Units"),
                UIElement(id: "lbl_price", name: "Price", type: .label, x: 40, y: 130, width: 320, height: 40, anchor: .topLeft, text: "🏷️ Item Market Price: {$item_price} $"),
                UIElement(id: "lbl_day", name: "Day", type: .label, x: 40, y: 175, width: 200, height: 40, anchor: .topLeft, text: "📅 Day: {$Day}"),

                UIElement(id: "btn_sell_goods", name: "Sell Materials", type: .button, x: 0, y: -70, width: 340, height: 48, anchor: .center, text: "1. Sell Processed Materials (Price*5/10)"),
                UIElement(id: "btn_buy_raw", name: "Buy Raw Materials", type: .button, x: 0, y: -10, width: 340, height: 48, anchor: .center, text: "2. Buy Bulk Raw Materials (-$200 / +15 Units)"),
                UIElement(id: "btn_upgrade_tech", name: "Upgrade Tech", type: .button, x: 0, y: 50, width: 340, height: 48, anchor: .center, text: "3. Upgrade Processing Tech (-$350)"),
                UIElement(id: "btn_next_day", name: "End Day", type: .button, x: 0, y: 110, width: 340, height: 48, anchor: .center, text: "4. End Day & Update Market")
            ],
            rules: [
                EventRule(
                    name: "1. Sell Raw Materials & Add to Cash",
                    trigger: .onButtonClick(elementId: "btn_sell_goods"),
                    conditions: [
                        .compareVariable(variable: "Raw_Materials", op: .greaterOrEqual, valueExpr: "5")
                    ],
                    actions: [
                        .modifyVariable(variable: "Cash", op: .add, expr: "item_price * 5 / 10"),
                        .modifyVariable(variable: "Raw_Materials", op: .subtract, expr: "5"),
                        .playSound(soundId: "coin", volume: 1.0),
                        .triggerHaptic(type: .levelChange),
                        .printCLI(text: "💰 Processed and sold 5 raw materials! (Formula: item_price * 5 / 10). Cash: {$Cash} $, Left: {$Raw_Materials}", color: "green")
                    ]
                ),
                EventRule(
                    name: "2. Buy Bulk Raw Materials",
                    trigger: .onButtonClick(elementId: "btn_buy_raw"),
                    conditions: [
                        .compareVariable(variable: "Cash", op: .greaterOrEqual, valueExpr: "200")
                    ],
                    actions: [
                        .modifyVariable(variable: "Cash", op: .subtract, expr: "200"),
                        .modifyVariable(variable: "Raw_Materials", op: .add, expr: "15"),
                        .playSound(soundId: "pickup", volume: 1.0),
                        .triggerHaptic(type: .generic),
                        .printCLI(text: "📦 Purchased 15 raw materials! Cash: {$Cash} $, Stock: {$Raw_Materials} Units", color: "cyan")
                    ]
                ),
                EventRule(
                    name: "3. Upgrade Factory Tech",
                    trigger: .onButtonClick(elementId: "btn_upgrade_tech"),
                    conditions: [
                        .compareVariable(variable: "Cash", op: .greaterOrEqual, valueExpr: "350")
                    ],
                    actions: [
                        .modifyVariable(variable: "Cash", op: .subtract, expr: "350"),
                        .modifyVariable(variable: "item_price", op: .add, expr: "25"),
                        .playSound(soundId: "victory", volume: 1.0),
                        .triggerHaptic(type: .alignment),
                        .printCLI(text: "⚙️ Factory technology upgraded! New item unit price: {$item_price} $", color: "yellow")
                    ]
                ),
                EventRule(
                    name: "4. End Day",
                    trigger: .onButtonClick(elementId: "btn_next_day"),
                    actions: [
                        .modifyVariable(variable: "Day", op: .add, expr: "1"),
                        .modifyVariable(variable: "item_price", op: .add, expr: "random(-10, 15)"),
                        .playSound(soundId: "select", volume: 0.8),
                        .printCLI(text: "📅 Advanced to Day {$Day}! Market price adjusted to {$item_price} $", color: "yellow")
                    ]
                )
            ]
        )

        return GameProject(
            title: "Astorka Business & Factory Simulation",
            author: "Astorka Tycoon",
            initialSceneId: "factory_management",
            globalVariables: variables,
            scenes: [factoryScene]
        )
    }
}
