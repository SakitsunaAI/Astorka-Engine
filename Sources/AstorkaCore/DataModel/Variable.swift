import Foundation

/// Enum representing all variable types inside the engine.
public enum VariableValue: Codable, Equatable, CustomStringConvertible, Sendable {
    case number(Double)
    case string(String)
    case boolean(Bool)
    case list([String])

    public var asNumber: Double {
        switch self {
        case .number(let v): return v
        case .string(let s): return Double(s) ?? 0.0
        case .boolean(let b): return b ? 1.0 : 0.0
        case .list(let arr): return Double(arr.count)
        }
    }

    public var asString: String {
        switch self {
        case .number(let v):
            if v.truncatingRemainder(dividingBy: 1) == 0 {
                return String(Int(v))
            } else {
                return String(format: "%.2f", v)
            }
        case .string(let s): return s
        case .boolean(let b): return b ? "true" : "false"
        case .list(let arr): return arr.joined(separator: ", ")
        }
    }

    public var asBool: Bool {
        switch self {
        case .number(let v): return v > 0
        case .string(let s): return !s.isEmpty && s != "false" && s != "0"
        case .boolean(let b): return b
        case .list(let arr): return !arr.isEmpty
        }
    }

    public var description: String {
        return asString
    }
}

/// Variable definition and metadata
public struct GameVariable: Codable, Identifiable, Equatable, Sendable {
    public var id: String { name }
    public var name: String
    public var initialValue: VariableValue
    public var category: String
    public var description: String

    public init(name: String, initialValue: VariableValue, category: String = "General", description: String = "") {
        self.name = name
        self.initialValue = initialValue
        self.category = category
        self.description = description
    }
}
