import Testing
import Foundation
@testable import GrimoireKit

@Suite("LinkRef.clickURL")
struct LinkRefClickURLTests {

    // MARK: - href (always-wins)

    @Test("href wins over every other field")
    func hrefBeatsEverything() {
        let link = LinkRef(
            exist: "42",
            noun: "thing",
            kind: .entity,
            coord: "c1",
            href: "https://play.net/goal",
            cmd: "look thing"
        )
        let url = link.clickURL(fallbackText: "click me")
        #expect(url?.host == "href")
        #expect(url?.query?.contains("url=https") == true)
    }

    // MARK: - cmd verbatim

    @Test("`<d cmd='gem equip 1'>` produces grimoire://cmd?value=...")
    func cmdAttributeRoutesAsVerbatim() {
        let link = LinkRef(exist: "", noun: nil, kind: .direction, cmd: "gem equip 1")
        let url = link.clickURL()
        #expect(url?.host == "cmd")
        #expect(url?.query?.contains("value=gem%20equip%201") == true)
    }

    @Test("cmd takes precedence over exist/noun on the same tag")
    func cmdBeatsExistAndNoun() {
        let link = LinkRef(exist: "42", noun: "X", kind: .direction, cmd: "go east")
        let url = link.clickURL()
        #expect(url?.host == "cmd")
        #expect(url?.query?.contains("value=go%20east") == true)
    }

    // MARK: - Bare <d>VERB</d> fallback to visible text

    @Test("Bare <d>VERB</d>: fallbackText routes to cmd")
    func bareDirectionUsesFallbackText() {
        let link = LinkRef(exist: "", noun: nil, kind: .direction)
        let url = link.clickURL(fallbackText: "ASCENSION LEARN CONFIRM")
        #expect(url?.host == "cmd")
        #expect(url?.query?.contains("value=ASCENSION") == true)
    }

    @Test("fallbackText is trimmed of surrounding whitespace")
    func fallbackTextIsTrimmed() {
        let link = LinkRef(exist: "", noun: nil, kind: .direction)
        let url = link.clickURL(fallbackText: "  STOW  ")
        #expect(url?.query?.contains("value=STOW") == true)
        #expect(url?.query?.contains("value=%20") == false)  // no leading space
    }

    @Test("Empty fallbackText is ignored")
    func emptyFallbackTextIgnored() {
        let link = LinkRef(exist: "", noun: nil, kind: .direction)
        let url = link.clickURL(fallbackText: "   ")
        #expect(url == nil)  // nothing actionable
    }

    @Test("Entity-kind links do NOT use fallbackText as cmd")
    func entityKindIgnoresFallbackText() {
        // Critical: prevents sending an entity description like
        // "pink-nosed grey and white kitten" as a literal command.
        let link = LinkRef(exist: "42", noun: "kitten", kind: .entity)
        let url = link.clickURL(fallbackText: "pink-nosed grey and white kitten")
        #expect(url?.host == "cli")  // entity path, not cmd
    }

    // MARK: - Entity (cli) path

    @Test("Entity link with coord+exist+noun encodes all three")
    func entityEncodesAllFields() {
        let link = LinkRef(exist: "42", noun: "sword", kind: .entity, coord: "c1")
        let url = link.clickURL()
        #expect(url?.host == "cli")
        let q = url?.query ?? ""
        #expect(q.contains("coord=c1"))
        #expect(q.contains("exist=42"))
        #expect(q.contains("noun=sword"))
    }

    @Test("Entity link with only exist still produces a URL")
    func entityWithOnlyExist() {
        let link = LinkRef(exist: "42", noun: nil, kind: .entity)
        let url = link.clickURL()
        #expect(url?.host == "cli")
        #expect(url?.query?.contains("exist=42") == true)
    }

    @Test("Entity link with nothing returns nil")
    func entityWithNothing() {
        let link = LinkRef(exist: "", noun: nil, kind: .entity)
        #expect(link.clickURL() == nil)
    }

    // MARK: - Direction (dir) path

    @Test("Direction link with exist routes as dir?value=exist")
    func directionWithExist() {
        let link = LinkRef(exist: "north", noun: nil, kind: .direction)
        let url = link.clickURL()
        #expect(url?.host == "dir")
        #expect(url?.query?.contains("value=north") == true)
    }

    @Test("Direction link with only noun falls back to noun as value")
    func directionWithOnlyNoun() {
        let link = LinkRef(exist: "", noun: "out", kind: .direction)
        let url = link.clickURL()
        #expect(url?.host == "dir")
        #expect(url?.query?.contains("value=out") == true)
    }

    @Test("Direction link with no exist, noun, cmd, or fallbackText returns nil")
    func directionWithNothing() {
        let link = LinkRef(exist: "", noun: nil, kind: .direction)
        #expect(link.clickURL() == nil)
    }
}
