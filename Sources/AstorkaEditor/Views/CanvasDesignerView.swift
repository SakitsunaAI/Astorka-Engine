import SwiftUI
import AstorkaCore

public struct CanvasDesignerView: View {
    @ObservedObject var state: AppState

    public init(state: AppState) {
        self.state = state
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Toolbar
            componentToolbar

            // Visual Canvas Area
            GeometryReader { _ in
                ZStack {
                    // Dotted Cyber Background Grid
                    CanvasGridBackground()

                    // Scene Area (Game Resolution Bounds)
                    if let scene = state.currentScene {
                        ZStack {
                            // Scene Background
                            Color(
                                red: Double(scene.backgroundColor.r),
                                green: Double(scene.backgroundColor.g),
                                blue: Double(scene.backgroundColor.b)
                            )

                            // UI Elements
                            ForEach(scene.uiElements) { element in
                                CanvasElementView(
                                    element: element,
                                    isSelected: state.selectedElementId == element.id,
                                    onSelect: {
                                        state.selectedElementId = element.id
                                    },
                                    onDrag: { delta in
                                        var updated = element
                                        updated.x += delta.width
                                        updated.y += delta.height
                                        state.updateSelectedElement(updated)
                                    }
                                )
                            }
                        }
                        .frame(width: 960, height: 600)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AstorkaTheme.borderSubtle, lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.6), radius: 24, y: 12)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    state.selectedElementId = nil
                }
            }
        }
        .background(AstorkaTheme.bgDark)
    }

    // MARK: - Component Toolbar

    private var componentToolbar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "plus.square.fill")
                    .foregroundStyle(AstorkaTheme.cyanNeon)
                Text("ADD COMPONENT:")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.8))
            }

            componentButton(title: "Button", icon: "button.programmable", type: .button)
            componentButton(title: "Card", icon: "menucard", type: .cardView)
            componentButton(title: "Card Slot", icon: "square.dashed", type: .cardSlot)
            componentButton(title: "Text Label", icon: "textformat", type: .label)
            componentButton(title: "Gauge Bar", icon: "gauge.with.dots.needle.bottom.50percent", type: .gaugeBar)
            componentButton(title: "Panel", icon: "rectangle.portrait", type: .panel)
            componentButton(title: "Terminal", icon: "terminal", type: .cliWindow)

            Spacer()

            if state.selectedElement != nil {
                Button(role: .destructive) {
                    state.deleteSelectedElement()
                } label: {
                    Label("Delete Component", systemImage: "trash")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(AstorkaGlowButtonStyle(color: AstorkaTheme.redNeon))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(AstorkaTheme.surfaceDark)
        .overlay(Divider().background(AstorkaTheme.borderSubtle), alignment: .bottom)
    }

    private func componentButton(title: String, icon: String, type: UIElementType) -> some View {
        Button {
            state.addElement(type: type)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
        }
        .buttonStyle(AstorkaGlassButtonStyle())
    }
}

// MARK: - Element Visual Rendering

private struct CanvasElementView: View {
    let element: UIElement
    let isSelected: Bool
    let onSelect: () -> Void
    let onDrag: (CGSize) -> Void

    @GestureState private var dragOffset: CGSize = .zero

