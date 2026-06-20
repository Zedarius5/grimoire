import Testing
@testable import GrimoireKit

@Suite("LogClassifier")
struct LogClassifierTests {

    @Test("script: Lich lifecycle and script-status lines")
    func script() {
        #expect(LogClassifier.category(of: "--- Lich: eloot active.") == .script)
        #expect(LogClassifier.category(of: "--- diskhider: hiding non-group disks from your room view.") == .script)
        #expect(LogClassifier.category(of: "[animate_refresher: Current shadow essence: 3/5]") == .script)
        #expect(LogClassifier.category(of: "[ecaster: Type ;ec for options.]") == .script)
    }

    @Test("thoughts: channel chat")
    func thoughts() {
        #expect(LogClassifier.category(of: #"[Merchant] Drewkin: "Nothing to do?""#) == .thoughts)
        #expect(LogClassifier.category(of: #"[General] Zaaldine: "Or ya know...""#) == .thoughts)
    }

    @Test("experience: block labels and inline readout")
    func experience() {
        #expect(LogClassifier.category(of: "     Experience: 12,072,241             Field Exp: 433/1,434") == .experience)
        #expect(LogClassifier.category(of: "  Ascension Exp: 1,000,044          Recent Deaths: 0") == .experience)
        #expect(LogClassifier.category(of: "      Total Exp: 13,072,285         Death's Sting: None") == .experience)
        #expect(LogClassifier.category(of: "Exp:  12,078,173              Field: 1,593/1,434") == .experience)
    }

    @Test("info: stat block lines")
    func info() {
        #expect(LogClassifier.category(of: "          Level: 100                         Fame: 57,736,180") == .info)
        #expect(LogClassifier.category(of: "      Strength (STR):  100 (45)    ...") == .info)
        #expect(LogClassifier.category(of: "   Constitution (CON):  90 (40)   ...") == .info)
    }

    @Test("logon: default + Rumor Woods custom arrival/departure phrases")
    func logon() {
        #expect(LogClassifier.category(of: " * Stingbert joins the adventure.") == .logon)
        #expect(LogClassifier.category(of: " * Stingbert returns home from a hard day of adventuring.") == .logon)
        // custom catalog phrases (name + pronouns vary in-game):
        #expect(LogClassifier.category(of: "* Like a sudden winter squall, Zedarius materializes.") == .logon)
        #expect(LogClassifier.category(of: "* Raucous catcalls let you know that Bob has arrived.") == .logon)
        // overloaded ' * ' lines that are NOT logon:
        #expect(LogClassifier.category(of: "* Crimson Salt: Adding first liquid...") != .logon)
        #expect(LogClassifier.category(of: "* Flare Resonance (Rank 3 of 5)") != .logon)
        #expect(LogClassifier.category(of: "*** This is not a logon") != .logon)
    }

    @Test("death: Rumor Woods custom death broadcasts")
    func death() {
        #expect(LogClassifier.category(of: "Looks like time's run out for Sutayllyc.") == .death)
        #expect(LogClassifier.category(of: "Bob forgot he wasn't wearing plot armor.") == .death)   // pronoun varies
        #expect(LogClassifier.category(of: "Sigh.  Zedarius died again.") == .death)
        #expect(LogClassifier.category(of: "*CRASH*  *CLANG*  Sounds like Alice has been squished!") == .death)
        // not death:
        #expect(LogClassifier.category(of: "A grim gigas skald swings a war hammer at you!") != .death)
    }

    @Test("resource: RESOURCE command block")
    func resource() {
        #expect(LogClassifier.category(of: "Health: 225/225     Mana: 354/354     Stamina: 152/152     Spirit: 12/12") == .resource)
        #expect(LogClassifier.category(of: "Necrotic Energy: 50,000/50,000 (Weekly)     11,660/200,000 (Total)") == .resource)
        #expect(LogClassifier.category(of: "Suffused Necrotic Energy: 813") == .resource)
        #expect(LogClassifier.category(of: "Covert Arts Charges: 188/200") == .resource)
        #expect(LogClassifier.category(of: "Accumulated Shadow Essence: 5") == .resource)
    }

