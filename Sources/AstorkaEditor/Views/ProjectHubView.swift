import SwiftUI
import AppKit
import AstorkaCore

public struct ProjectHubView: View {
    @ObservedObject var state: AppState

    @State private var showingCreateSheet: Bool = false
    @State private var newProjectTitle: String = ""
    @State private var newProjectType: ProjectType = .cli
    @State private var projectToDelete: SavedProjectItem? = nil
    @State private var showingDeleteAlert: Bool = false
    @State private var searchText: String = ""
    @State private var selectedFilter: ProjectFilter = .all
    @State private var hoveredCardId: String? = nil

    public init(state: AppState) {
        self.state = state
    }

    public enum ProjectFilter: String, CaseIterable, Identifiable {
        case all = "All Games"
        case cli = "CLI Games"
        case ui = "UI Games"
        public var id: String { rawValue }
    }

    private var filteredProjects: [SavedProjectItem] {
        state.savedProjects.filter { item in
            let matchesFilter: Bool
            switch selectedFilter {
            case .all: matchesFilter = true
            case .cli: matchesFilter = item.type == .cli
            case .ui: matchesFilter = item.type == .ui || item.type == .world2D
            }
            if !matchesFilter { return false }
            if searchText.trimmingCharacters(in: .whitespaces).isEmpty { return true }
            return item.title.localizedCaseInsensitiveContains(searchText) ||
                   item.url.lastPathComponent.localizedCaseInsensitiveContains(searchText)
        }
    }

    private let columns = [
        GridItem(.adaptive(minimum: 360, maximum: 460), spacing: 24)
    ]

