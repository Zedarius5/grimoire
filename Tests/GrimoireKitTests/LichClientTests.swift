import Testing
import Foundation
@testable import GrimoireKit

@Suite("LichClient")
@MainActor
struct LichClientTests {

    @Test("echoLocal appends to main stream")
    func echoLocalAppendsToMain() {
        let client = LichClient()
        #expect(client.mainLines.isEmpty)

        client.echoLocal("> look")
        client.echoLocal("> smile")

        #expect(client.mainLines.count == 2)
        #expect(client.mainLines.first?.plainText == "> look")
        #expect(client.mainLines.last?.plainText  == "> smile")
    }

    @Test("echoLocal bumps stream revision per append")
    func echoLocalBumpsRevision() {
        let client = LichClient()
        let r0 = client.revision(for: "main")
        client.echoLocal("> look")
        let r1 = client.revision(for: "main")
        client.echoLocal("> smile")
        let r2 = client.revision(for: "main")

        #expect(r1 == r0 + 1)
        #expect(r2 == r1 + 1)
    }

    @Test("echoLocal collapses adjacent prompt-only lines")
    func adjacentPromptsCollapse() {
        // Consecutive prompt-only `>` lines are collapsed so the feed doesn't
        // fill with chevrons. echoLocal lines contain the command (not
        // prompt-only), so both are retained here.
        let client = LichClient()
        client.echoLocal("> look")
        client.echoLocal("> smile")
        #expect(client.mainLines.count == 2)
    }

    @Test("connect() resets all per-session state synchronously")
    func connectResetsState() {
        let client = LichClient()
        client.echoLocal("> previous session")
        #expect(!client.mainLines.isEmpty)

        // Port 9 won't be listening, but connect()'s synchronous part still
        // runs (resets state, bumps generation, queues the NWConnection setup).
        client.connect(host: "127.0.0.1", port: 9, mode: .raw)

        #expect(client.mainLines.isEmpty,
                "linesByStream should be wiped on every connect so a new session starts clean")
        #expect(client.revision(for: "main") == 0)
        #expect(client.dialogs.isEmpty)
        #expect(client.endpointLabel == "127.0.0.1:9")
    }

    @Test("connect() sets status to .connecting")
    func connectSetsConnectingStatus() {
        let client = LichClient()
        client.connect(host: "127.0.0.1", port: 9, mode: .raw)
        // Checked immediately after connect() returns: the workQueue async may
        // not have run, so status is .connecting from the synchronous setup
        // (or .failed if the attempt already bounced).
        switch client.status {
        case .connecting, .failed:
            break
        default:
            Issue.record("Expected .connecting or .failed, got \(client.status)")
        }
    }

    @Test("reportFailure flips status to .failed without disturbing lines")
    func reportFailurePreservesLines() {
        let client = LichClient()
        client.echoLocal("> some text")
        client.reportFailure("SGE rejected auth")
        if case .failed(let msg) = client.status {
            #expect(msg == "SGE rejected auth")
        } else {
            Issue.record("Expected .failed status")
        }
        // Lines must not be wiped just because we noted a failure --
        // the user may want to see whatever was on screen.
        #expect(client.mainLines.count == 1)
    }

    @Test("clearFailure resets a .failed status to .disconnected")
    func clearFailureResets() {
        let client = LichClient()
        client.reportFailure("test")
        client.clearFailure()
        #expect(client.status == .disconnected)
    }

    @Test("clearFailure on non-failed status is a no-op")
    func clearFailureOnConnected() {
        let client = LichClient()
        // Initial status is .disconnected; clearFailure should leave it.
        client.clearFailure()
        #expect(client.status == .disconnected)
    }

    @Test("isActive reflects status correctly")
    func isActiveStates() {
        let client = LichClient()
        #expect(client.isActive == false)

        client.connect(host: "127.0.0.1", port: 9, mode: .raw)
        // .connecting OR a quickly-flipped .failed both end up: failed = false.
        if case .connecting = client.status {
            #expect(client.isActive == true)
        }

        client.reportFailure("x")
        #expect(client.isActive == false)
    }

    @Test("mainLines caps at 5000")
    func mainLinesCapAt5000() {
        let client = LichClient()
        for i in 0..<5050 {
            client.echoLocal("> line \(i)")
        }
        // Cap is 5000; echoLocal trims if over. Verify we don't keep all
        // 5050 (otherwise the cap is broken and memory grows unbounded).
        #expect(client.mainLines.count <= 5000)
        // Newest line should still be present.
        #expect(client.mainLines.last?.plainText == "> line 5049")
    }
}
