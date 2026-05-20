import SwiftUI
import AppKit

/// Loads a game-icons.net SVG from the app bundle and renders it as a
/// tintable template image. The SVGs from game-icons are pure white-on-
/// transparent, so marking `NSImage.isTemplate = true` lets SwiftUI's
/// `.foregroundStyle()` apply any colour we want — same ergonomics as
/// `Image(systemName:)` for SF Symbols.
///
/// Resources are declared in `Package.swift` via `.process("Resources/
/// game-icons")` so `Bundle.module` finds them by name (no extension).
struct GameIcon: View {
    let name: String

    var body: some View {
        if let image = Self.image(named: name) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            // Loud fallback so a typo or missing file shows up obviously
            // during development rather than silently rendering empty.
            Image(systemName: "questionmark.square.dashed")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.red)
        }
    }

    /// Cached so repeated renders of the same status don't re-parse the
    /// SVG every frame. `NSImage` objects are reference types, safe to
    /// share across views.
    private static let cache = NSCache<NSString, NSImage>()

    private static func image(named name: String) -> NSImage? {
        if let cached = cache.object(forKey: name as NSString) {
            return cached
        }
        guard let url = Bundle.module.url(
            forResource: name,
            withExtension: "svg"
        ) else { return nil }
        guard let image = NSImage(contentsOf: url) else { return nil }
        image.isTemplate = true
        cache.setObject(image, forKey: name as NSString)
        return image
    }
}