    public var body: some View {
        ZStack {
            AstorkaTheme.bgDark.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Hero Header
                heroHeaderBar

                // MARK: - Search & Filters Bar
                controlsBar

                // MARK: - Projects Grid Area
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if filteredProjects.isEmpty {
                            emptyStateView
                        } else {
                            LazyVGrid(columns: columns, spacing: 24) {
                                ForEach(filteredProjects) { item in
                                    projectCard(item: item)
                                }
                            }
                            .padding(.horizontal, 36)
                            .padding(.top, 24)
                            .padding(.bottom, 48)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            createProjectSheet
        }
        .alert("Delete Project", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let item = projectToDelete {
                    state.deleteProject(item: item)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to permanently delete '\(projectToDelete?.title ?? "")'? This cannot be undone.")
        }
        .onAppear {
            state.loadSavedProjects()
        }
    }

    // MARK: - Hero Header Bar

    private var heroHeaderBar: some View {
        HStack(spacing: 24) {
            // Glowing Logo Emblem
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.0, green: 0.9, blue: 1.0), Color(red: 0.65, green: 0.25, blue: 1.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .shadow(color: AstorkaTheme.cyanNeon.opacity(0.4), radius: 16)

                Image(systemName: "terminal.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 10) {
                    Text("ASTORKA ENGINE")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(white: 0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("NO-CODE STUDIO")
                        .astorkaBadge(color: AstorkaTheme.cyanNeon)

                    Text("METAL 120Hz")
                        .astorkaBadge(color: AstorkaTheme.emeraldNeon)
                }

                Text("Native macOS engine for building formula-driven CLI and UI games without code.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.65))
            }

            Spacer()

            // Header Action Buttons
            HStack(spacing: 12) {
                Button {
                    openExternalProjectDialog()
                } label: {
                    Label("Import .astorkaproject", systemImage: "folder")
                }
                .buttonStyle(AstorkaGlassButtonStyle())

                Button {
                    newProjectTitle = ""
                    newProjectType = .cli
                    showingCreateSheet = true
                } label: {
                    Label("Create New Project", systemImage: "plus.circle.fill")
                }
                .buttonStyle(AstorkaGlowButtonStyle(color: AstorkaTheme.cyanNeon))
            }
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 22)
        .background(AstorkaTheme.surfaceDark)
        .overlay(Divider().background(AstorkaTheme.borderSubtle), alignment: .bottom)
    }

    // MARK: - Controls Bar (Filter, Search, Quick Stats)

    private var controlsBar: some View {
        HStack(spacing: 16) {
            // Filter Pills
            HStack(spacing: 8) {
                ForEach(ProjectFilter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 12, weight: selectedFilter == filter ? .bold : .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(selectedFilter == filter ? AstorkaTheme.cyanNeon.opacity(0.2) : Color.white.opacity(0.04))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(selectedFilter == filter ? AstorkaTheme.cyanNeon : AstorkaTheme.borderSubtle, lineWidth: 1)
                            )
                            .foregroundColor(selectedFilter == filter ? AstorkaTheme.cyanNeon : .white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search projects...", text: $searchText)
                    .textFieldStyle(.plain)
                    .frame(width: 220)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AstorkaTheme.borderSubtle, lineWidth: 1))

            // Refresh Button
            Button {
                state.loadSavedProjects()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13))
            }
            .buttonStyle(AstorkaGlassButtonStyle())
            .help("Scan directory for changes")

            // Show in Finder
            Button {
                NSWorkspace.shared.open(AppState.projectsDirectoryURL)
            } label: {
                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 13))
            }
            .buttonStyle(AstorkaGlassButtonStyle())
            .help("Reveal ~/Documents/AstorkaProjects in Finder")
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 14)
        .background(AstorkaTheme.panelHeader)
        .overlay(Divider().background(AstorkaTheme.borderSubtle), alignment: .bottom)
    }

    // MARK: - Project Card

    private func projectCard(item: SavedProjectItem) -> some View {
        let isHovered = hoveredCardId == item.id

        return VStack(alignment: .leading, spacing: 16) {
            // Card Header
            HStack(alignment: .top) {
                // Project Icon with Glow
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            item.type == .cli
                                ? LinearGradient(colors: [Color.green.opacity(0.25), Color.cyan.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.purple.opacity(0.25), Color.blue.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(item.type == .cli ? AstorkaTheme.emeraldNeon.opacity(0.4) : AstorkaTheme.purpleNeon.opacity(0.4), lineWidth: 1)
                        )

                    Image(systemName: item.type == .cli ? "terminal.fill" : "macwindow.on.rectangle")
                        .font(.system(size: 22))
                        .foregroundStyle(item.type == .cli ? AstorkaTheme.emeraldNeon : AstorkaTheme.cyanNeon)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(item.type == .cli ? "CLI TERMINAL GAME" : "UI GAME")
                            .astorkaBadge(color: item.type == .cli ? AstorkaTheme.emeraldNeon : AstorkaTheme.purpleNeon)

                        Text("•")
                            .foregroundStyle(.secondary)

                        Text(formatDate(item.modifiedDate))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Delete Button
                Button(role: .destructive) {
                    projectToDelete = item
                    showingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
                .padding(6)
                .background(Circle().fill(Color.white.opacity(0.05)))
                .help("Delete Project")
            }

            // File path indicator pill
            HStack(spacing: 6) {
                Image(systemName: "doc.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(item.url.lastPathComponent)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.04)))

            Divider().background(AstorkaTheme.borderSubtle)

            // Bottom Actions
            HStack(spacing: 12) {
                Button {
                    state.openProject(item: item)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Open In Editor")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(AstorkaGlowButtonStyle(color: AstorkaTheme.cyanNeon))

                if item.type == .cli {
                    Button {
                        launchTerminalDirectly(item: item)
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(AstorkaGlassButtonStyle())
                    .help("Launch directly in native macOS Terminal.app")
                }
            }
        }
        .padding(20)
        .astorkaCard(isHovered: isHovered, cornerRadius: 16)
        .onHover { h in
            hoveredCardId = h ? item.id : nil
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)

            ZStack {
                Circle()
                    .fill(AstorkaTheme.cyanNeon.opacity(0.08))
                    .frame(width: 120, height: 120)

                Image(systemName: "sparkles")
                    .font(.system(size: 52))
                    .foregroundStyle(AstorkaTheme.cyberGradient)
            }

            Text("No Games Found")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            Text("Create your first no-code project to begin crafting choices, formulas, and visual scenes.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 440)

            Button {
                newProjectTitle = ""
                newProjectType = .cli
                showingCreateSheet = true
            } label: {
                Label("Create Your First Project", systemImage: "plus")
            }
            .buttonStyle(AstorkaGlowButtonStyle(color: AstorkaTheme.cyanNeon))
            .padding(.top, 8)

            Spacer().frame(height: 60)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Create Project Sheet

    private var createProjectSheet: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CREATE NEW PROJECT")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("Select your game architecture. Saved as a .astorkaproject file.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    showingCreateSheet = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider().background(AstorkaTheme.borderSubtle)

            // Game Type Selector Cards
            HStack(spacing: 16) {
                // CLI Game Card
                Button {
                    newProjectType = .cli
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.green.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "terminal.fill")
                                    .font(.title3)
                                    .foregroundColor(AstorkaTheme.emeraldNeon)
                            }
                            Spacer()
                            if newProjectType == .cli {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AstorkaTheme.emeraldNeon)
                            }
                        }

                        Text("CLI / Terminal Game")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("Pure text & terminal game. Driven entirely by choices, mathematical formulas, economy stats, and turn-based simulation.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(4)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(newProjectType == .cli ? AstorkaTheme.emeraldNeon.opacity(0.12) : AstorkaTheme.cardDark)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(newProjectType == .cli ? AstorkaTheme.emeraldNeon : AstorkaTheme.borderSubtle, lineWidth: newProjectType == .cli ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)

                // UI Game Card
                Button {
                    newProjectType = .ui
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.purple.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "macwindow.on.rectangle")
                                    .font(.title3)
                                    .foregroundColor(AstorkaTheme.purpleNeon)
                            }
                            Spacer()
                            if newProjectType == .ui {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AstorkaTheme.purpleNeon)
                            }
                        }

                        Text("UI Game / Canvas")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("Visual cards, gauges, dialogue boxes, panels, and interactive buttons powered by 120Hz Metal rendering.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(4)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(newProjectType == .ui ? AstorkaTheme.purpleNeon.opacity(0.12) : AstorkaTheme.cardDark)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(newProjectType == .ui ? AstorkaTheme.purpleNeon : AstorkaTheme.borderSubtle, lineWidth: newProjectType == .ui ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
            }

            // Project Title Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Project Title")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                TextField("e.g., Cyberpunk Trader, Dungeon RPG, Space Tycoon", text: $newProjectTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AstorkaTheme.borderHighlight, lineWidth: 1))

                // Presets
                HStack(spacing: 8) {
                    Text("Suggestions:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    ForEach(["Cyber Trader", "Dungeon Crawler", "Factory Tycoon"], id: \.self) { preset in
                        Button {
                            newProjectTitle = preset
                        } label: {
                            Text(preset)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.white.opacity(0.08)))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer().frame(height: 10)

            // Modal Footer Buttons
            HStack(spacing: 14) {
                Button("Cancel") {
                    showingCreateSheet = false
                }
                .buttonStyle(AstorkaGlassButtonStyle())

                Spacer()

                Button {
                    let title = newProjectTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    state.createAndOpenProject(
                        title: title.isEmpty ? "New Project" : title,
                        type: newProjectType
                    )
                    showingCreateSheet = false
                } label: {
                    Label("Create & Open Editor", systemImage: "arrow.right.circle.fill")
                }
                .buttonStyle(AstorkaGlowButtonStyle(color: newProjectType == .cli ? AstorkaTheme.emeraldNeon : AstorkaTheme.cyanNeon))
            }
        }
        .padding(28)
        .frame(width: 580)
        .background(AstorkaTheme.surfaceDark)
    }

    // MARK: - Helpers

    private func openExternalProjectDialog() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = []

        if panel.runModal() == .OK, let url = panel.url {
            let item = SavedProjectItem(
                title: url.deletingPathExtension().lastPathComponent,
                type: .cli,
                modifiedDate: Date(),
                url: url
            )
            state.openProject(item: item)
        }
    }

    private func launchTerminalDirectly(item: SavedProjectItem) {
        let cwd = FileManager.default.currentDirectoryPath
        let script = "cd '\(cwd)' && swift run astorka-cli '\(item.url.path)'"
        let escaped = script.replacingOccurrences(of: "\"", with: "\\\"")
        let appleScript = "tell application \"Terminal\" to do script \"\(escaped)\""
        var error: NSDictionary?
        if let scriptObj = NSAppleScript(source: appleScript) {
            scriptObj.executeAndReturnError(&error)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
