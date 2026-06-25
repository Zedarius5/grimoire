import CoreGraphics

/// Coordinate mapping for `scroll='manual'` dialog windows, whose children
/// carry absolute StormFront pixel positions. Pure + testable; the SwiftUI
/// layer (`DialogPane`) calls these and offsets each widget.
///
/// Responsive X: `left` is treated as a fraction of a ~300px design width and
/// scaled to the pane's actual width, so columns keep their relative positions
/// at any size. 1:1 Y: `top` maps straight to points, preserving the script's
/// row rhythm inside a vertical scroll.
public enum ManualDialogLayout {

    /// StormFront's dialog design width. `left` values are fractions of this.
    /// Also the minimum layout width — below it the view scrolls horizontally
    /// rather than letting columns collide.
    public static let designWidth: CGFloat = 300

    /// The width the widgets are laid out within: the pane width, but never
    /// below `designWidth`.
    public static func layoutWidth(paneWidth: CGFloat) -> CGFloat {
        max(paneWidth, designWidth)
    }

    /// Top-left point for a widget at server design-space `(leftPx, topPx)`.
    public static func position(leftPx: CGFloat, topPx: CGFloat, paneWidth: CGFloat) -> CGPoint {
        let lw = layoutWidth(paneWidth: paneWidth)
        return CGPoint(x: (leftPx / designWidth) * lw, y: topPx)
    }
}
