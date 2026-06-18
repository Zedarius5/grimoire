# Log Viewer — design

_2026-06-18_

## Purpose

Open an old GemStone log file inside Grimoire and read it back with the
user's current highlight rules applied, plus live toggles to hide the
categories that normally get split into other windows (thoughts,
experience, INFO) so the main flow isn't cluttered.

## Key constraint discovered

The Lich logs (`~/Gemstone/logs/GSIV-<char>/YYYY/MM/*.log`) are ~96%
clean game text. They carry styling tags (`<pushBold>`, `<output
class>`, `<preset>`, `<prompt>`) but **no stream-routing tags**
(`pushStream`/`popStream`/`component` are absent). So lines cannot be
classified by where the game routed them; classification must be
**heuristic pattern-matching**. This is good for the recognizable
categories below and best-effort on oddballs — an accepted tradeoff.

## Behavior

- **Entry:** `File ▸ Open Log…` opens an `NSOpenPanel` defaulting to
  `~/Gemstone/logs` (falls back to home if absent), `.log`/`.txt`
  allowed. Each chosen file opens its **own** read-only viewer window
  titled with the filename. Multiple logs can be open at once.
- **Viewer:** read-only, selectable/copyable `NSTextView` in a scroll
  view. **Starts at the top.** Native Find bar (⌘F). A row of category
  toggles across the top.
- **Categories** (each a checkbox; flipping re-filters instantly):
  - `thoughts` — channel/ESP chat, e.g. `[Merchant] Drewkin: "…"`.
    **Hidden by default.**
  - `experience` — EXP readouts/blocks. **Hidden by default.**
  - `info` — INFO/stat blocks. **Hidden by default.**
  - `script` — Lich lifecycle (`--- …`) and script status
    (`[scriptname: …]`). **Shown by default** (user wants these kept).
  - `game` — everything unmatched. **Always shown, no toggle.**
- **Highlights:** the user's current `effectiveHighlights` are snapshot
  when the window opens and applied on top of whatever's visible. (Edit
  rules → reopen the log to re-snapshot.)
- **Styling:** `<tags>` are parsed through the same path the live story
  feed uses so presets/bold render like the game.

## Components (boundaries)

1. **`LogCategory`** (GrimoireKit) — enum: `.thoughts`, `.experience`,
   `.info`, `.script`, `.game`.
2. **`LogClassifier`** (GrimoireKit, pure, unit-tested) —
   `static func category(of line: String) -> LogCategory`. Regex/prefix
   rules:
   - `script`: line starts with `--- ` OR matches `^\[[a-z][\w]*: `.
   - `thoughts`: matches `^\[[A-Za-z][\w'’ -]*\] .+?: ` (channel + speaker).
   - `experience`: contains one of the EXP labels (`Experience:`,
     `Field Exp:`, `Ascension Exp:`, `Total Exp:`, `Long-Term Exp:`,
     `Death's Sting:`, `Deeds:`) OR matches the inline `Exp:\s*[\d,]+`
     readout.
   - `info`: matches stat-block lines (`^\s*Level: .*Fame:`,
     `\(STR\)|\(CON\)|\(DEX\)|…`, `Name:.*Race:`).
   - else `.game`.
   Evaluate in this fixed order, first match wins: **script → thoughts
   → experience → info → game.** (Script before thoughts because both
   start with `[`: script is `[name: …]` with the colon inside the
   brackets; thoughts is `[Channel] speaker: …` with the bracket
   closing first.) Classification is per-line; multi-line EXP/INFO
   blocks are covered because each of their lines carries a distinctive
   label.
3. **`LogParser`** (GrimoireKit) —
   `static func parse(_ text: String) -> [LogLine]` where
   `LogLine = (line: RenderedLine, category: LogCategory)`. Splits into
   lines, renders tags via the shared story-feed tag parser, classifies
   each. (Implementation note: reuse `StreamRenderer` if it can be
   driven from file text; otherwise a thin tag parser handling the tags
   that actually occur in logs — `pushBold`→bold, `preset`→styled,
   strip `prompt`/`streamWindow`/`clearStream` — same visual result.)
4. **`LogViewerModel`** (app, `@MainActor`) — holds `[LogLine]`, a
   `Set<LogCategory>` of visible categories (default: all except
   thoughts/experience/info), and the highlight snapshot. Exposes the
   currently-visible `[RenderedLine]`.
5. **`LogTextView`** (app, `NSViewRepresentable`) — read-only top-
   anchored `NSTextView`; builds one `NSAttributedString` from the
   visible lines via the existing `appendLine` builder +
   `HighlightProcessor.apply`. Find bar enabled. Rebuilds on
   visible-set change.
6. **`LogViewerView` + window** (app) — toggle row + `LogTextView`.
7. **Menu command** (app, `GrimoireApp`) — `File ▸ Open Log…`, open
   panel, spawn a viewer window per file.

## Data flow

`Open Log…` → URL → `LogParser.parse(text)` → `[LogLine]` →
`LogViewerModel` (filter by visible categories) → `LogTextView`
(apply highlight snapshot, build attributed string) → display at top.
Toggling a category updates the visible set → model recomputes visible
lines → text view rebuilds.

## Error handling

- Unreadable/oversized-to-read file → alert, no window.
- Nothing visible after parse/filter → in-view message ("No lines in
  the shown categories").
- **Large files:** cap at 100,000 parsed lines; if exceeded, keep the
  last 100k and show a one-line banner ("showing last 100,000 lines").
  Prevents UI hangs on multi-MB logs.
- Rebuild cost: re-render on toggle is O(visible lines); acceptable at
  the cap. No incremental reconcile (unlike the live feed).

## Testing

- `LogClassifier.category(of:)` — unit tests per category, including
  the tricky cases verified against real logs: `[Merchant] X: "…"` →
  thoughts; `[Abbey, Courtyard]` and `[+25 Sigil Staff bonus == 303]`
  → game (NOT script/thoughts); `--- Lich: eloot active.` and
  `[animate_refresher: …]` → script; `Experience: 12,072,241` and the
  inline `Exp: N  Field: N/N` → experience; `Level: 100  Fame:` → info.
- `LogParser.parse` — tags stripped/rendered, entities decoded,
  blank lines handled, category attached.
- `HighlightProcessor` already covered.

## Out of scope (YAGNI)

- Editing highlights from the viewer (snapshot only).
- Full live-feed fidelity (monsterbold/links the log never recorded).
- Search/filter beyond native Find + category toggles.
- Saving filtered output (could be a later "export" follow-up).
