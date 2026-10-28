import Foundation
import SwiftUI
import AstorkaCore

public enum AppScreen {
    case hub        // Main Menu (Project Launcher & Hub)
    case editor     // Game Design Editor
}

public struct SavedProjectItem: Identifiable, Equatable {
    public var id: String { url.path }
    public let title: String
    public let type: ProjectType
    public let modifiedDate: Date
    public let url: URL
}

public enum EditorTab: String, CaseIterable, Identifiable {
    case choices = "📋 Choices & Formulas"
    case canvas = "🎨 Visual Canvas"
    case tables = "📊 Data Tables"
    case variables = "⚙️ Variables & Stats"
    case playtest = "▶️ Play / Live Test"

    public var id: String { rawValue }
}

@MainActor
public final class AppState: ObservableObject {
    @Published public var currentScreen: AppScreen = .hub
    @Published public var currentProjectURL: URL? = nil
    @Published public var savedProjects: [SavedProjectItem] = []

    @Published public var project: GameProject
    @Published public var selectedSceneId: String = ""
    @Published public var selectedElementId: String? = nil
    @Published public var selectedTableId: String? = nil
    @Published public var activeTab: EditorTab = .choices

    public var availableTabs: [EditorTab] {
        if project.type == .cli {
            return [.choices, .variables, .playtest]
        } else {
            return [.choices, .canvas, .variables, .tables, .playtest]
        }
    }

    // Live Game Execution Runtime
    @Published public var liveRuntime: AstorkaGameRuntime? = nil
    @Published public var isPlaying: Bool = false
    @Published public var consoleLogs: [String] = []

