import Foundation

/// Small presentation highlighter for the captured Python example, not a Python
/// parser. Other language fences remain verbatim and uncolored. No code executes.
public enum PythonCodePresentation {
    public enum Kind: Equatable, Sendable { case plain, keyword, string, interpolation, number, comment }
    public struct Token: Equatable, Sendable {
        public let text: String
        public let kind: Kind
        public init(_ text: String, _ kind: Kind) { self.text = text; self.kind = kind }
    }
    public static func tokens(_ source: String, language: String?) -> [Token] {
        guard ["python", "py"].contains(language?.lowercased() ?? "") else { return [.init(source, .plain)] }
        let pattern = #"#[^\n]*|(?:\b[fF])?"(?:\\.|[^"\\])*"|(?:\b[fF])?'(?:\\.|[^'\\])*'|\b(?:def|return|if|else|elif|for|in|while|import|from|as|class|try|except|with|yield|True|False|None|and|or|not|pass)\b|\b\d+(?:\.\d+)?\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [.init(source, .plain)] }
        let string = source as NSString
        var offset = 0; var output: [Token] = []
        for match in regex.matches(in: source, range: NSRange(location: 0, length: string.length)) {
            if match.range.location > offset { output.append(.init(string.substring(with: NSRange(location: offset, length: match.range.location - offset)), .plain)) }
            let value = string.substring(with: match.range)
            if value.hasPrefix("#") { output.append(.init(value, .comment)) }
            else if value.hasPrefix("\"") || value.hasPrefix("'") { output.append(.init(value, .string)) }
            else if value.hasPrefix("f\"") || value.hasPrefix("f'") || value.hasPrefix("F\"") || value.hasPrefix("F'") { output += interpolated(value) }
            else if value.first?.isNumber == true { output.append(.init(value, .number)) }
            else { output.append(.init(value, .keyword)) }
            offset = NSMaxRange(match.range)
        }
        if offset < string.length { output.append(.init(string.substring(from: offset), .plain)) }
        return output
    }
    private static func interpolated(_ source: String) -> [Token] {
        guard let regex = try? NSRegularExpression(pattern: #"(?<!\{)\{[^{}]*\}(?!\})"#) else { return [.init(source, .string)] }
        let string = source as NSString; var offset = 0; var output: [Token] = []
        for match in regex.matches(in: source, range: NSRange(location: 0, length: string.length)) {
            output.append(.init(string.substring(with: NSRange(location: offset, length: match.range.location - offset)), .string))
            output.append(.init(string.substring(with: match.range), .interpolation)); offset = NSMaxRange(match.range)
        }
        output.append(.init(string.substring(from: offset), .string)); return output
    }
}
