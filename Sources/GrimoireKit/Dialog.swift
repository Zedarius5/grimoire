import Foundation

/// A script-defined panel pushed by the server (`<openDialog>` / `<dialogData>`).
/// Wrayth and Warlock render these as docked widgets; in Grimoire they get
/// mapped onto the same pane layout the stream panes use.
public struct Dialog: Identifiable, Equatable, Sendable {
    public let id: String
    public var title: String
    public var widgets: [DialogWidget]
    /// Time of the most recent widget update. UI uses this to subtract
    /// elapsed seconds from each progressBar's `time` value so the visible
    /// countdown ticks smoothly between Lich's emit intervals.
    public var lastUpdated: Date

    public init(id: String, title: String = "", widgets: [DialogWidget] = [], lastUpdated: Date = Date()) {
        self.id = id
        self.title = title.isEmpty ? id : title
        self.widgets = widgets
        self.lastUpdated = lastUpdated
    }
}

/// A `left/top/width/height` value, which may be absolute pixels (`'80'`)
/// or a fraction of the parent dimension (`'25%'`).
public enum Length: Equatable, Hashable, Sendable {
    case px(Int)
    case percent(Double)

    public static func parse(_ s: String?) -> Length? {
        guard let s = s, !s.isEmpty else { return nil }
        if s.hasSuffix("%") {
            let raw = String(s.dropLast())
            if let v = Double(raw) { return .percent(v / 100.0) }
            return nil
        }
        if let v = Int(s) { return .px(v) }
        return nil
    }

    public var rowKey: Int {
        switch self {
        case .px(let v):      return v
        case .percent(let v): return Int(v * 10_000)
        }
    }

    public func resolve(against parent: CGFloat) -> CGFloat {
        switch self {
        case .px(let v):      return CGFloat(v)
        case .percent(let v): return CGFloat(v) * parent
        }
    }
}

/// Layout attributes for a widget (`left`, `top`, `width`, `height`, plus the
/// `anchor_left` / `anchor_top` references the Stormfront protocol uses to
/// chain widgets together within a row).
public struct WidgetLayout: Equatable, Hashable, Sendable {
    public var left: Length?
    public var top: Length?
    public var width: Length?
    public var height: Length?
    public var anchorLeft: String?
    public var anchorTop: String?

    public init(
        left: Length? = nil,
        top: Length? = nil,
        width: Length? = nil,
        height: Length? = nil,
        anchorLeft: String? = nil,
        anchorTop: String? = nil
    ) {
        self.left = left
        self.top = top
        self.width = width
        self.height = height
        self.anchorLeft = anchorLeft
        self.anchorTop = anchorTop
    }

    public static func parse(_ attrs: [String: String]) -> WidgetLayout {
        WidgetLayout(
            left:   Length.parse(attrs["left"]),
            top:    Length.parse(attrs["top"]),
            width:  Length.parse(attrs["width"]),
            height: Length.parse(attrs["height"]),
            anchorLeft: attrs["anchor_left"]?.nilIfEmpty,
            anchorTop:  attrs["anchor_top"]?.nilIfEmpty
        )
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

/// One renderable element inside a Dialog.
public enum DialogWidget: Equatable, Sendable {
    case label(id: String, text: String, layout: WidgetLayout)
    case link(id: String, text: String, command: String?, layout: WidgetLayout)
    case progressBar(id: String, value: Int, text: String, time: String?, layout: WidgetLayout)
    case image(id: String, name: String, layout: WidgetLayout)
    case separator

    /// The widget's `id` attribute, used to upsert in place when the script
    /// re-emits a label/bar with the same id (Wrayth's update semantics).
    public var widgetId: String? {
        switch self {
        case .label(let id, _, _):              return id.isEmpty ? nil : id
        case .link(let id, _, _, _):            return id.isEmpty ? nil : id
        case .progressBar(let id, _, _, _, _):  return id.isEmpty ? nil : id
        case .image(let id, _, _):              return id.isEmpty ? nil : id
        case .separator:                        return nil
        }
    }

    public var layout: WidgetLayout {
        switch self {
        case .label(_, _, let l):              return l
        case .link(_, _, _, let l):            return l
        case .progressBar(_, _, _, _, let l):  return l
        case .image(_, _, let l):              return l
        case .separator:                       return WidgetLayout()
        }
    }
}

extension Dialog {
    /// Replaces a widget with the same `widgetId`, or appends if it's new.
    public mutating func upsert(_ widget: DialogWidget) {
        if let id = widget.widgetId,
           let idx = widgets.firstIndex(where: { $0.widgetId == id }) {
            widgets[idx] = widget
        } else {
            widgets.append(widget)
        }
        lastUpdated = Date()
    }
}
