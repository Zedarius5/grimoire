import Foundation
import UserNotifications
import GrimoireKit

/// macOS notification dispatch for the highlight-match path. Requests
/// permission on first use, then fans out to `UNUserNotificationCenter`.
///
/// Throttled per-rule-id so a chatty rule doesn't flood the notification
/// center while independent rules don't suppress each other.
///
/// Note: UserNotifications require a proper app bundle with a bundle id.
/// Unbundled SPM runs from `.build/` fail authorization, which we log rather
/// than crash on; run from a built `.app` for live behavior.
@MainActor
final class NotificationManager {

    static let shared = NotificationManager()

    /// Minimum gap (seconds) between notifications fired by the same rule.
    private static let perRuleThrottle: TimeInterval = 5

    private var authorizationRequested = false
    private var authorized = false
    /// Timestamp of the most recent notification per rule id, so we
    /// can apply the per-rule throttle without scanning history.
    private var lastFiredAt: [UUID: Date] = [:]

    /// Intentionally no UNUserNotificationCenterDelegate: that would force
    /// foreground banners, but the macOS default (banners only when
    /// backgrounded) is what's wanted -- no banner while you're watching the
    /// feed, but an alert when you're tabbed away.
    private init() {}

    /// Posts a notification for a highlight match. Drops repeat fires from the
    /// same rule within `perRuleThrottle` seconds. Returns immediately; the
    /// notification-center work is async.
    /// - Parameters:
    ///   - rule: the rule that fired (used as the throttle key).
    ///   - matchedText: the highlighted substring of the line (the matched span,
    ///     or the whole line for `entireLine`), shown as the notification body.
    ///   - groupName: the rule's group name, or nil; shown as the subtitle (with
    ///     a "No highlight group" fallback).
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
        // Fixed title; the system already shows "Grimoire" by the icon.
        content.title = "Highlighted text found"
        // Subtitle = group name (which bucket fired), with a fallback so it's not blank.
        content.subtitle = (groupName?.isEmpty == false) ? groupName! : "No highlight group"
        // Body = the highlighted span, trimmed for display.
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
