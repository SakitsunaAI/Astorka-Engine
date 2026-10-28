import SwiftUI
import AstorkaCore

public struct MainEditorView: View {
    @StateObject private var state = AppState()
    @State private var showingExportAlert: Bool = false
    @State private var exportMessage: String = ""

    public init() {}

    public var body: some View {
        Group {
            switch state.currentScreen {
            case .hub:
                ProjectHubView(state: state)
            case .editor:
                editorBody
            }
        }
    }

    private var editorBody: some View {
        VStack(spacing: 0) {
            NavigationSplitView {
                // Left Sidebar: Scenes & Management
                SidebarView(state: state)
                    .background(AstorkaTheme.surfaceDark)
            } detail: {
                HSplitView {
                    // Center: Active Tab
                    VStack(spacing: 0) {
                        switch state.activeTab {
                        case .choices:
                            ChoicesEditorView(state: state)
                        case .canvas:
                            CanvasDesignerView(state: state)
                        case .tables:
                            DataTablesEditorView(state: state)
                        case .variables:
                            VariablesEditorView(state: state)
                        case .playtest:
                            LivePlaytestView(state: state)
                        }
                    }
                    .frame(minWidth: 640, maxWidth: .infinity, maxHeight: .infinity)
                    .background(AstorkaTheme.bgDark)

                    // Right: Properties Inspector (Hidden during Playtest)
                    if state.activeTab != .playtest {
                        InspectorView(state: state)
                            .background(AstorkaTheme.surfaceDark)
                    }
                }
            }

            // Bottom Engine Studio Status Bar
            studioStatusBar
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 12) {
                    Button {
                        state.returnToHub()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "house.fill")
                                .foregroundStyle(AstorkaTheme.cyanNeon)
                            Text("Main Menu")
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .buttonStyle(AstorkaGlassButtonStyle())
                    .help("Return to Project Hub (Auto-saves)")

                    Rectangle().fill(AstorkaTheme.borderSubtle).frame(width: 1, height: 18)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.project.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                        HStack(spacing: 6) {
                            Text(state.project.type == .cli ? "CLI GAME ENGINE" : "UI GAME ENGINE")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(AstorkaTheme.cyanNeon)
                            Text("•")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("NO-CODE")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(AstorkaTheme.emeraldNeon)
                        }
                    }
                }
            }

            ToolbarItem(placement: .principal) {
                Picker("Tab", selection: $state.activeTab) {
                    ForEach(state.availableTabs) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(minWidth: 320)
            }

            ToolbarItemGroup(placement: .primaryAction) {
                // Play / Stop Engine
                Button {
                    if state.isPlaying {
                        state.stopPlaytest()
                        state.activeTab = (state.project.type == .cli) ? .choices : .canvas
                    } else {
                        state.startPlaytest()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: state.isPlaying ? "stop.fill" : "play.fill")
                        Text(state.isPlaying ? "STOP" : "PLAY GAME")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                }
                .buttonStyle(AstorkaGlowButtonStyle(color: state.isPlaying ? AstorkaTheme.redNeon : AstorkaTheme.emeraldNeon))

                if state.project.type == .cli {
                    Button {
                        launchInNativeTerminal()
                    } label: {
                        Label("Terminal", systemImage: "terminal.fill")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(AstorkaGlassButtonStyle())
                    .help("Launch in macOS Terminal app")
                }

                Button {
                    exportStandaloneApp()
                } label: {
                    Label("Export .app", systemImage: "shippingbox.fill")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(AstorkaGlassButtonStyle())
                .help("Build standalone macOS application bundle")

                Button {
                    saveProject()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(AstorkaGlowButtonStyle(color: AstorkaTheme.cyanNeon))
                .help("Save project file")
            }
        }
        .alert("Astorka Engine", isPresented: $showingExportAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportMessage)
        }
    }

    // MARK: - Bottom Studio Status Bar

    private var studioStatusBar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Circle().fill(AstorkaTheme.emeraldNeon).frame(width: 8, height: 8)
                Text("ENGINE ONLINE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(AstorkaTheme.emeraldNeon)
            }

            Text("•")
                .foregroundStyle(Color.secondary)

            HStack(spacing: 4) {
                Text("Scene:")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text(state.currentScene?.name ?? "Main Scene")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
            }

            Text("•")
                .foregroundStyle(Color.secondary)

            HStack(spacing: 4) {
                Text("Variables:")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text("\(state.project.globalVariables.count)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(AstorkaTheme.cyanNeon)
            }

            Text("•")
                .foregroundStyle(Color.secondary)

            HStack(spacing: 4) {
                Text("Choices:")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text("\(state.currentScene?.uiElements.filter { $0.type == .button }.count ?? 0)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(AstorkaTheme.amberNeon)
            }

            Spacer()

            HStack(spacing: 10) {
                Text("Metal Core • 120Hz ProMotion")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(AstorkaTheme.emeraldNeon)
                    Text("Auto-Saved")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(AstorkaTheme.panelHeader)
        .overlay(Divider().background(AstorkaTheme.borderSubtle), alignment: .top)
    }

    private func launchInNativeTerminal() {
        state.saveCurrentProject()
        let cwd = FileManager.default.currentDirectoryPath
        let projectPath = state.currentProjectURL?.path ?? "AstorkaProject.json"
        let script = "cd '\(cwd)' && swift run astorka-cli '\(projectPath)'"
        let escapedScript = script.replacingOccurrences(of: "\"", with: "\\\"")
        let appleScript = "tell application \"Terminal\" to do script \"\(escapedScript)\""

        var error: NSDictionary?
        if let scriptObj = NSAppleScript(source: appleScript) {
            scriptObj.executeAndReturnError(&error)
        }
    }

    private func saveProject() {
        state.saveCurrentProject()
        let filename = state.currentProjectURL?.lastPathComponent ?? "\(state.project.title).astorkaproject"
        exportMessage = "✅ Project saved successfully to '\(filename)'!"
        showingExportAlert = true
    }

    private func exportStandaloneApp() {
        saveProject()
        let gameName = state.project.title.replacingOccurrences(of: " ", with: "")
        let script = "./scripts/export_app.sh \"\(gameName)\" \"AstorkaProject.json\""

        DispatchQueue.global().async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", script]
            try? process.run()
            process.waitUntilExit()

            DispatchQueue.main.async {
                self.exportMessage = "🎉 Success! Standalone macOS application '\(gameName).app' created! Double click to play."
                self.showingExportAlert = true
            }
        }
    }
}

// MARK: - Left Sidebar

private struct SidebarView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Sidebar Header
            HStack {
                Text("SCENES & SCREENS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.8))
                Spacer()
                Button {
                    let newId = "scene_\(UUID().uuidString.prefix(6))"
                    let newName = state.project.type == .cli ? "Terminal \(state.project.scenes.count + 1)" : "Screen \(state.project.scenes.count + 1)"
                    let newScene = GameScene(
                        id: newId,
                        name: newName,
                        type: state.project.type == .cli ? .cliTerminal : .uiCanvas
                    )
                    state.project.scenes.append(newScene)
                    state.selectedSceneId = newId
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AstorkaTheme.cyanNeon)
                }
                .buttonStyle(.plain)
                .help("Add new screen")
            }
            .padding(14)
            .background(AstorkaTheme.panelHeader)
            .overlay(Divider().background(AstorkaTheme.borderSubtle), alignment: .bottom)

            // Scene List
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(state.project.scenes) { scene in
                        let isSelected = state.selectedSceneId == scene.id
                        Button {
                            state.selectedSceneId = scene.id
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: state.project.type == .cli ? "terminal.fill" : "macwindow")
                                    .foregroundStyle(isSelected ? AstorkaTheme.cyanNeon : Color.secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(scene.name)
                                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                        .foregroundStyle(isSelected ? .white : Color.white.opacity(0.85))

                                    Text("\(scene.uiElements.count) choices / elements")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if isSelected {
                                    Circle()
                                        .fill(AstorkaTheme.cyanNeon)
                                        .frame(width: 6, height: 6)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelected ? AstorkaTheme.cardDarkHover : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? AstorkaTheme.borderCyanGlow : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
            }

            Spacer()

            // Quick Project Switcher in Sidebar footer
            VStack(alignment: .leading, spacing: 8) {
                Divider().background(AstorkaTheme.borderSubtle)
                HStack {
                    Image(systemName: "folder.badge.gearshape")
                        .foregroundStyle(AstorkaTheme.purpleNeon)
                    Text("GAME ENGINE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.secondary)
                }
                Text("All changes are automatically synced to your game project file.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(AstorkaTheme.panelHeader)
        }
        .frame(minWidth: 220, maxWidth: 260)
        .background(AstorkaTheme.surfaceDark)
        .overlay(Divider().background(AstorkaTheme.borderSubtle), alignment: .trailing)
    }
}
