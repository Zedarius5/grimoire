import Foundation
import UserNotifications
import GrimoireKit

/// macOS notification dispatch for the highlight-match path. Requests
/// permission on first use; subsequent calls fan out to
/// `UNUserNotificationCenter` if the user granted access.
///
/// Per-rule throttle: a rule that matches dozens of lines in a row
/// (e.g. a chatty regex) doesn't flood the notification center. The
/// throttle window is per-rule-id so independent rules don't suppress
/// each other.
///
/// Note: macOS UserNotifications require the running binary to be
/// inside a proper app bundle with a bundle identifier. SPM-built
/// executables run directly from `.build/` won't have one, so
/// `requestAuthorization` will fail with "not bundled" and we'll log
/// it instead of crashing. Run from a built `.app` for live behavior.
@MainActor
final class NotificationManager {

    static let shared = NotificationManager()

    /// Minimum gap between notifications fired by the SAME rule, in
    /// seconds. Tunable; 5s is a sensible "don't drown me" floor that
    /// still catches genuinely-spaced events.
    private static let perRuleThrottle: TimeInterval = 5

    private var authorizationRequested = false
    private var authorized = false
    /// Timestamp of the most recent notification per rule id, so we
    /// can apply the per-rule throttle without scanning history.
    private var lastFiredAt: [UUID: Date] = [:]

    /// Intentionally no UNUserNotificationCenterDelegate set: that
    /// would let us force foreground banner presentation, but the
    /// macOS default ("only show banners when the app is in the
    /// background") is what the user actually wants. A match while
    /// you're already watching the feed shouldn't pop a banner on
    /// top of itself; a match while you're tabbed away SHOULD alert
    /// you. The default behavior handles both cases.
    private init() {}

    /// Posts a notification for a highlight match.
    /// - Parameters:
    ///   - rule: the rule that fired (used as the throttle key).
    ///   - matchedText: the actual substring of the game line that
    ///     was highlighted -- for a regex rule this is the matched
    ///     span, for a `entireLine` rule the whole line, etc. Shown
    ///     as the notification body so the user sees what hit, not
    ///     the rule's match pattern.
    ///   - groupName: optional name of the rule's group; nil when
    ///     the rule isn't grouped. Shown as the subtitle (with a
    ///     "No highlight group" fallback so the slot isn't blank).
    ///
    /// Per-rule throttling drops repeat fires within
    /// `perRuleThrottle` seconds. Returns immediately; the UN
    /// center work is async.
    func notify(rule: Highlight, matchedText: String, groupName: String?) {
        if let last = lastFiredAt[rule.id],
           Date().timeIntervalSince(last) < Self.perRuleThrottle {
            return
        }
        lastFiredAt[rule.id] = Date()

        let ruleId = rule.id
        let matched = matchedText
        let group = groupName
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard await self.ensureAuthorized() else { return }
            await self.deliver(ruleId: ruleId, matchedText: matched, groupName: group)
        }
    }

    private func ensureAuthorized() async -> Bool {
        if authorizationRequested { return authorized }
        authorizationRequested = true
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            authorized = granted
            if !granted {
                appLog("NotificationManager",
                       "User declined notification permission",
                       level: .info)
            }
            return granted
        } catch {
            appLog("NotificationManager",
                   "Authorization failed: \(error.localizedDescription) (likely unbundled SPM run)",
                   level: .info)
            return false
        }
    }

    private func deliver(ruleId: UUID, matchedText: String, groupName: String?) async {
        let content = UNMutableNotificationContent()
        // Fixed title -- the system already shows "Grimoire" next to
        // the icon, so this slot describes the event itself.
        content.title = "Highlighted text found"
        // Group name in the subtitle gives the user immediate context
        // for which bucket of rules fired. Explicit fallback string
        // for ungrouped rules so the slot isn't blank.
        content.subtitle = (groupName?.isEmpty == false) ? groupName! : "No highlight group"
        // Body is the actual highlighted span (for regex matches that's
        // the substring that hit; for entireLine rules it's the whole
        // line). Trimmed for tidy display.
        content.body = matchedText.trimmingCharacters(in: .whitespacesAndNewlines)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil  // deliver immediately
        )
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            appLog("NotificationManager",
                   "Failed to deliver (rule \(ruleId)): \(error.localizedDescription)",
                   level: .info)
        }
    }
}