    public static var projectsDirectoryURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory())
        let dir = docs.appendingPathComponent("AstorkaProjects", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    public init() {
        let initial = GameProject.empty(title: "New Project", type: .cli)
        self.project = initial
        self.selectedSceneId = initial.scenes.first?.id ?? ""
        self.selectedTableId = nil
        self.activeTab = .choices
        self.currentScreen = .hub // Start directly in the Project Hub
        loadSavedProjects()
    }

    /// Scan and load saved .astorkaproject files
    public func loadSavedProjects() {
        var list: [SavedProjectItem] = []
        let fm = FileManager.default
        let dir = Self.projectsDirectoryURL

        // 1. Scan ~/Documents/AstorkaProjects directory
        if let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles) {
            for file in files where file.pathExtension == "astorkaproject" {
                if let item = parseProjectItem(at: file) {
                    list.append(item)
                }
            }
        }

        // 2. Also scan current working directory for .astorkaproject files
        let cwdURL = URL(fileURLWithPath: fm.currentDirectoryPath)
        if let cwdFiles = try? fm.contentsOfDirectory(at: cwdURL, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles) {
            for file in cwdFiles where file.pathExtension == "astorkaproject" {
                if !list.contains(where: { $0.url.path == file.path }) {
                    if let item = parseProjectItem(at: file) {
                        list.append(item)
                    }
                }
            }
        }

        self.savedProjects = list.sorted(by: { $0.modifiedDate > $1.modifiedDate })
    }

    private func parseProjectItem(at url: URL) -> SavedProjectItem? {
        guard let data = try? Data(contentsOf: url),
              let proj = try? GameProject.fromJSONData(data) else {
            return nil
        }
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        let date = (attrs?[.modificationDate] as? Date) ?? Date()
        return SavedProjectItem(title: proj.title, type: proj.type, modifiedDate: date, url: url)
    }

    /// Create a new project and open it in the editor (saved as .astorkaproject)
    public func createAndOpenProject(title: String, type: ProjectType) {
        stopPlaytest()
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = cleanTitle.isEmpty ? "New Project" : cleanTitle

        let newProj = GameProject.empty(title: finalTitle, type: type)
        self.project = newProj
        self.selectedSceneId = newProj.scenes.first?.id ?? ""
        self.selectedElementId = nil
        self.selectedTableId = nil
        self.activeTab = .choices

        // Pre-seed starter variables so choices have live numbers immediately
        self.project.globalVariables = [
            GameVariable(name: "cash", initialValue: .number(100), category: "Economy"),
            GameVariable(name: "raw_materials", initialValue: .number(20), category: "Inventory"),
            GameVariable(name: "item_price", initialValue: .number(50), category: "Economy")
        ]

        // Pre-seed starter choices with formulas
        let choice1 = GameChoice(
            id: "choice_sell",
            label: "1. Sell Raw Materials",
            shortcut: "1",
            condition: "raw_materials >= 5",
            formula: "cash += item_price * 5 / 10",
            secondaryFormula: "raw_materials -= 5",
            message: "Sold 5 raw materials for cash!",
            sound: "coin"
        )
        let choice2 = GameChoice(
            id: "choice_gather",
            label: "2. Gather Raw Ore",
            shortcut: "2",
            condition: "",
            formula: "raw_materials += 10",
            secondaryFormula: "",
            message: "Gathered 10 raw materials from the mine!",
            sound: "pickup"
        )
        addGameChoice(choice1)
        addGameChoice(choice2)

        let safeName = finalTitle
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined(separator: "_")
        let filename = safeName.isEmpty ? "project.astorkaproject" : "\(safeName).astorkaproject"
        let fileURL = Self.projectsDirectoryURL.appendingPathComponent(filename)

        self.currentProjectURL = fileURL
        saveCurrentProject()

        self.currentScreen = .editor
        loadSavedProjects()
    }

    /// Open a saved project
    public func openProject(item: SavedProjectItem) {
        stopPlaytest()
        do {
            let data = try Data(contentsOf: item.url)
            let loaded = try GameProject.fromJSONData(data)
            self.project = loaded
            self.currentProjectURL = item.url
            self.selectedSceneId = loaded.scenes.first?.id ?? ""
            self.selectedElementId = nil
            self.selectedTableId = loaded.dataTables.first?.id
            self.activeTab = .choices
            self.currentScreen = .editor
        } catch {
            print("Error opening project: \(error)")
        }
    }

    /// Delete project
    public func deleteProject(item: SavedProjectItem) {
        try? FileManager.default.removeItem(at: item.url)
        loadSavedProjects()
    }

    /// Save current project
    public func saveCurrentProject() {
        do {
            let data = try project.toJSONData()
            let safeName = project.title
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .joined(separator: "_")
            let filename = safeName.isEmpty ? "project.astorkaproject" : "\(safeName).astorkaproject"
            let targetURL = currentProjectURL ?? Self.projectsDirectoryURL.appendingPathComponent(filename)

            try data.write(to: targetURL)
            self.currentProjectURL = targetURL

            // Also update AstorkaProject.json for instant CLI testing
            try? data.write(to: URL(fileURLWithPath: "AstorkaProject.json"))
            loadSavedProjects()
        } catch {
            print("Save error: \(error)")
        }
    }

    /// Return to Project Hub
    public func returnToHub() {
        saveCurrentProject()
        stopPlaytest()
        self.currentScreen = .hub
        loadSavedProjects()
    }

    /// Create a new empty project (quick switch inside editor)
    public func createEmptyProject(title: String, type: ProjectType) {
        createAndOpenProject(title: title, type: type)
    }

    public var currentScene: GameScene? {
        get {
            project.scenes.first { $0.id == selectedSceneId } ?? project.scenes.first
        }
        set {
            if let newValue = newValue,
               let idx = project.scenes.firstIndex(where: { $0.id == newValue.id }) {
                project.scenes[idx] = newValue
            }
        }
    }

    public var selectedElement: UIElement? {
        guard let currentScene = currentScene, let elId = selectedElementId else { return nil }
        return currentScene.uiElements.first { $0.id == elId }
    }

    /// Add a new choice & formula (generates rule and choice from a single form)
    public func addGameChoice(_ choice: GameChoice) {
        guard var scene = currentScene else { return }

        // 1. Create UI button
        let btnY = Double(scene.uiElements.filter { $0.type == .button }.count * 56) - 80.0
        let button = UIElement(
            id: choice.id,
            name: choice.label,
            type: .button,
            x: 0,
            y: btnY,
            width: 340,
            height: 48,
            anchor: .center,
            text: choice.label
        )
        scene.uiElements.append(button)

        // 2. Create rule (formulas and sounds)
        let rule = choice.toEventRule()
        scene.rules.append(rule)

        // 3. Automatically register variables from formulas
        autoRegisterVariables(from: choice)

        self.currentScene = scene
    }

    /// Update an existing choice and its formulas
    public func updateGameChoice(_ choice: GameChoice) {
        guard var scene = currentScene else { return }

        // 1. Update UI button text and label
        if let idx = scene.uiElements.firstIndex(where: { $0.id == choice.id }) {
            scene.uiElements[idx].name = choice.label
            scene.uiElements[idx].text = choice.label
        }

        // 2. Update Rule (trigger on this choice button)
        let updatedRule = choice.toEventRule()
        if let ruleIdx = scene.rules.firstIndex(where: { $0.id == choice.id || $0.trigger == .onButtonClick(elementId: choice.id) }) {
            scene.rules[ruleIdx] = updatedRule
        } else {
            scene.rules.append(updatedRule)
        }

        // 3. Automatically register variables from updated formulas
        autoRegisterVariables(from: choice)

        self.currentScene = scene
    }

    private func autoRegisterVariables(from choice: GameChoice) {
        let combined = "\(choice.condition) \(choice.formula) \(choice.secondaryFormula)"
        guard let regex = try? NSRegularExpression(pattern: "[a-zA-Z_][a-zA-Z0-9_]*") else { return }
        let matches = regex.matches(in: combined, range: NSRange(combined.startIndex..., in: combined))
        
        let reserved: Set<String> = ["true", "false", "and", "or", "not"]
        for m in matches {
            guard let r = Range(m.range, in: combined) else { continue }
            let varName = String(combined[r])
            if !reserved.contains(varName.lowercased()) && !project.globalVariables.contains(where: { $0.name == varName }) {
                let initialVal: Double = varName.lowercased().contains("price") ? 50.0 : (varName.lowercased().contains("cash") || varName.lowercased().contains("gold") ? 100.0 : 10.0)
                let gVar = GameVariable(name: varName, initialValue: .number(initialVal))
                project.globalVariables.append(gVar)
            }
        }
    }

    // MARK: - Scene & Element Creation

    public func addElement(type: UIElementType) {
        guard var scene = currentScene else { return }
        let id = "el_\(UUID().uuidString.prefix(6))"
        let name: String
        let width: Double
        let height: Double
        var text: String = ""

        switch type {
        case .button:
            name = "New Button"
            width = 160; height = 48
            text = "Click"
        case .label:
            name = "Text Label"
            width = 200; height = 36
            text = "Text..."
        case .cardView:
            name = "Card View"
            width = 140; height = 200
            text = "Sample Card"
        case .cardSlot:
            name = "Card Slot"
            width = 150; height = 210
            text = "Place Card Here"
        case .panel:
            name = "Box Panel"
            width = 300; height = 200
        case .gaugeBar:
            name = "Health / Resource Bar"
            width = 240; height = 28
            text = "Health: 100/100"
        case .dialogueBox:
            name = "Dialogue Box"
            width = 600; height = 140
            text = "Character: Welcome adventurer!"
        case .cliWindow:
            name = "Terminal Window"
            width = 500; height = 300
            text = "Astorka CLI Terminal"
        case .textInput, .inventoryGrid:
            name = "Input Field"
            width = 200; height = 40
        }

        let newElement = UIElement(
            id: id,
            name: name,
            type: type,
            x: 0,
            y: 0,
            width: width,
            height: height,
            anchor: .center,
            text: text
        )

        scene.uiElements.append(newElement)
        self.currentScene = scene
        self.selectedElementId = id
    }

    public func updateSelectedElement(_ updated: UIElement) {
        guard var scene = currentScene,
              let idx = scene.uiElements.firstIndex(where: { $0.id == updated.id }) else { return }
        scene.uiElements[idx] = updated
        self.currentScene = scene
    }

    public func deleteSelectedElement() {
        guard let elId = selectedElementId, var scene = currentScene else { return }
        scene.uiElements.removeAll { $0.id == elId }
        self.currentScene = scene
        self.selectedElementId = nil
    }

    // MARK: - Data Table Operations

    public func addDataTable() {
        let id = "table_\(project.dataTables.count + 1)"
        let newTable = DataTable(
            id: id,
            name: "New Table \(project.dataTables.count + 1)",
            columns: [
                DataColumn(name: "name", type: .string),
                DataColumn(name: "cost", type: .number),
                DataColumn(name: "power", type: .number)
            ],
            rows: [
                ["name": .string("Item 1"), "cost": .number(10), "power": .number(5)]
            ]
        )
        project.dataTables.append(newTable)
        selectedTableId = id
    }

    public func addTableRow(to tableId: String) {
        guard let idx = project.dataTables.firstIndex(where: { $0.id == tableId }) else { return }
        var row: [String: VariableValue] = [:]
        for col in project.dataTables[idx].columns {
            switch col.type {
            case .string: row[col.name] = .string("New \(col.name)")
            case .number: row[col.name] = .number(1)
            case .boolean: row[col.name] = .boolean(true)
            }
        }
        project.dataTables[idx].rows.append(row)
    }

    // MARK: - Variable Operations

    public func addVariable(name: String, value: Double) {
        let v = GameVariable(name: name, initialValue: .number(value))
        project.globalVariables.append(v)
    }

    public func deleteVariable(name: String) {
        project.globalVariables.removeAll { $0.name == name }
    }

    // MARK: - Live Playtest

    public func startPlaytest() {
        consoleLogs.removeAll()
        let runtime = AstorkaGameRuntime(project: project)
        runtime.onPrintCLI = { [weak self] text, color in
            Task { @MainActor in
                self?.consoleLogs.append(text)
            }
        }
        if let scene = currentScene {
            runtime.loadScene(scene)
        }
        self.liveRuntime = runtime
        self.isPlaying = true
        self.activeTab = .playtest
    }

    public func stopPlaytest() {
        self.isPlaying = false
        self.liveRuntime = nil
    }

    public func handlePlaytestClick(elementId: String) {
        guard let runtime = liveRuntime else { return }
        runtime.inputManager.triggerHaptic(type: .generic)
        runtime.audioManager.playSound("click")
        let count = runtime.ruleEngine.dispatchTrigger(.onButtonClick(elementId: elementId))
        if count == 0 {
            // Check if there is a rule for this button whose condition failed
            if let rule = runtime.ruleEngine.activeRules.first(where: {
                if case .onButtonClick(let id) = $0.trigger { return id == elementId }
                return false
            }) {
                for cond in rule.conditions {
                    switch cond {
                    case .compareVariable(let v, let op, let val):
                        let cur = runtime.ruleEngine.getVariable(v).asString
                        consoleLogs.append("🔒 [Choice Locked]: Requires [\(v) \(op.rawValue) \(val)] (Current: \(v)=\(cur))")
                    default:
                        consoleLogs.append("🔒 [Choice Locked]: Condition not satisfied.")
                    }
                }
            }
        }
        // Force view re-render so live variables and terminal stats update immediately
        objectWillChange.send()
    }
}
