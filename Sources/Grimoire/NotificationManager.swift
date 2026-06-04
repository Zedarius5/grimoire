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

    private init() {}

    /// Posts a notification for the given matched line. Idempotent
    /// w.r.t. permission requesting (first call requests; subsequent
    /// reuse the result). Per-rule throttling drops repeat fires for
    /// the same rule within `perRuleThrottle` seconds. Returns
    /// immediately; the actual UN center work is async.
    func notify(rule: Highlight, matchedLine: String) {
        if let last = lastFiredAt[rule.id],
           Date().timeIntervalSince(last) < Self.perRuleThrottle {
            return
        }
        lastFiredAt[rule.id] = Date()

        let ruleSnapshot = rule
        let lineSnapshot = matchedLine
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard await self.ensureAuthorized() else { return }
            await self.deliver(rule: ruleSnapshot, matchedLine: lineSnapshot)
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

    private func deliver(rule: Highlight, matchedLine: String) async {
        let content = UNMutableNotificationContent()
        // Use the rule's match text (or a brief excerpt) as the subtitle
        // so the notification center stack stays readable when several
        // rules fire near in time. The actual matched line is the body.
        content.title = "Grimoire"
        content.subtitle = rule.text.isEmpty ? "Highlight match" : rule.text
        content.body = matchedLine.trimmingCharacters(in: .whitespacesAndNewlines)
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
                   "Failed to deliver: \(error.localizedDescription)",
                   level: .info)
        }
    }
}
