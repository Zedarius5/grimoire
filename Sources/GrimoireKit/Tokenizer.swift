import Foundation

/// Tokenizes one wire line of the GemStone IV protocol into a flat token stream.
///
/// The network layer is responsible for splitting on newlines; this function
/// assumes its input is a single complete line (no embedded `\n`).
public enum Tokenizer {

    public static func tokenize(_ line: String) -> [Token] {
        var scanner = Scanner(line)
        var tokens: [Token] = []
        var text = ""

        func flushText() {
            if !text.isEmpty {
                tokens.append(.text(text))
                text = ""
            }
        }

        while let c = scanner.peek() {
            switch c {
            case "<":
                if scanner.matches("<!--") {
                    flushText()
                    scanner.advance(4)
                    _ = scanner.consumeUntil("-->")
                    continue
                }
                flushText()
                scanner.advance()
                let isClose = scanner.consumeIf("/")
                guard let name = scanner.consumeName() else {
                    // Stray '<' — treat as literal text.
                    text.append("<")
                    if isClose { text.append("/") }
                    continue
                }
                if isClose {
                    _ = scanner.consumeWhile { $0 != ">" }
                    _ = scanner.consumeIf(">")
                    tokens.append(.closeTag(name: name))
                } else {
                    let attrs = scanner.consumeAttributes()
                    let selfClosing = scanner.consumeIf("/")
                    _ = scanner.consumeIf(">")
                    tokens.append(.openTag(name: name, attributes: attrs, selfClosing: selfClosing))
                }

            case "&":
                let savedIndex = scanner.index
                scanner.advance()
                if scanner.consumeIf("#") {
                    let hex = scanner.consumeIf("x") || scanner.consumeIf("X")
                    let digits = scanner.consumeWhile { ch in
                        hex ? (ch.hexDigitValue != nil) : (ch >= "0" && ch <= "9")
                    }
                    if !digits.isEmpty, scanner.consumeIf(";"),
                       let value = Int(digits, radix: hex ? 16 : 10) {
                        flushText()
                        tokens.append(.charRef(value))
                    } else {
                        // Malformed numeric ref — emit '&' literally and rewind.
                        scanner.index = savedIndex
                        text.append("&")
                        scanner.advance()
                    }
                } else if let name = scanner.consumeName(), scanner.consumeIf(";") {
                    flushText()
                    tokens.append(.entityRef(name))
                } else {
                    scanner.index = savedIndex
                    text.append("&")
                    scanner.advance()
                }

            default:
                text.append(c)
                scanner.advance()
            }
        }
        flushText()
        return tokens
    }
}

// MARK: - Scanner

private struct Scanner {
    let chars: [Character]
    var index: Int = 0

    init(_ string: String) { self.chars = Array(string) }

    func peek(offset: Int = 0) -> Character? {
        let i = index + offset
        return i < chars.count ? chars[i] : nil
    }

    mutating func advance(_ n: Int = 1) {
        index = Swift.min(index + n, chars.count)
    }

    mutating func consumeIf(_ c: Character) -> Bool {
        guard peek() == c else { return false }
        advance()
        return true
    }

    func matches(_ s: String) -> Bool {
        for (i, c) in s.enumerated() where peek(offset: i) != c { return false }
        return true
    }

    mutating func consumeUntil(_ s: String) -> String {
        var result = ""
        while index < chars.count {
            if matches(s) {
                advance(s.count)
                return result
            }
            result.append(chars[index])
            advance()
        }
        return result
    }

    mutating func consumeWhile(_ predicate: (Character) -> Bool) -> String {
        var result = ""
        while let c = peek(), predicate(c) {
            result.append(c)
            advance()
        }
        return result
    }

    mutating func consumeName() -> String? {
        guard let first = peek(), first.isLetter || first == "_" else { return nil }
        var name = String(first)
        advance()
        while let c = peek(), c.isLetter || c.isNumber || c == "_" || c == "-" || c == ":" {
            name.append(c)
            advance()
        }
        return name
    }

    mutating func consumeAttributes() -> [String: String] {
        var attrs: [String: String] = [:]
        while let c = peek() {
            if c == ">" || c == "/" { break }
            if c.isWhitespace { advance(); continue }
            guard let name = consumeName() else {
                advance()  // skip unrecognized char to avoid an infinite loop
                continue
            }
            _ = consumeWhile { $0.isWhitespace }
            if consumeIf("=") {
                _ = consumeWhile { $0.isWhitespace }
                if let quote = peek(), quote == "\"" || quote == "'" {
                    advance()
                    let value = consumeWhile { $0 != quote }
                    _ = consumeIf(quote)
                    attrs[name] = decodeXMLEntities(value)
                } else {
                    let value = consumeWhile { ch in
                        !ch.isWhitespace && ch != ">" && ch != "/"
                    }
                    attrs[name] = decodeXMLEntities(value)
                }
            } else {
                attrs[name] = ""
            }
        }
        return attrs
    }
}

/// Decodes escaped XML attribute values (`wyrm&apos;s heart`). Text content
/// is decoded separately via `.entityRef` tokens + `StreamRenderer.decodeEntity`,
/// so this only fires for the attribute path.
///
/// `&amp;` is decoded LAST so sequences like `&amp;apos;` (which should become
/// the literal text `&apos;`, not an apostrophe) aren't double-decoded.
private func decodeXMLEntities(_ s: String) -> String {
    guard s.contains("&") else { return s }
    var out = s
    out = out.replacingOccurrences(of: "&apos;", with: "'")
    out = out.replacingOccurrences(of: "&quot;", with: "\"")
    out = out.replacingOccurrences(of: "&lt;",   with: "<")
    out = out.replacingOccurrences(of: "&gt;",   with: ">")
    out = out.replacingOccurrences(of: "&nbsp;", with: "\u{00A0}")
    out = out.replacingOccurrences(of: "&amp;",  with: "&")
    return out
}
