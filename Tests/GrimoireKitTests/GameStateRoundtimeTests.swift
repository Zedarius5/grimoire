import Testing
import Foundation
@testable import GrimoireKit

/// Roundtime countdown must be computed against the SERVER's clock (anchored
/// from `<prompt time=…>`), not the local machine clock. The game sends
/// roundtime as an absolute server-clock timestamp; if the server's clock is
/// skewed from the local one, comparing against the local clock makes every
/// RT look already-expired (the "no bricks" bug). `serverClockOffset` cancels
/// that skew.
@Suite("GameState.secondsRemaining")
struct GameStateRoundtimeTests {

    @Test("nil end -> 0")
    func nilEnd() {
        let s = GameState()
        #expect(s.secondsRemaining(until: nil, localNow: 1_000) == 0)
    }

    @Test("no skew: counts down, clamps past to 0")
    func noSkew() {
        var s = GameState()
        s.serverClockOffset = 0
        #expect(s.secondsRemaining(until: 1_005, localNow: 1_000) == 5)
        #expect(s.secondsRemaining(until: 995,  localNow: 1_000) == 0)
    }

    @Test("server clock behind local: offset cancels the skew (the bug)")
    func serverBehind() {
        var s = GameState()
        s.serverClockOffset = -85   // server is 85s behind local
        let localNow: TimeInterval = 1_000_000
        // A real 5s RT: the server says it ends at serverNow + 5
        // = (localNow - 85) + 5 = localNow - 80. Comparing against the local
        // clock that reads as 80s expired; with the offset it's a correct 5s.
        let end = (localNow - 85) + 5
        #expect(s.secondsRemaining(until: end, localNow: localNow) == 5)
    }

    @Test("server clock ahead of local")
    func serverAhead() {
        var s = GameState()
        s.serverClockOffset = 40
        let localNow: TimeInterval = 1_000_000
        let end = (localNow + 40) + 3
        #expect(s.secondsRemaining(until: end, localNow: localNow) == 3)
    }
}
