import Foundation

/// Data table column types
public enum DataColumnType: String, Codable, Sendable {
    case string
    case number
    case boolean
}

public struct DataColumn: Codable, Identifiable, Equatable, Sendable {
    public var id: String { name }
    public var name: String
    public var type: DataColumnType
    public var defaultValue: String

    public init(name: String, type: DataColumnType, defaultValue: String = "") {
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
    }
}

/// No-Code Data Table: For cards, items, entities, and upgrades.
public struct DataTable: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var columns: [DataColumn]
    public var rows: [[String: VariableValue]]

    public init(id: String, name: String, columns: [DataColumn] = [], rows: [[String: VariableValue]] = []) {
        self.id = id
        self.name = name
        self.columns = columns
        self.rows = rows
    }

    /// Returns the first matching row where the column matches value
    public func findRow(where column: String, equals value: String) -> [String: VariableValue]? {
        return rows.first { row in
            row[column]?.asString.lowercased() == value.lowercased()
        }
    }

    /// Returns all matching rows
    public func filterRows(where column: String, equals value: String) -> [[String: VariableValue]] {
        return rows.filter { row in
            row[column]?.asString.lowercased() == value.lowercased()
        }
    }

    /// Retrieves a random row (for drawing cards, loot drops, etc.)
    public func randomRow() -> [String: VariableValue]? {
        return rows.randomElement()
    }
}
