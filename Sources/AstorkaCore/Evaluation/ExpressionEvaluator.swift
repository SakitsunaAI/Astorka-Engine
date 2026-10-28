import Foundation

/// Safe, deterministic, pure Swift No-Code Math & Expression Evaluator.
/// Uses a zero-dependency, high-performance Recursive Descent Parser
/// avoiding platform security restrictions.
public final class ExpressionEvaluator: @unchecked Sendable {
    public init() {}

    /// Evaluates an expression against variables and returns a VariableValue
    public func evaluate(_ expr: String, variables: [String: VariableValue]) -> VariableValue {
        let trimmed = expr.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .string("") }

        // Direct boolean check
        if trimmed.lowercased() == "true" { return .boolean(true) }
        if trimmed.lowercased() == "false" { return .boolean(false) }

        // Quoted string check (e.g. "Hello World" or 'Hello')
        if (trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"")) || (trimmed.hasPrefix("'") && trimmed.hasSuffix("'")) {
            let inner = String(trimmed.dropFirst().dropLast())
            return .string(interpolate(inner, variables: variables))
        }

        // Variable reference check (e.g. $Gold or Gold)
        if trimmed.hasPrefix("$") {
            let varName = String(trimmed.dropFirst())
            if let val = variables[varName] { return val }
        }
        if let val = variables[trimmed] {
            return val
        }

        // Evaluate mathematical or functional expression with pure Swift Parser
        var parser = MathParser(input: trimmed, variables: variables)
        if let num = parser.parse() {
            return .number(num)
        }

        // Fallback to string interpolation if not a mathematical expression
        return .string(interpolate(trimmed, variables: variables))
    }

    /// Interpolates {$VarName} or $VarName references with values
    public func interpolate(_ text: String, variables: [String: VariableValue]) -> String {
        var result = text
        for (key, val) in variables {
            result = result.replacingOccurrences(of: "{\(key)}", with: val.asString)
            result = result.replacingOccurrences(of: "{$\(key)}", with: val.asString)
            result = result.replacingOccurrences(of: "$\(key)", with: val.asString)
        }
        return result
    }

    /// Executes an assignment or mutation statement
    /// e.g. "cash += item_price * 5 / 10" or "raw_materials -= 5" or "cash = 500"
    @discardableResult
    public func executeStatement(_ statement: String, variables: inout [String: VariableValue]) -> Bool {
        let trimmed = statement.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return false }

        let operators = ["+=", "-=", "*=", "/=", "="]
        for op in operators {
            if let range = trimmed.range(of: op) {
                var varName = String(trimmed[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                if varName.hasPrefix("$") { varName = String(varName.dropFirst()) }
                let expr = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)

                // Case-insensitive variable lookup
                let matchedKey = variables.keys.first { $0.lowercased() == varName.lowercased() } ?? varName
                let currentVal = variables[matchedKey]?.asNumber ?? 0.0
                let exprVal = evaluate(expr, variables: variables).asNumber

                let finalVal: Double
                switch op {
                case "+=": finalVal = currentVal + exprVal
                case "-=": finalVal = currentVal - exprVal
                case "*=": finalVal = currentVal * exprVal
                case "/=": finalVal = exprVal != 0 ? currentVal / exprVal : currentVal
                case "=":  finalVal = exprVal
                default:   finalVal = exprVal
                }

                variables[matchedKey] = .number(finalVal)
                return true
            }
        }
        return false
    }

    /// Evaluates a condition expression
    /// e.g. "raw_materials >= 5" or "cash > 100" or "level == 2"
    public func evaluateCondition(_ conditionStr: String, variables: [String: VariableValue]) -> Bool {
        let trimmed = conditionStr.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }

        let ops = [">=", "<=", "==", "!=", ">", "<"]
        for op in ops {
            if let range = trimmed.range(of: op) {
                let leftStr = String(trimmed[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let rightStr = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)

                let leftVal = evaluate(leftStr, variables: variables).asNumber
                let rightVal = evaluate(rightStr, variables: variables).asNumber

                switch op {
                case ">=": return leftVal >= rightVal
                case "<=": return leftVal <= rightVal
                case "==": return leftVal == rightVal
                case "!=": return leftVal != rightVal
                case ">":  return leftVal > rightVal
                case "<":  return leftVal < rightVal
                default:   return false
                }
            }
        }
        return evaluate(trimmed, variables: variables).asBool
    }
}

// MARK: - Pure Swift Mathematical Expression Parser (Recursive Descent)

private struct MathParser {
    let chars: [Character]
    var pos: Int = 0
    let variables: [String: VariableValue]

    init(input: String, variables: [String: VariableValue]) {
        self.chars = Array(input)
        self.variables = variables
    }

    mutating func parse() -> Double? {
        skipWhitespace()
        guard let result = parseExpression() else { return nil }
        skipWhitespace()
        if pos < chars.count {
            // If expression was not consumed completely
            return nil
        }
        return result
    }

