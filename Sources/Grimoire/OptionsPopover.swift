import SwiftUI
import GrimoireKit

/// Settings popover anchored to the toolbar's Options button. Owns the
/// macro-import file-picker state, the timer-bar window configuration, and
/// the macro-set picker. All settings persist via `@AppStorage`, so
/// ContentView's parallel `@AppStorage` declarations stay in sync without
/// any explicit plumbing.
struct OptionsPopover: View {
    @Binding var fontSize: Double
    /// Used to dismiss self when the user clicks "Open editor…" so the
    /// editor window doesn't open behind the popover.
    @Binding var showingOptions: Bool

    @EnvironmentObject var macros: MacroEngine
    @EnvironmentObject var highlights: HighlightStore
    @Environment(\.openWindow) private var openWindow

    @AppStorage("grimoire.macroThreshold") private var macroThreshold: Int = 3
    // The same five timer-bar keys are observed by ContentView for its
    // per-dialog `timerConfig(for:)` lookup. Writes here propagate via
    // UserDefaults; ContentView re-renders its panes automatically.
    @AppStorage("grimoire.timerBars.normalize")            private var timerBarsNormalize: Bool = true
    @AppStorage("grimoire.timerBars.window.activeSpells")  private var timerWindowActiveSpells: Int = 1800
    @AppStorage("grimoire.timerBars.window.buffs")         private var timerWindowBuffs: Int = 1800
    @AppStorage("grimoire.timerBars.window.cooldowns")     private var timerWindowCooldowns: Int = 1800
    @AppStorage("grimoire.timerBars.window.debuffs")       private var timerWindowDebuffs: Int = 180

    @State private var importingMacros: Bool = false
    @State private var macroError: String? = nil

    private enum TimerStepperUnit { case seconds, minutes }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Options").font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Font size")
                    Spacer()
                    Text("\(Int(fontSize))pt")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $fontSize, in: 9...28, step: 1)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Macros").font(.subheadline.bold())
                HStack {
                    Text("Repeat-command minimum length")
                    Spacer()
                    Stepper("\(macroThreshold)", value: $macroThreshold, in: 1...50)
                        .labelsHidden()
                    Text("\(macroThreshold)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, alignment: .trailing)
                }
                Text("Ctrl+Return repeats the most recent command at least this many characters long. Option+Return repeats the one before it.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                HStack {
                    Button("Import macros from XML…") { importingMacros = true }
                    Button("Open editor…") {
                        showingOptions = false
                        openWindow(id: "macros")
                    }
                    Spacer()
                    if !macros.config.sets.isEmpty {
                        Text("\(macros.config.sets.map(\.bindings.count).reduce(0, +)) bindings loaded")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if !macros.config.sets.isEmpty {
                    HStack {
                        Text("Active set")
                        Spacer()
                        Picker("", selection: $macros.config.activeSetId) {
                            ForEach(macros.config.sets) { set in
                                Text(set.name).tag(set.id)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 200)
                    }
                }
                if let macroError {
                    Text(macroError)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Timer bars").font(.subheadline.bold())
                Toggle("Normalize fill against a fixed time window", isOn: $timerBarsNormalize)
                Text("When off, bars use the server's reported value (Wrayth behavior: percentage of the spell's original duration).")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if timerBarsNormalize {
                    timerWindowRow(label: "Active Spells", minutes: $timerWindowActiveSpells, unit: .minutes)
                    timerWindowRow(label: "Buffs",         minutes: $timerWindowBuffs,        unit: .minutes)
                    timerWindowRow(label: "Cooldowns",     minutes: $timerWindowCooldowns,    unit: .minutes)
                    timerWindowRow(label: "Debuffs",       minutes: $timerWindowDebuffs,      unit: .seconds)
                    Text("Bars fill against this window. Spells with more remaining show a » overflow chevron.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Highlights").font(.subheadline.bold())
                HStack {
                    Button("Open editor…") {
                        showingOptions = false
                        openWindow(id: "highlights")
                    }
                    Spacer()
                    Text("\(highlights.highlights.count) rules loaded")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("Paint text spans (or whole lines) with custom fg/bg. Import Wrayth XML or build them in the editor.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(width: 400)
        .fileImporter(
            isPresented: $importingMacros,
            allowedContentTypes: [.xml, .data],
            allowsMultipleSelection: false
        ) { result in
            handleMacroImport(result)
        }
    }

    /// Renders one row of the Options "Timer bars" section — a label, a
    /// stepper, and a rendered "Nm" / "Ns" readout. `unit` controls whether
    /// the stored seconds value is stepped in 1-minute or 15-second increments.
    @ViewBuilder
    private func timerWindowRow(label: String, minutes: Binding<Int>, unit: TimerStepperUnit) -> some View {
        let step = (unit == .minutes) ? 60 : 15
        let range = (unit == .minutes) ? 60...7200 : 15...1800
        HStack {
            Text(label).frame(width: 110, alignment: .leading)
            Spacer()
            Stepper("", value: minutes, in: range, step: step)
                .labelsHidden()
            Text(format(seconds: minutes.wrappedValue))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
        }
    }

    private func format(seconds: Int) -> String {
        if seconds % 60 == 0 { return "\(seconds / 60)m" }
        if seconds < 60      { return "\(seconds)s" }
        return "\(seconds / 60)m \(seconds % 60)s"
    }

    private func handleMacroImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        do {
            let config = try MacroParser.parse(file: url)
            macros.install(config)
            Preferences.saveMacros(config)
            UserDefaults.standard.set(url.absoluteString, forKey: "grimoire.macroFile")
            macroError = nil
        } catch {
            macroError = error.localizedDescription
        }
    }
}
