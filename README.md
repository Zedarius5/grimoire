# Grimoire

A native **macOS** front-end for **GemStone IV** (and DragonRealms), built on top of
[Lich](https://gswiki.play.net/Lich). Grimoire connects through your local Lich
install and renders the game with a Mac-native UI — highlights, spell timers, a
wound diagram, customizable panes, and a few tools you won't find in the other
clients.

> ⚠️ Independent, community-made client. **Not affiliated with or endorsed by
> Simutronics.** GemStone IV and DragonRealms are trademarks of Simutronics Corp.

<!-- TODO: add a screenshot here -->

## Features

### Things that set it apart

- **Truly native macOS app** — SwiftUI/AppKit, not a Windows app or a
  cross-platform JVM port. Dark theme, proper Find bar, native notifications.
- **Log viewer with your *live* highlights applied** — open any old log and it
  re-colors it with your current highlight rules, plus toggle-on/off noise
  filters (hide thoughts, experience, INFO, room descriptions, combat math,
  songs, logon/death spam, and more). Great for reviewing a hunt or finding
  that one line.
- **Huge built-in crit/damage highlight library** — every elemental damage type
  with a two-tier treatment: a tint for ordinary damage and the full treatment
  for *fatal* blows, built from the wiki's crit tables.
- **Per-spell bar height in the spell timers** — make your can't-let-it-drop
  spells physically bigger so they're impossible to miss at a glance.
- **Handles enormous highlight sets smoothly** — a fast pre-filter under the
  hood keeps 900+ highlight rules from lagging your typing.
- **macOS notifications on flagged highlights** — mark a rule "notify" and
  matching lines pop a real Notification Center alert (search your rules by
  `tag:notify`).
- **Mac-citizen niceties** — stays *out* of the macOS Games / "Now Playing"
  overlay, shuts down gracefully (tells Lich to save before it exits), and
  confirms or blocks any web link the game tries to open.

### Front-end essentials

- Login picker with SGE auth and credentials stored in the macOS Keychain
  (GS3 / GSX / GSF / GST and the DragonRealms variants).
- Drag-and-drop resizable panes — lay the window out how you like.
- Vitals, hands, a visual **body/wound diagram**, and an **exits compass**.
- Server-driven **right-click context menus** on items and creatures, plus
  clickable links and directions.
- Macros (with timed pauses), spell presets, and a spell-name database pulled
  from Lich.
- Status-effect icons, log rotation, and a stuck-stream watchdog.

## Requirements

- **macOS 15 (Sequoia) or later**
- A working **[Lich](https://gswiki.play.net/Lich)** install (default location
  `~/Gemstone`), including Ruby and Lich's required gems. If `lich.rbw` runs for
  you from Terminal, you're set.
- A **GemStone IV** or **DragonRealms** account.

## Install

### Option A — download (recommended)

1. Grab the latest `Grimoire-<version>.zip` from the
   [Releases](https://github.com/Zedarius5/grimoire/releases) page.
2. Unzip and drag **Grimoire.app** into `/Applications`.
3. Launch it. Release builds are notarized, so it opens without Gatekeeper
   warnings.

### Option B — build from source

Requires the Xcode command-line tools (Swift 6).

```bash
git clone https://github.com/Zedarius5/grimoire.git
cd grimoire
swift build            # quick compile check
./scripts/build-app.sh # assembles + signs Grimoire.app, installs it, launches
```

`build-app.sh` flags (all optional):

| Variable     | Default | Effect                                              |
|--------------|---------|-----------------------------------------------------|
| `CONFIG`     | `debug` | `release` for an optimized build                    |
| `INSTALL`    | `1`     | `0` to leave the app in `build/` instead of installing |
| `LAUNCH`     | `1`     | `0` to skip launching after the build               |

```bash
# Build a release app without installing or launching:
CONFIG=release INSTALL=0 LAUNCH=0 ./scripts/build-app.sh
```

## First run

1. Make sure Lich is installed at `~/Gemstone` (this is currently assumed; a
   configurable folder is on the roadmap).
2. Open Grimoire and use the **Play** dialog: enter your account, password, and
   character, and pick your game (GemStone IV by default).
3. Check **"Remember on this Mac"** to save the password to your Keychain for
   next time.

Grimoire authenticates with Simutronics, then launches Lich and connects to it
for you.

## Your credentials & safety

- Your password is stored in the **macOS Keychain**, never in plain text on disk
  and never in this repo.
- It's handed to the login helper over **stdin**, so it never appears in the
  process list (`ps`) where other local programs could read it.
- Any link the game asks to open is **confirmed first** for normal web
  (http/https) links — showing you the full URL — and **blocked** for anything
  else (e.g. `file://` or custom app schemes), since the game stream is only
  semi-trusted.

## Development

```bash
swift build      # compile
swift test       # run the test suite
```

The code is split into a `GrimoireKit` library (parsing, protocol, classifiers
— unit-tested) and a `Grimoire` SwiftUI app target.

## Releasing (maintainers)

Release builds are signed and notarized for distribution outside the App Store.
You need a paid Apple Developer Program account with a **Developer ID
Application** certificate, plus a stored `notarytool` credential profile:

```bash
xcrun notarytool store-credentials "grimoire-notary" \
  --apple-id "you@example.com" --team-id "TEAMID" --password "app-specific-pw"
# (or --key/--key-id/--issuer for an App Store Connect API key)
```

Then:

```bash
CONFIG=release NOTARIZE=1 ./scripts/build-app.sh
```

This signs with your Developer ID, submits to Apple's notary service, staples
the ticket, and writes a shareable `build/dist/Grimoire-<version>.zip`. Set the
version with a git tag first (e.g. `git tag v0.1.0`).

## Credits

- **[Lich](https://gswiki.play.net/Lich)** — the engine Grimoire is a front-end
  for.
- Status-effect icons from **[game-icons.net](https://game-icons.net)**, used
  under [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/).
- Crit-table highlight data adapted from **[GSWiki](https://gswiki.play.net)**.

## License

[GPL-3.0-or-later](LICENSE) — copyleft, so Grimoire and any derivatives stay
open source. Copyright © 2026 Danny Olefsky.