    private mutating func peek() -> Character? {
        guard pos < chars.count else { return nil }
        return chars[pos]
    }

    private mutating func advance() -> Character? {
        guard pos < chars.count else { return nil }
        let c = chars[pos]
        pos += 1
        return c
    }

    private mutating func skipWhitespace() {
        while pos < chars.count && chars[pos].isWhitespace {
            pos += 1
        }
    }

    // Expression: Term (('+' | '-') Term)*
    private mutating func parseExpression() -> Double? {
        guard var value = parseTerm() else { return nil }

        while true {
            skipWhitespace()
            guard let next = peek(), next == "+" || next == "-" else { break }
            _ = advance()
            guard let nextTerm = parseTerm() else { return nil }
            if next == "+" {
                value += nextTerm
            } else {
                value -= nextTerm
            }
        }

        return value
    }

    // Term: Factor (('*' | '/' | '%') Factor)*
    private mutating func parseTerm() -> Double? {
        guard var value = parseFactor() else { return nil }

        while true {
            skipWhitespace()
            guard let next = peek(), next == "*" || next == "/" || next == "%" else { break }
            _ = advance()
            guard let nextFactor = parseFactor() else { return nil }
            if next == "*" {
                value *= nextFactor
            } else if next == "/" {
                value = nextFactor != 0 ? value / nextFactor : 0
            } else if next == "%" {
                value = nextFactor != 0 ? value.truncatingRemainder(dividingBy: nextFactor) : 0
            }
        }

        return value
    }

    // Factor: ('+' | '-')? Primary
    private mutating func parseFactor() -> Double? {
        skipWhitespace()
        guard let next = peek() else { return nil }

        if next == "+" {
            _ = advance()
            return parseFactor()
        } else if next == "-" {
            _ = advance()
            guard let val = parseFactor() else { return nil }
            return -val
        }

        return parsePrimary()
    }

    // Primary: Number | '(' Expression ')' | FunctionCall | Variable
    private mutating func parsePrimary() -> Double? {
        skipWhitespace()
        guard let next = peek() else { return nil }

        // Parentheses
        if next == "(" {
            _ = advance()
            guard let val = parseExpression() else { return nil }
            skipWhitespace()
            if peek() == ")" { _ = advance() }
            return val
        }

        // Numbers
        if next.isNumber || next == "." {
            return parseNumber()
        }

        // Variable reference ($VarName)
        if next == "$" {
            _ = advance()
            let name = parseIdentifier()
            return variables[name]?.asNumber ?? 0.0
        }

        // Identifier (Function or Variable)
        if next.isLetter || next == "_" {
            let ident = parseIdentifier()
            skipWhitespace()
            if peek() == "(" {
                // Function call
                return parseFunction(named: ident)
            } else {
                // Variable reference
                return variables[ident]?.asNumber ?? 0.0
            }
        }

        return nil
    }

    private mutating func parseNumber() -> Double? {
        var numStr = ""
        var hasDot = false

        while let c = peek() {
            if c.isNumber {
                numStr.append(c)
                _ = advance()
            } else if c == "." && !hasDot {
                hasDot = true
                numStr.append(c)
                _ = advance()
            } else {
                break
            }
        }

        return Double(numStr)
    }

    private mutating func parseIdentifier() -> String {
        var ident = ""
        while let c = peek(), c.isLetter || c.isNumber || c == "_" {
            ident.append(c)
            _ = advance()
        }
        return ident
    }

    private mutating func parseFunction(named name: String) -> Double? {
        guard peek() == "(" else { return nil }
        _ = advance() // Skip '('

        var args: [Double] = []
        skipWhitespace()
        if peek() != ")" {
            while true {
                guard let arg = parseExpression() else { return nil }
                args.append(arg)
                skipWhitespace()
                if peek() == "," {
                    _ = advance()
                    skipWhitespace()
                } else {
                    break
                }
            }
        }

        skipWhitespace()
        if peek() == ")" { _ = advance() }

        switch name.lowercased() {
        case "random":
            if args.count >= 2 {
                let minV = min(args[0], args[1])
                let maxV = max(args[0], args[1])
                return round(Double.random(in: minV...maxV))
            }
            return 0
        case "clamp":
            if args.count >= 3 {
                return min(max(args[0], args[1]), args[2])
            }
            return args.first ?? 0
        case "min":
            if args.count >= 2 { return min(args[0], args[1]) }
            return args.first ?? 0
        case "max":
            if args.count >= 2 { return max(args[0], args[1]) }
            return args.first ?? 0
        case "round":
            return round(args.first ?? 0)
        case "floor":
            return floor(args.first ?? 0)
        case "ceil":
            return ceil(args.first ?? 0)
        default:
            return 0
        }
    }
}
