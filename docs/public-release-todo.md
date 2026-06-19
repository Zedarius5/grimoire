# Public-release TODO

Tracking what's left before Grimoire is a clean, safe, "anyone can use it"
project on public GitHub. Grouped by theme. Checked items are done.

## Done (this pass)

- [x] **Bundle the SGE login helper.** `sge_auth.rb` now lives in
  `Sources/Grimoire/Resources/` and is resolved at runtime via
  `Bundle.module` instead of a hardcoded `~/Documents/Repositories/...`
  path. The app no longer depends on the developer's checkout location.
- [x] **Keep the account password out of the process table.** `sge_auth.rb`
  reads the password from stdin; `SgeAuth.swift` writes it to the child's
  stdin and closes the pipe (was previously passed as an argv argument,
  visible to local `ps`).
- [x] **Guard externally-opened URLs.** Server-pushed `<LaunchURL>` and
  clicked `<a href>` links now route through `SafeExternalURL`: http/https
  links prompt for confirmation (showing the full URL); any other scheme
  (file://, custom app schemes, javascript:, …) is blocked with an
  explanation.
- [x] **Stop tracking personal/internal files.** Personal highlight backups
  and internal working notes are gitignored (see `.gitignore`).

## Default settings for a fresh install (define these)

New users start with empty/neutral config. Decide what ships by default:

- [ ] **Ship the damage/crit highlight groups as defaults.** The crit work
  (Fire/Cold/Impact/Electric + all 15 damage types, damage vs. fatal
  tiers) is worth keeping for everyone. Plan: extract *just* those groups
  from the personal backup into a bundled `default-highlights.json`
  resource, and have `HighlightStore` load it on first run when no user
  config exists. Must NOT include personal/non-crit rules.
- [ ] Decide defaults for: pane layout, which log-viewer categories are on,
  notification behavior, fonts/sizes.
- [ ] First-run experience: when there's no saved config, seed defaults and
  (optionally) show a short "welcome / point me at your Lich folder" step.

## Configurable Lich / Gemstone folder

Right now `~/Gemstone` is assumed in several places. Let users point at their
own install (first-run prompt, or a Settings field, with `~/Gemstone` as the
default). Spots to plumb a single user-set path through:

- `Sources/Grimoire/ConnectView.swift` — `lichDir` for SGE auth.
- `Sources/Grimoire/ContentView.swift` — `lichDir` + `lich.rbw` launch path.
- `Sources/GrimoireKit/SgeAuth.swift` — `LICH_DIR` env passed to the helper.
- `Sources/GrimoireKit/SpellNameDatabase.swift` — `defaultPath`
  (`~/Gemstone/data/effect-list.xml`).
- `Sources/Grimoire/SpellPresetStore.swift` / `SpellPresetEditorView.swift`
  — effect-list cache references.
- `Sources/Grimoire/LogViewer.swift` — Open-Log default directory
  (`~/Gemstone/logs`).
- `scripts`/bundled `sge_auth.rb` — already honors `LICH_DIR` env (good).

## Distribution (so people can download a prebuilt app)

- [x] Code signing is already wired in `scripts/build-app.sh` (auto-detects an
  Apple Development / Developer ID Application cert, signs with
  `--options runtime`).
- [ ] **Notarize + staple** so downloaders don't hit Gatekeeper's
  "unidentified developer" wall. Needs: a **Developer ID Application**
  cert (not just "Apple Development"), plus either an app-specific password
  or an App Store Connect API key for `notarytool`. Add a `NOTARIZE=1` path
  to `build-app.sh`:
  `xcrun notarytool submit build/Grimoire.app.zip --keychain-profile <p> --wait`
  then `xcrun stapler staple build/Grimoire.app`.
  (Building from source needs none of this — only distributing a prebuilt
  `.app` does.)

## Repo hygiene / legal

- [ ] **Add a LICENSE** (e.g. MIT). Without one, public code is
  all-rights-reserved by default and nobody may legally use it.
- [ ] **Add a README**: what Grimoire is, that it needs Lich installed at
  `~/Gemstone` (or the configured folder) with the required Ruby gems, the
  game-code picker, build/run instructions, and the Gatekeeper note for the
  prebuilt app.
- [ ] Decide whether `.claude/settings.json` (innocuous tooling allowlist)
  stays tracked — currently kept; nothing personal in it.

## Security follow-ups (optional hardening)

- [ ] Consider a per-window "don't ask again for play.net links" memory so
  the LaunchURL confirmation isn't repetitive for trusted SIMUCOIN/GOAL
  redirects (scoped to `*.play.net` only).
