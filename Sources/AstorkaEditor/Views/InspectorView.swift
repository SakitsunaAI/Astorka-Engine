import SwiftUI
import AstorkaCore

public struct InspectorView: View {
    @ObservedObject var state: AppState

    public init(state: AppState) {
        self.state = state
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .font(.caption)
                    .foregroundStyle(AstorkaTheme.cyanNeon)
                Text(state.selectedElement != nil ? "PROPERTIES INSPECTOR" : "SCENE & PROJECT SETTINGS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.8))
                Spacer()
            }
            .padding(14)
            .background(AstorkaTheme.panelHeader)
            .overlay(Divider().background(AstorkaTheme.borderSubtle), alignment: .bottom)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let element = state.selectedElement {
                        elementInspector(element)
                    } else {
                        sceneAndProjectInspector()
                    }
                }
                .padding(16)
            }
        }
        .frame(minWidth: 260, maxWidth: 300)
        .background(AstorkaTheme.surfaceDark)
        .overlay(Divider().background(AstorkaTheme.borderSubtle), alignment: .leading)
    }

    @ViewBuilder
    private func elementInspector(_ element: UIElement) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Component Info
            VStack(alignment: .leading, spacing: 8) {
                Text("COMPONENT INFO")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(AstorkaTheme.cyanNeon)

                TextField("Name", text: binding(for: \.name))
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(8)
                    .background(AstorkaTheme.cardDark)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AstorkaTheme.borderSubtle, lineWidth: 1))

                HStack {
                    Text("Type:")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(element.type.rawValue.uppercased())
                        .astorkaBadge(color: AstorkaTheme.purpleNeon)
                }
            }

            Divider().background(AstorkaTheme.borderSubtle)

            // Position & Size
            VStack(alignment: .leading, spacing: 8) {
                Text("GEOMETRY & POSITION")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(AstorkaTheme.cyanNeon)

                HStack(spacing: 8) {
                    numberInput(label: "X", value: binding(for: \.x))
                    numberInput(label: "Y", value: binding(for: \.y))
                }

                HStack(spacing: 8) {
                    numberInput(label: "W", value: binding(for: \.width))
                    numberInput(label: "H", value: binding(for: \.height))
                }
            }

            Divider().background(AstorkaTheme.borderSubtle)

            // Content & Text
            VStack(alignment: .leading, spacing: 8) {
                Text("TEXT CONTENT")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(AstorkaTheme.cyanNeon)

                TextField("Visible Text", text: binding(for: \.text))
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(8)
                    .background(AstorkaTheme.cardDark)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AstorkaTheme.borderSubtle, lineWidth: 1))

                Text("Variable Binding:")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)

                Picker("Variable", selection: bindingOptional(for: \.bindingVariable)) {
                    Text("(None)").tag(String?.none)
                    ForEach(state.project.globalVariables) { v in
                        Text("$\(v.name)").tag(String?.some(v.name))
                    }
                }
                .pickerStyle(.menu)
            }

            Divider().background(AstorkaTheme.borderSubtle)

            // Style
            VStack(alignment: .leading, spacing: 8) {
                Text("APPEARANCE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(AstorkaTheme.cyanNeon)

                HStack {
                    Text("Font Size:")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField("Size", value: bindingStyle(for: \.fontSize), format: .number)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(6)
                        .background(AstorkaTheme.cardDark)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .frame(width: 60)
                }

                HStack {
                    Text("Corner Radius:")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField("Radius", value: bindingStyle(for: \.cornerRadius), format: .number)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(6)
                        .background(AstorkaTheme.cardDark)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .frame(width: 60)
                }
            }
        }
    }

    private func numberInput(label: String, value: Binding<Double>) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
            TextField(label, value: value, format: .number)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .padding(6)
                .background(AstorkaTheme.cardDark)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AstorkaTheme.borderSubtle, lineWidth: 1))
        }
    }

    @ViewBuilder
    private func sceneAndProjectInspector() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("PROJECT DETAILS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(AstorkaTheme.cyanNeon)

                TextField("Project Title", text: $state.project.title)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(8)
                    .background(AstorkaTheme.cardDark)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AstorkaTheme.borderSubtle, lineWidth: 1))

                TextField("Author", text: $state.project.author)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(8)
                    .background(AstorkaTheme.cardDark)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AstorkaTheme.borderSubtle, lineWidth: 1))

                HStack {
                    Text("Refresh Rate:")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("120 FPS ProMotion")
                        .astorkaBadge(color: AstorkaTheme.emeraldNeon)
                }
            }

            Divider().background(AstorkaTheme.borderSubtle)

            if let scene = state.currentScene {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ACTIVE SCENE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(AstorkaTheme.cyanNeon)

                    HStack {
                        Text("Name:")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(scene.name)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    HStack {
                        Text("Type:")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(scene.type.rawValue.uppercased())
                            .astorkaBadge(color: AstorkaTheme.amberNeon)
                    }

                    HStack {
                        Text("Elements:")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(scene.uiElements.count)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(AstorkaTheme.cyanNeon)
                    }

                    HStack {
                        Text("Choices:")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(scene.uiElements.filter { $0.type == .button }.count)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(AstorkaTheme.emeraldNeon)
                    }
                }
            }
        }
    }

    // MARK: - Bindings

    private func binding<T>(for keyPath: WritableKeyPath<UIElement, T>) -> Binding<T> {
        Binding(
            get: {
                guard let el = state.selectedElement else { fatalError() }
                return el[keyPath: keyPath]
            },
            set: { newVal in
                guard var el = state.selectedElement else { return }
                el[keyPath: keyPath] = newVal
                state.updateSelectedElement(el)
            }
        )
    }

    private func bindingOptional(for keyPath: WritableKeyPath<UIElement, String?>) -> Binding<String?> {
        Binding(
            get: {
                guard let el = state.selectedElement else { return nil }
                return el[keyPath: keyPath]
            },
            set: { newVal in
                guard var el = state.selectedElement else { return }
                el[keyPath: keyPath] = newVal
                state.updateSelectedElement(el)
            }
        )
    }

    private func bindingStyle<T>(for keyPath: WritableKeyPath<UIStyle, T>) -> Binding<T> {
        Binding(
            get: {
                guard let el = state.selectedElement else { fatalError() }
                return el.style[keyPath: keyPath]
            },
            set: { newVal in
                guard var el = state.selectedElement else { return }
                el.style[keyPath: keyPath] = newVal
                state.updateSelectedElement(el)
            }
        )
    }
}
