import SwiftUI
import GrimoireKit

/// What ConnectView hands back to its parent on a successful authentication.
/// Bundles the typed-in fields, the SGE-returned game credentials, and the
/// resolved Ruby interpreter path so the caller doesn't have to re-derive any
/// of them for the post-auth session setup (lich launch + connect).
struct ConnectAuthResult {
    let account: String
    let password: String
    let character: String
    let gameCode: String
    let rememberCredentials: Bool
    let serverCreds: GameCredentials
    let rubyPath: String
    let lichRoot: String
}

/// Connect/Play popover. Owns the SGE authentication flow but delegates the
/// post-auth work (lich launch, layout loading, keychain save) to the parent
/// via `onAuthenticated`. Keeps the form @State on the parent so in-progress
/// typing survives the popover being dismissed and re-opened.
struct ConnectView: View {
    @ObservedObject var client: LichClient
    @Binding var showingConnect: Bool
    @Binding var launchAccount: String
    @Binding var launchPassword: String
    @Binding var launchCharacter: String
    @Binding var launchGameCode: String
    @Binding var rememberCredentials: Bool
    let onAuthenticated: (ConnectAuthResult) -> Void

    @State private var recents: [Preferences.LastLogin] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Play").font(.headline)

            if !recents.isEmpty {
                recentList
                Divider()
            }

            HStack {
                Text("Account").frame(width: 80, alignment: .trailing)
                TextField("Simu account", text: $launchAccount)
                    .textFieldStyle(.roundedBorder)
            }
            HStack {
                Text("Password").frame(width: 80, alignment: .trailing)
                SecureField("password", text: $launchPassword)
                    .textFieldStyle(.roundedBorder)
            }
            HStack {
                Text("Character").frame(width: 80, alignment: .trailing)
                TextField("e.g. Drakuud", text: $launchCharacter)
                    .textFieldStyle(.roundedBorder)
            }
            HStack {
                Text("Game").frame(width: 80, alignment: .trailing)
                Picker("", selection: $launchGameCode) {
                    Text("GemStone IV (GS3)").tag("GS3")
                    Text("GemStone IV — Platinum (GSX)").tag("GSX")
                    Text("GemStone IV — Shattered (GSF)").tag("GSF")
                    Text("GemStone IV — Test (GST)").tag("GST")
                }
                .labelsHidden()
            }
            Toggle("Remember on this Mac", isOn: $rememberCredentials)
                .font(.caption)
            HStack {
                Spacer()
                Button("Authenticate & Play") {
                    Task { await authenticate() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(launchAccount.isEmpty || launchPassword.isEmpty || launchCharacter.isEmpty)
            }
        }
        .padding(16)
        .frame(width: 420)
        .onAppear { recents = Preferences.loadRecentLogins() }
    }

    /// Scrollable list of previously logged-in characters. Tap a row to fill
    /// the form; the ✕ forgets that character.
    private var recentList: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Recent characters")
                .font(.caption).foregroundStyle(.secondary)
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(recents) { entry in
                        HStack(spacing: 6) {
                            Button { selectRecent(entry) } label: {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(entry.character)
                                    Text("\(entry.account) · \(entry.gameCode)")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            Button {
                                Preferences.removeRecentLogin(entry)
                                recents = Preferences.loadRecentLogins()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Forget this character")
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color(nsColor: .textBackgroundColor).opacity(0.6))
                        )
                    }
                }
            }
            // A definite height (not just maxHeight) so the ScrollView doesn't
            // collapse to zero inside the dialog's height-hugging VStack.
            .frame(height: min(CGFloat(recents.count) * 40, 160))
        }
    }

    /// Fills the form from a saved character (and its Keychain password).
    private func selectRecent(_ entry: Preferences.LastLogin) {
        launchAccount = entry.account
        launchCharacter = entry.character
        launchGameCode = entry.gameCode
        if let pw = Keychain.loadPassword(account: entry.account) {
            launchPassword = pw
        }
    }

    private func authenticate() async {
        let account   = launchAccount.trimmingCharacters(in: .whitespaces)
        let password  = launchPassword
        let character = launchCharacter.trimmingCharacters(in: .whitespaces)
        let game      = launchGameCode

        guard !account.isEmpty, !password.isEmpty, !character.isEmpty else { return }

        showingConnect = false

        let ruby = Self.resolveRubyPath()

        client.clearFailure()

        // Find the Lich folder. Auto-detected installs (~/Lich5, ~/Gemstone)
        // and a previously-set folder connect silently; otherwise prompt the
        // user to locate it. Only a picked folder is persisted.
        let lichRoot: String
        if let resolved = LichLocation.resolvedRoot() {
            lichRoot = resolved
        } else if let picked = LichFolderPicker.prompt() {
            LichLocation.setRoot(picked)
            lichRoot = picked
        } else {
            client.reportFailure("Set your Lich folder to play (the folder that contains lich.rbw).")
            return
        }

        // sge_auth.rb ships in the app's resource bundle. Resolving it from the
        // bundle rather than a hardcoded checkout path lets the app run on any Mac.
        guard let script = Bundle.module.url(forResource: "sge_auth", withExtension: "rb")?.path else {
            client.reportFailure("Couldn't find the bundled login helper (sge_auth.rb).")
            return
        }

        let creds: GameCredentials
        do {
            creds = try await SgeAuth.authenticate(
                rubyPath: ruby,
                scriptPath: script,
                lichDir: lichRoot,
                account: account,
                password: password,
                character: character,
                gameCode: game
            )
        } catch {
            client.reportFailure(error.localizedDescription)
            return
        }

        onAuthenticated(ConnectAuthResult(
            account: account,
            password: password,
            character: character,
            gameCode: game,
            rememberCredentials: rememberCredentials,
            serverCreds: creds,
            rubyPath: ruby,
            lichRoot: lichRoot
        ))
    }

    /// Finds a Ruby interpreter to run the SGE helper and lich.rbw under.
    /// Prefers rbenv (developer environments) → Homebrew → /usr/local →
    /// /usr/bin fallback. Returns /usr/bin/ruby unconditionally as a last
    /// resort so the caller always has something to invoke.
    static func resolveRubyPath() -> String {
        let candidates = [
            NSString(string: "~/.rbenv/shims/ruby").expandingTildeInPath,
            "/opt/homebrew/bin/ruby",
            "/usr/local/bin/ruby",
            "/usr/bin/ruby"
        ]
        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
        return "/usr/bin/ruby"
    }
}
