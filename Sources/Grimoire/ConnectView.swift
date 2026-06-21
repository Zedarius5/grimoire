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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Play").font(.headline)

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
    }

    private func authenticate() async {
        let account   = launchAccount.trimmingCharacters(in: .whitespaces)
        let password  = launchPassword
        let character = launchCharacter.trimmingCharacters(in: .whitespaces)
        let game      = launchGameCode

        guard !account.isEmpty, !password.isEmpty, !character.isEmpty else { return }

        showingConnect = false

        let ruby     = Self.resolveRubyPath()
        let lichDir  = NSString(string: "~/Gemstone").expandingTildeInPath

        client.clearFailure()

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
                lichDir: lichDir,
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
            rubyPath: ruby
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
