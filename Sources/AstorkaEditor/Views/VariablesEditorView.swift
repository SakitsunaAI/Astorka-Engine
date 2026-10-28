import SwiftUI
import AstorkaCore

public struct VariablesEditorView: View {
    @ObservedObject var state: AppState

    @State private var newVarName: String = ""
    @State private var newVarValue: Double = 100
    @State private var newVarCategory: String = "Economy"
    @State private var searchQuery: String = ""
    @State private var selectedCategory: String = "All"

    private let categories = ["All", "Economy", "Stats", "Inventory", "Progression"]

    public init(state: AppState) {
        self.state = state
    }

    private var filteredVariables: [GameVariable] {
        state.project.globalVariables.filter { v in
            let matchesSearch = searchQuery.isEmpty || v.name.localizedCaseInsensitiveContains(searchQuery)
            let matchesCategory = (selectedCategory == "All") || (v.category.localizedCaseInsensitiveContains(selectedCategory))
            return matchesSearch && matchesCategory
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerBar

            // Category Filter & Search Bar
            filterBar

            // Variable Cards Grid / List
            ScrollView {
                VStack(spacing: 16) {
                    // Quick Preset Chips
                    presetChipsSection

                    // Variable Cards
                    if filteredVariables.isEmpty {
                        emptyVariablesState
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredVariables) { v in
                                variableCard(v)
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
        .background(AstorkaTheme.bgDark)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Image(systemName: "gauge.with.needle.fill")
                        .foregroundStyle(AstorkaTheme.cyanNeon)
                    Text("GAME STATE & VARIABLE REGISTRY")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("\(state.project.globalVariables.count) ACTIVE")
                        .astorkaBadge(color: AstorkaTheme.cyanNeon)
                }
                Text("Manage economic balances, character stats, inventory counts, and progression flags without code.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Quick Creator Form
            HStack(spacing: 8) {
                TextField("Variable Name (e.g. gold)", text: $newVarName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(AstorkaTheme.cardDark)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AstorkaTheme.borderSubtle, lineWidth: 1))
                    .frame(width: 170)

                TextField("Value", value: $newVarValue, format: .number)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(AstorkaTheme.cardDark)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AstorkaTheme.borderSubtle, lineWidth: 1))
                    .frame(width: 80)

                Button {
                    guard !newVarName.isEmpty else { return }
                    state.addVariable(name: newVarName, value: newVarValue)
                    newVarName = ""
                } label: {
                    Label("Add Variable", systemImage: "plus")
                        .font(.system(size: 12, weight: .bold))
                }
                .buttonStyle(AstorkaGlowButtonStyle(color: AstorkaTheme.cyanNeon))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(AstorkaTheme.surfaceDark)
        .overlay(Divider().background(AstorkaTheme.borderSubtle), alignment: .bottom)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 12) {
            // Search Field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Search variable name...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AstorkaTheme.cardDark)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(AstorkaTheme.borderSubtle, lineWidth: 1))
            .frame(width: 240)

            // Category Pills
            HStack(spacing: 6) {
                ForEach(categories, id: \.self) { cat in
                    let isSelected = selectedCategory == cat
                    Button {
                        selectedCategory = cat
                    } label: {
                        Text(cat)
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(isSelected ? AstorkaTheme.cyanNeon.opacity(0.18) : Color.white.opacity(0.04))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? AstorkaTheme.cyanNeon : AstorkaTheme.borderSubtle, lineWidth: 1)
                            )
                            .foregroundStyle(isSelected ? AstorkaTheme.cyanNeon : Color.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(AstorkaTheme.panelHeader)
        .overlay(Divider().background(AstorkaTheme.borderSubtle), alignment: .bottom)
    }

    // MARK: - Preset Chips

    private var presetChipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundStyle(AstorkaTheme.amberNeon)
                Text("QUICK ECONOMY & RPG PRESETS (CLICK TO INSTANTLY ADD):")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(AstorkaTheme.amberNeon)
            }

            HStack(spacing: 8) {
                presetButton(name: "gold", val: 500, label: "💰 Gold ($500)")
                presetButton(name: "energy", val: 100, label: "⚡ Energy (100)")
                presetButton(name: "raw_materials", val: 25, label: "📦 Raw Materials (25)")
                presetButton(name: "level", val: 1, label: "⭐ Level (1)")
                presetButton(name: "reputation", val: 50, label: "🏛️ Reputation (50)")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AstorkaTheme.cardDark.opacity(0.6))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AstorkaTheme.borderSubtle, lineWidth: 1))
        )
    }

    private func presetButton(name: String, val: Double, label: String) -> some View {
        Button {
            state.addVariable(name: name, value: val)
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AstorkaTheme.borderSubtle, lineWidth: 1))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Variable Card

    private func variableCard(_ v: GameVariable) -> some View {
        HStack(spacing: 16) {
            // Icon & Name
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AstorkaTheme.cyanNeon.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AstorkaTheme.cyanNeon)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text("$\(v.name)")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)

                        Text(v.category)
                            .astorkaBadge(color: AstorkaTheme.purpleNeon)
                    }

                    Text("Used in conditions & formula calculations")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Value Display
            HStack(spacing: 8) {
                Text("Default:")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Text(v.initialValue.asString)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AstorkaTheme.emeraldNeon.opacity(0.15))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(AstorkaTheme.emeraldNeon.opacity(0.4), lineWidth: 1))
                    )
                    .foregroundStyle(AstorkaTheme.emeraldNeon)
            }

            // Quick Tweakers
            HStack(spacing: 4) {
                quickAdjustButton(name: v.name, current: v.initialValue.asNumber, delta: -10, label: "-10")
                quickAdjustButton(name: v.name, current: v.initialValue.asNumber, delta: +10, label: "+10")
                quickAdjustButton(name: v.name, current: v.initialValue.asNumber, delta: +100, label: "+100")
            }

            // Delete Button
            Button(role: .destructive) {
                state.deleteVariable(name: v.name)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundStyle(AstorkaTheme.redNeon.opacity(0.8))
                    .padding(8)
                    .background(Circle().fill(Color.white.opacity(0.04)))
            }
            .buttonStyle(.plain)
            .help("Delete variable")
        }
        .padding(16)
        .astorkaCard(isHovered: false, cornerRadius: 10)
    }

    private func quickAdjustButton(name: String, current: Double, delta: Double, label: String) -> some View {
        Button {
            let updated = current + delta
            if let idx = state.project.globalVariables.firstIndex(where: { $0.name == name }) {
                state.project.globalVariables[idx].initialValue = .number(updated)
            }
        } label: {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(AstorkaTheme.borderSubtle, lineWidth: 1))
                .foregroundStyle(Color.white.opacity(0.8))
        }
        .buttonStyle(.plain)
    }

    private var emptyVariablesState: some View {
        VStack(spacing: 12) {
            Image(systemName: "gauge.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(AstorkaTheme.cyanNeon.opacity(0.5))
            Text("No Variables Match Your Filter")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
            Text("Create custom parameters above or click any preset to begin.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
