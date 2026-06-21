import SwiftUI
import AppKit

/// Shared hex-color parsing for both SwiftUI `Color` (used by
/// `HighlightEditorView`'s color pickers + serialisation) and AppKit
/// `NSColor` (used by `StoryTextView`'s NSAttributedString builder). Keeping
/// them on one parser ensures the round-trip stays consistent — a value
/// edited in the picker renders identically when the renderer reads it back.

/// Parses `"#RGB"`, `"#RRGGBB"`, or `"#RRGGBBAA"` (and their unprefixed
/// variants). Returns nil for any malformed input.
fileprivate func parseHex(_ raw: String) -> (r: Double, g: Double, b: Double, a: Double)? {
    var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if s.hasPrefix("#") { s.removeFirst() }
    guard let value = UInt64(s, radix: 16) else { return nil }
    switch s.count {
    case 3:
        return (
            Double((value >> 8) & 0xF) / 15,
            Double((value >> 4) & 0xF) / 15,
            Double( value       & 0xF) / 15,
            1
        )
    case 6:
        return (
            Double((value >> 16) & 0xFF) / 255,
            Double((value >> 8)  & 0xFF) / 255,
            Double( value        & 0xFF) / 255,
            1
        )
    case 8:
        return (
            Double((value >> 24) & 0xFF) / 255,
            Double((value >> 16) & 0xFF) / 255,
            Double((value >> 8)  & 0xFF) / 255,
            Double( value        & 0xFF) / 255
        )
    default:
        return nil
    }
}

extension Color {
    /// Parses `"#RGB"`, `"#RRGGBB"`, or `"#RRGGBBAA"`. Returns `nil` for
    /// malformed inputs so callers can fall back to a default.
    init?(hex: String) {
        guard let c = parseHex(hex) else { return nil }
        // Explicitly sRGB. The unspecified-color-space initializer can fall
        // through to Generic RGB (gamma 1.8) in some macOS render paths, which
        // brightens neutral grays; naming the color space pins gamma to 2.2 so
        // the on-screen value matches the hex.
        self = Color(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: c.a)
    }

    /// `#RRGGBB` round-trip — alpha is dropped for editor simplicity.
    var hexString: String? {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(self)
        let r = Int((ns.redComponent   * 255).rounded())
        let g = Int((ns.greenComponent * 255).rounded())
        let b = Int((ns.blueComponent  * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

extension NSColor {
    /// Parses `#RRGGBB`, `#RGB`, or `#RRGGBBAA`. Used by the highlight
    /// pipeline when applying a custom highlight's stored hex value to
    /// `NSAttributedString` attributes.
    convenience init?(hexString: String) {
        guard let c = parseHex(hexString) else { return nil }
        self.init(srgbRed: CGFloat(c.r), green: CGFloat(c.g), blue: CGFloat(c.b), alpha: CGFloat(c.a))
    }
}
