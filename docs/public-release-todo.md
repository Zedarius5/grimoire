# Public-release TODO

Tracking the path to a clean, safe, "anyone can use it" Grimoire on public
GitHub. Checked items are done.

## Done

**Security / safety**
- [x] **Bundle the SGE login helper.** `sge_auth.rb` lives in
  `Sources/Grimoire/Resources/` and resolves at runtime via `Bundle.module`,
  not a hardcoded checkout path — so the app runs on any Mac.
- [x] **Password off the process table.** `sge_auth.rb` reads the password
  from stdin; `SgeAuth.swift` writes it to the child's stdin (no longer an
  argv argument visible to local `ps`).
- [x] **Guard externally-opened URLs.** Server-pushed `<LaunchURL>` and
  clicked `<a href>` links route through `SafeExternalURL`: http/https links
  prompt for confirmation (full URL shown); other schemes are blocked.

**Repo / legal**
- [x] **GPL-3.0-or-later `LICENSE`** (canonical text) added.
- [x] **README** added (features, requirements, install, first-run,
  credentials/safety, dev + notarization recipe).
- [x] **Stop tracking personal/internal files.** Highlight backups and
  internal notes are gitignored; `.claude/` removed from the repo and
  gitignored too.
- [x] **GemStone IV only.** DragonRealms options/mentions removed (untested,
  unsupported).

**Distribution**
- [x] Code signing wired in `scripts/build-app.sh` (auto-detects the
  Developer ID cert, hardened runtime).
- [x] **Notarization wired.** `NOTARIZE=1 ./scripts/build-app.sh` signs →
  submits to Apple → staples → emits `build/dist/Grimoire-<version>.zip`.
  Developer ID cert + `notarytool` keychain profile (`grimoire-notary`) are
  set up.

**Two-remote git model**
- [x] `origin` = gitea (private) holds everything: `main` + a `private`
  overlay branch with the personal files. `github` = `main` only.
- [x] `.git/hooks/pre-push` blocks personal paths / `.claude/` from reaching
  GitHub (tested).
- [x] GitHub repo created (`Zedarius5/grimoire`, **private for staging**);
  `main` pushed.

**Code quality**
- [x] Removed dev-only tools (Icon Browser, Wounds debug).
- [x] Log viewer shipped (marked **beta** in-UI).
- [x] Fixed the macro-set delete crash (id-keyed mutations).
- [x] Trimmed verbose/war-story comments across the codebase for public view.

## Remaining before launch

- [ ] **Flip the GitHub repo to Public** (Settings → change visibility) once
  you've browsed the staged repo.
- [ ] **README polish:** add a screenshot (there's a `<!-- TODO -->` near the
  top); confirm the Lich link (`gswiki.play.net/Lich`).
- [ ] **Cut the first release:** `git tag v0.1.0` →
  `CONFIG=release NOTARIZE=1 ./scripts/build-app.sh` → attach
  `build/dist/Grimoire-0.1.0.zip` to a GitHub Release.

## Roadmap (post-launch / nice-to-have)

**Default settings for a fresh install**
- [ ] **Ship the damage/crit highlight groups as defaults.** Extract *just*
  those groups (Fire/Cold/Impact/Electric + all 15 damage types, damage vs.
  fatal tiers) into a bundled `default-highlights.json`, and have
  `HighlightStore` load it on first run when no user config exists. Must NOT
  include personal/non-crit rules.
- [ ] Decide defaults for: pane layout, which log-viewer categories are on,
  notification behavior, fonts/sizes.
- [ ] First-run experience: seed defaults and (optionally) a short
  "welcome / point me at your Lich folder" step.

**Configurable Lich / Gemstone folder**

`~/Gemstone` is currently assumed. Let users point at their own install
(first-run prompt or a Settings field, defaulting to `~/Gemstone`). Spots to
plumb a single user-set path through:
- `Sources/Grimoire/ConnectView.swift` — `lichDir` for SGE auth.
- `Sources/Grimoire/ContentView.swift` — `lichDir` + `lich.rbw` launch path.
- `Sources/GrimoireKit/SgeAuth.swift` — `LICH_DIR` env passed to the helper.
- `Sources/GrimoireKit/SpellNameDatabase.swift` — `defaultPath`
  (`~/Gemstone/data/effect-list.xml`).
- `Sources/Grimoire/SpellPresetStore.swift` / `SpellPresetEditorView.swift`
  — effect-list cache references.
- `Sources/Grimoire/LogViewer.swift` — Open-Log default directory.
- Bundled `sge_auth.rb` already honors the `LICH_DIR` env (good).

**Optional hardening**
- [ ] A per-window "don't ask again for `*.play.net` links" memory so the
  LaunchURL confirmation isn't repetitive for trusted SIMUCOIN/GOAL
  redirects.
