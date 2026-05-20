import Foundation

/// Parses the `<macros>` section out of a Wrayth/Stormfront settings XML.
public enum MacroParser {

    public enum ParseError: Error, LocalizedError {
        case ioError(String)
        case parseError(String)

        public var errorDescription: String? {
            switch self {
            case .ioError(let s):    return "Couldn't read file: \(s)"
            case .parseError(let s): return "Couldn't parse: \(s)"
            }
        }
    }

    public static func parse(file url: URL) throws -> MacroConfig {
        guard let data = try? Data(contentsOf: url) else {
            throw ParseError.ioError(url.lastPathComponent)
        }
        return try parse(data: data)
    }

    public static func parse(data: Data) throws -> MacroConfig {
        let parser = XMLParser(data: data)
        let delegate = Delegate()
        parser.delegate = delegate
        if !parser.parse() {
            let msg = parser.parserError?.localizedDescription ?? "unknown parser error"
            throw ParseError.parseError(msg)
        }
        return delegate.config
    }
}

private final class Delegate: NSObject, XMLParserDelegate {
    var config = MacroConfig()
    private var inMacros = false
    private var currentSet: MacroSet?

    func parser(_ parser: XMLParser,
                didStartElement element: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attrs: [String: String] = [:]) {
        switch element {
        case "macros":
            inMacros = true
        case "keys" where inMacros:
            let id = Int(attrs["id"] ?? "0") ?? 0
            let name = attrs["name"] ?? "Set \(id)"
            currentSet = MacroSet(id: id, name: name)
        case "k" where currentSet != nil:
            if let key = attrs["key"], let action = attrs["action"], !key.isEmpty {
                currentSet?.bindings.append(MacroBinding(key: key, action: action))
            }
        default:
            break
        }
    }

    func parser(_ parser: XMLParser,
                didEndElement element: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        switch element {
        case "macros":
            inMacros = false
        case "keys":
            if let set = currentSet { config.sets.append(set) }
            currentSet = nil
        default:
            break
        }
    }
}
