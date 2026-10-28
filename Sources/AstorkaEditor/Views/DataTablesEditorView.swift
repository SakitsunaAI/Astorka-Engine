import SwiftUI
import AstorkaCore

public struct DataTablesEditorView: View {
    @ObservedObject var state: AppState

    @State private var hoveredRowIdx: Int? = nil

    public init(state: AppState) {
        self.state = state
    }

    public var body: some View {
        HSplitView {
            // Left: Tables List
            leftSidebar

            // Right: Selected Table Spreadsheet
            tableSpreadsheetView
        }
        .background(AstorkaTheme.bgDark)
    }

    // MARK: - Left Sidebar

    private var leftSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "tablecells.fill")
                        .foregroundStyle(AstorkaTheme.cyanNeon)
                    Text("DATA TABLES")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.8))
                }

                Spacer()

                Button {
                    state.addDataTable()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AstorkaTheme.cyanNeon)
                }
                .buttonStyle(.plain)
                .help("Add new data table")
            }
            .padding(14)
            .background(AstorkaTheme.panelHeader)
            .overlay(Divider().background(AstorkaTheme.borderSubtle), alignment: .bottom)

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(state.project.dataTables) { table in
                        let isSelected = state.selectedTableId == table.id
                        Button {
                            state.selectedTableId = table.id
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "tablecells")
                                    .foregroundStyle(isSelected ? AstorkaTheme.cyanNeon : Color.secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(table.name)
                                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                        .foregroundStyle(isSelected ? .white : Color.white.opacity(0.8))

                                    Text("\(table.rows.count) rows • \(table.columns.count) columns")
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
        }
        .frame(minWidth: 220, maxWidth: 280)
        .background(AstorkaTheme.surfaceDark)
        .overlay(Divider().background(AstorkaTheme.borderSubtle), alignment: .trailing)
    }

    // MARK: - Spreadsheet View

    @ViewBuilder
    private var tableSpreadsheetView: some View {
        if let tableId = state.selectedTableId,
           let table = state.project.dataTables.first(where: { $0.id == tableId }) {
            VStack(spacing: 0) {
                // Table Header Bar
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(table.name)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)

                            Text("SPREADSHEET REGISTRY")
                                .astorkaBadge(color: AstorkaTheme.purpleNeon)
                        }

                        Text("Use for items, quests, dialogue pools, enemy stats, or merchant trade goods.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        state.addTableRow(to: table.id)
                    } label: {
                        Label("Add Row", systemImage: "plus.rectangle.fill")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .buttonStyle(AstorkaGlowButtonStyle(color: AstorkaTheme.cyanNeon))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(AstorkaTheme.surfaceDark)
                .overlay(Divider().background(AstorkaTheme.borderSubtle), alignment: .bottom)

                // Table Grid
                ScrollView([.horizontal, .vertical]) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header Row
                        HStack(spacing: 0) {
                            Text("#")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(AstorkaTheme.cyanNeon)
                                .frame(width: 50, alignment: .center)
                                .padding(.vertical, 10)
                                .background(AstorkaTheme.panelHeader)

                            ForEach(table.columns) { col in
                                Rectangle().fill(AstorkaTheme.borderSubtle).frame(width: 1)
                                HStack(spacing: 6) {
                                    Text(col.name.uppercased())
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text(col.type.rawValue)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(AstorkaTheme.amberNeon)
                                }
                                .frame(width: 170, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(AstorkaTheme.panelHeader)
                            }
                        }
                        .overlay(Rectangle().stroke(AstorkaTheme.borderSubtle, lineWidth: 1))

                        // Data Rows
                        ForEach(table.rows.indices, id: \.self) { rowIdx in
                            let isHovered = hoveredRowIdx == rowIdx
                            HStack(spacing: 0) {
                                Text("\(rowIdx + 1)")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(Color.secondary)
                                    .frame(width: 50, alignment: .center)
                                    .padding(.vertical, 10)

                                ForEach(table.columns) { col in
                                    Rectangle().fill(AstorkaTheme.borderSubtle).frame(width: 1)
                                    let val = table.rows[rowIdx][col.name]?.asString ?? ""
                                    Text(val)
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundStyle(Color.white.opacity(0.9))
                                        .frame(width: 170, alignment: .leading)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                }
                            }
                            .background(isHovered ? AstorkaTheme.cardDarkHover : (rowIdx % 2 == 0 ? AstorkaTheme.cardDark : AstorkaTheme.surfaceDark))
                            .overlay(Rectangle().stroke(AstorkaTheme.borderSubtle, lineWidth: 0.5))
                            .onHover { h in
                                hoveredRowIdx = h ? rowIdx : nil
                            }
                        }
                    }
                    .padding(20)
                }
            }
        } else {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "tablecells.badge.ellipsis")
                    .font(.system(size: 48))
                    .foregroundStyle(AstorkaTheme.cyanNeon.opacity(0.4))
                Text("Select or Create a Data Table")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text("Organize tabular records like items, card stats, prices, and dialogue choices.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AstorkaTheme.bgDark)
        }
    }
}
