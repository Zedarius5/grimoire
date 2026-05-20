import Foundation

public enum HighlightImportError: Error, LocalizedError {
    case fileUnreadable
    case parseFailure(String)

    public var errorDescription: String? {
        switch self {
        case .fileUnreadable:        return "Couldn't read the file."
        case .parseFailure(let msg): return "XML parse error: \(msg)"
        }
    }
}

/// Imports Wrayth's `<settings><strings><h .../></strings><palette>...</palette></settings>`
/// highlight format. Wrayth references palette entries as `@N` from inside
/// the highlight rows; we resolve those to `#RRGGBB` after both sections have
/// been seen (palette appears after strings in the XML).
public enum HighlightParser {
    public static func parse(file url: URL) throws -> [Highlight] {
        guard let data = try? Data(contentsOf: url) else {
            throw HighlightImportError.fileUnreadable
        }
        return try parse(data: data)
    }

    public static func parse(data: Data) throws -> [Highlight] {
        let delegate = WraythHighlightDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        guard parser.parse() else {
            let msg = parser.parserError?.localizedDescription ?? "unknown error"
            throw HighlightImportError.parseFailure(msg)
        }
        return delegate.resolved()
    }
}

private final class WraythHighlightDelegate: NSObject, XMLParserDelegate {

    private struct RawHighlight {
        var text: String
        var fg: String?
        var bg: String?
        var entireLine: Bool
        var caseSensitive: Bool
        var wholeWord: Bool
        var kind: HighlightKind
    }

    private var inStrings = false
    private var inNames   = false
    private var inPalette = false
    private var palette: [String: String] = [:]
    private var raw: [RawHighlight] = []

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        switch elementName {
        case "strings": inStrings = true
        case "names":   inNames   = true
        case "palette": inPalette = true

        case "i" where inPalette:
            if let id = attributeDict["id"], let color = attributeDict["color"], !color.isEmpty {
                palette[id] = color
            }

        case "h" where inStrings || inNames:
            guard let text = attributeDict["text"], !text.isEmpty else { return }
            raw.append(RawHighlight(
                text: text,
                fg: attributeDict["color"].flatMap { $0.isEmpty ? nil : $0 },
                bg: attributeDict["bgcolor"].flatMap { $0.isEmpty ? nil : $0 },
                entireLine: attributeDict["line"] == "y",
                caseSensitive: attributeDict["case"] == "y",
                wholeWord: attributeDict["word"] == "y",
                kind: inNames ? .name : .text
            ))

        default: break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        switch elementName {
        case "strings": inStrings = false
        case "names":   inNames   = false
        case "palette": inPalette = false
        default: break
        }
    }

    func resolved() -> [Highlight] {
        raw.map { r in
            Highlight(
                text: r.text,
                fgColor: resolve(r.fg),
                bgColor: resolve(r.bg),
                entireLine: r.entireLine,
                caseSensitive: r.caseSensitive,
                wholeWord: r.wholeWord,
                kind: r.kind
            )
        }
    }

    /// `@N` → palette lookup, `#RRGGBB` → passthrough, anything else → nil.
    private func resolve(_ ref: String?) -> String? {
        guard let ref else { return nil }
        if ref.hasPrefix("@") { return palette[String(ref.dropFirst())] }
        if ref.hasPrefix("#") { return ref }
        return nil
    }
}
