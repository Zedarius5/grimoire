import Testing
@testable import GrimoireKit

@Suite("Tokenizer")
struct TokenizerTests {

    @Test("plain text → single .text token")
    func plainText() {
        #expect(Tokenizer.tokenize("hello world") == [.text("hello world")])
    }

    @Test("empty input → no tokens")
    func empty() {
        #expect(Tokenizer.tokenize("") == [])
    }

    @Test("self-closing tag with single-quoted attribute")
    func selfClosingSingleQuoted() {
        #expect(Tokenizer.tokenize("<roundTime value='5'/>") == [
            .openTag(name: "roundTime", attributes: ["value": "5"], selfClosing: true)
        ])
    }

    @Test("self-closing tag with double-quoted attribute")
    func selfClosingDoubleQuoted() {
        #expect(Tokenizer.tokenize("<roundTime value=\"5\"/>") == [
            .openTag(name: "roundTime", attributes: ["value": "5"], selfClosing: true)
        ])
    }

    @Test("open + close around text")
    func openCloseAroundText() {
        #expect(Tokenizer.tokenize("<b>bold</b>") == [
            .openTag(name: "b", attributes: [:], selfClosing: false),
            .text("bold"),
            .closeTag(name: "b"),
        ])
    }

    @Test("named entity ref")
    func namedEntity() {
        #expect(Tokenizer.tokenize("&amp;") == [.entityRef("amp")])
    }

    @Test("decimal char ref")
    func decimalCharRef() {
        #expect(Tokenizer.tokenize("&#65;") == [.charRef(65)])
    }

    @Test("hex char ref")
    func hexCharRef() {
        #expect(Tokenizer.tokenize("&#x41;") == [.charRef(0x41)])
    }

    @Test("stray ampersand is literal text")
    func strayAmpersand() {
        #expect(Tokenizer.tokenize("salt & pepper") == [.text("salt & pepper")])
    }

    @Test("comment is skipped")
    func commentSkipped() {
        #expect(Tokenizer.tokenize("before<!--ignored-->after") == [
            .text("before"),
            .text("after"),
        ])
    }

    @Test("multiple attributes")
    func multipleAttributes() {
        let tokens = Tokenizer.tokenize("<a exist='123' noun='sword'>blade</a>")
        #expect(tokens == [
            .openTag(name: "a", attributes: ["exist": "123", "noun": "sword"], selfClosing: false),
            .text("blade"),
            .closeTag(name: "a"),
        ])
    }

    @Test("unquoted attribute value")
    func unquotedAttribute() {
        #expect(Tokenizer.tokenize("<x a=1/>") == [
            .openTag(name: "x", attributes: ["a": "1"], selfClosing: true)
        ])
    }

    @Test("realistic stream push + body")
    func streamPushBody() {
        let tokens = Tokenizer.tokenize("<pushStream id='thoughts'/>You hear someone think...")
        #expect(tokens == [
            .openTag(name: "pushStream", attributes: ["id": "thoughts"], selfClosing: true),
            .text("You hear someone think..."),
        ])
    }

    @Test("multiple sibling tags with interleaved text")
    func interleavedSiblings() {
        let line = "<style id='roomName'/>[The Crossing]<style id=''/> some text"
        let tokens = Tokenizer.tokenize(line)
        #expect(tokens == [
            .openTag(name: "style", attributes: ["id": "roomName"], selfClosing: true),
            .text("[The Crossing]"),
            .openTag(name: "style", attributes: ["id": ""], selfClosing: true),
            .text(" some text"),
        ])
    }
}