    @Test("resource/logon don't steal exp or info lines")
    func noCrossContamination() {
        #expect(LogClassifier.category(of: "     Experience: 12,072,241             Field Exp: 433/1,434") == .experience)
        #expect(LogClassifier.category(of: "          Level: 100                         Fame: 57,736,180") == .info)
    }

    @Test("script: broadened to command echoes and progress lines")
    func scriptBroad() {
        #expect(LogClassifier.category(of: "[go2]>west") == .script)
        #expect(LogClassifier.category(of: "[eloot]>loot #12345") == .script)
        #expect(LogClassifier.category(of: "[go2 ETA: 5 (3 rooms to move through)]") == .script)
        #expect(LogClassifier.category(of: "[exec2]>Broken pipe") == .script)
        // uppercase brackets are NOT script (room titles / combat / channels)
        #expect(LogClassifier.category(of: "[Abbey, Courtyard]") == .game)
        #expect(LogClassifier.category(of: "[General] Bob: \"hi\"") == .thoughts)
    }

    @Test("songs: medley spam")
    func songs() {
        #expect(LogClassifier.category(of: "You are currently singing:") == .songs)
        #expect(LogClassifier.category(of: "    (1009) Sonic Shield Song") == .songs)
        #expect(LogClassifier.category(of: "Your song magic remains strong.  It will be several minutes before your medley renews.  Your current renewal cost is 8 mana.") == .songs)
        #expect(LogClassifier.category(of: "Your medley has recently renewed, and it will be quite some time before the effects fade.") == .songs)
    }

    @Test("stance / command errors / disk / exits / combat")
    func miscToggles() {
        #expect(LogClassifier.category(of: "You are now in an offensive stance.") == .stance)
        #expect(LogClassifier.category(of: "You are now in a guarded stance.") == .stance)
        #expect(LogClassifier.category(of: "I could not find what you were referring to.") == .commandError)
        #expect(LogClassifier.category(of: "What were you trying to stow?") == .commandError)
        #expect(LogClassifier.category(of: "Please rephrase that command.") == .commandError)
        #expect(LogClassifier.category(of: "Your disk arrives, following you dutifully.") == .disk)
        #expect(LogClassifier.category(of: "Obvious paths: north, south, east.") == .exits)
        #expect(LogClassifier.category(of: "Obvious exits: out") == .exits)
        #expect(LogClassifier.category(of: "AS: +620 vs DS: +570 with AvD: +35 + d100 roll: +20 = +105") == .combat)
        #expect(LogClassifier.category(of: "Roundtime: 5 sec.") == .combat)
        #expect(LogClassifier.category(of: "[SMR result: 120 (Open d100: 80 Bonus: 40)]") == .combat)
    }

    @Test("experience: folded-in mind saturation, Wisdom of the Ages, TP lines")
    func expExtras() {
        #expect(LogClassifier.category(of: "Your mind is completely saturated.  It is imperative that you rest immediately!") == .experience)
        #expect(LogClassifier.category(of: "You have been experiencing the Wisdom of the Ages for 3 months.") == .experience)
        #expect(LogClassifier.category(of: "PTPs/MTPs: 12                        ATPs: 4") == .experience)
        #expect(LogClassifier.category(of: "Exp to next TP: 5000            Exp to next ATP: 9000") == .experience)
    }

    @Test("game: bracketed content that is NOT script or thoughts")
    func gameBrackets() {
        // Room names and bracketed game numbers must fall through to game.
        #expect(LogClassifier.category(of: "[Abbey, Courtyard]") == .game)
        #expect(LogClassifier.category(of: "[A Silent Path]") == .game)
        #expect(LogClassifier.category(of: "[+25 Sigil Staff bonus == 303]") == .game)
    }

    @Test("game: ordinary combat / room prose")
    func gameProse() {
        #expect(LogClassifier.category(of: "A grim gigas skald swings a war hammer at you!") == .game)
        #expect(LogClassifier.category(of: "Flames incinerate scalp completely and blacken skullcap.  Not very fashionable.") == .game)
    }

    @Test("every category has a non-empty label")
    func labels() {
        for c in LogCategory.allCases { #expect(!c.label.isEmpty) }
    }
}