    var body: some View {
        Group {
            switch element.type {
            case .button:
                HStack(spacing: 6) {
                    if !element.icon.isEmpty {
                        Image(systemName: element.icon)
                    }
                    Text(element.text.isEmpty ? element.name : element.text)
                        .font(.system(size: CGFloat(element.style.fontSize), weight: .semibold))
                }
                .frame(width: CGFloat(element.width), height: CGFloat(element.height))
                .background(
                    RoundedRectangle(cornerRadius: CGFloat(element.style.cornerRadius))
                        .fill(AstorkaTheme.cyanNeon.opacity(0.85))
                )
                .foregroundColor(.black)
                .overlay(
                    RoundedRectangle(cornerRadius: CGFloat(element.style.cornerRadius))
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )

            case .cardView:
                VStack(spacing: 8) {
                    HStack {
                        Text("⚡ 3")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(AstorkaTheme.cyanNeon.opacity(0.2)))
                            .foregroundStyle(AstorkaTheme.cyanNeon)
                        Spacer()
                        Text("★ Rare")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(AstorkaTheme.amberNeon)
                    }
                    Spacer()
                    Image(systemName: "flame.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(AstorkaTheme.amberNeon)
                    Text(element.text.isEmpty ? "Sample Card" : element.text)
                        .font(.system(size: 13, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                    Spacer()
                    Text("+50 Damage / x2")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .frame(width: CGFloat(element.width), height: CGFloat(element.height))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AstorkaTheme.cardDark)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AstorkaTheme.amberNeon.opacity(0.6), lineWidth: 1.5)
                )

            case .cardSlot:
                VStack {
                    Image(systemName: "plus.square.dashed")
                        .font(.title2)
                        .foregroundStyle(AstorkaTheme.cyanNeon.opacity(0.6))
                    Text(element.text.isEmpty ? "Card Slot" : element.text)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .frame(width: CGFloat(element.width), height: CGFloat(element.height))
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                        .foregroundColor(AstorkaTheme.cyanNeon.opacity(0.4))
                )

            case .label:
                Text(element.text.isEmpty ? "Text Label" : element.text)
                    .font(.system(size: CGFloat(element.style.fontSize), weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: CGFloat(element.width), height: CGFloat(element.height), alignment: .leading)

            case .gaugeBar:
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.6))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [AstorkaTheme.emeraldNeon, AstorkaTheme.cyanNeon],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: CGFloat(element.width) * 0.75)
                    Text(element.text.isEmpty ? "HP: 75/100" : element.text)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.leading, 8)
                }
                .frame(width: CGFloat(element.width), height: CGFloat(element.height))

            case .panel:
                RoundedRectangle(cornerRadius: CGFloat(element.style.cornerRadius))
                    .fill(AstorkaTheme.cardDark.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: CGFloat(element.style.cornerRadius))
                            .stroke(AstorkaTheme.borderSubtle, lineWidth: 1)
                    )
                .frame(width: CGFloat(element.width), height: CGFloat(element.height))

            case .dialogueBox:
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(AstorkaTheme.purpleNeon.opacity(0.4))
                        .frame(width: 44, height: 44)
                        .overlay(Text("🧙‍♂️").font(.title3))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Wizard:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AstorkaTheme.amberNeon)
                        Text(element.text.isEmpty ? "Welcome to the dungeon. Stay alert!" : element.text)
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(12)
                .frame(width: CGFloat(element.width), height: CGFloat(element.height))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AstorkaTheme.cardDark)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AstorkaTheme.amberNeon.opacity(0.4), lineWidth: 1.5)
                )

            case .cliWindow:
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Circle().fill(Color.red).frame(width: 8, height: 8)
                        Circle().fill(Color.yellow).frame(width: 8, height: 8)
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                        Spacer()
                        Text("terminal")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    Divider().background(AstorkaTheme.borderSubtle)
                    Text("> Astorka CLI Runtime Ready.")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(AstorkaTheme.emeraldNeon)
                    Text("> Enter choice number [1] to trade.")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(8)
                .frame(width: CGFloat(element.width), height: CGFloat(element.height))
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.04, green: 0.05, blue: 0.07))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AstorkaTheme.cyanNeon.opacity(0.3), lineWidth: 1)
                )

            default:
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: CGFloat(element.width), height: CGFloat(element.height))
            }
        }
        .overlay(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: CGFloat(element.style.cornerRadius + 2))
                        .stroke(AstorkaTheme.cyanNeon, lineWidth: 2)
                        .shadow(color: AstorkaTheme.cyanNeon.opacity(0.5), radius: 8)
                        .padding(-4)
                }
            }
        )
        .offset(x: CGFloat(element.x) + dragOffset.width, y: CGFloat(element.y) + dragOffset.height)
        .onTapGesture {
            onSelect()
        }
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    onDrag(value.translation)
                }
        )
    }
}

// MARK: - Background Grid

private struct CanvasGridBackground: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 30
            var path = Path()

            for x in stride(from: 0, to: size.width, by: step) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }

            for y in stride(from: 0, to: size.height, by: step) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }

            context.stroke(path, with: .color(Color.white.opacity(0.04)), lineWidth: 1)
        }
    }
}
