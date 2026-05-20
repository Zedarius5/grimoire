import Foundation

/// A token from the GemStone IV wire protocol.
///
/// The stream is line-oriented tag-soup — XML-ish but not strictly valid XML.
/// Attribute values may be single- or double-quoted (sometimes unquoted),
/// and the body can contain raw text mixed with self-closing tags.
public enum Token: Equatable, Sendable {
    case text(String)
    case entityRef(String)
    case charRef(Int)
    case openTag(name: String, attributes: [String: String], selfClosing: Bool)
    case closeTag(name: String)
}
