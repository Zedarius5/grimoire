import Foundation
import Network

/// Lightweight async helper that checks whether a TCP port is accepting
/// connections. Used to wait for a child Lich process to bind its detachable
/// listener before initiating a real client connection.
private final class ProbeState: @unchecked Sendable {
    private let lock = NSLock()
    private var resumed = false
    private let conn: NWConnection
    private let cont: CheckedContinuation<Bool, Never>

    init(conn: NWConnection, cont: CheckedContinuation<Bool, Never>) {
        self.conn = conn
        self.cont = cont
    }

    func finish(_ result: Bool) {
        lock.lock(); defer { lock.unlock() }
        guard !resumed else { return }
        resumed = true
        conn.cancel()
        cont.resume(returning: result)
    }
}

public enum TCPProbe {

    /// Returns true if a TCP connection to `host:port` reaches the `.ready`
    /// state within `timeout` seconds.
    public static func isOpen(
        host: String,
        port: UInt16,
        timeout: TimeInterval = 0.8
    ) async -> Bool {
        await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            guard let nwPort = NWEndpoint.Port(rawValue: port) else {
                cont.resume(returning: false)
                return
            }
            let conn = NWConnection(
                host: NWEndpoint.Host(host),
                port: nwPort,
                using: .tcp
            )

            let state = ProbeState(conn: conn, cont: cont)

            conn.stateUpdateHandler = { connState in
                switch connState {
                case .ready:    state.finish(true)
                case .failed, .waiting, .cancelled: state.finish(false)
                default: break
                }
            }
            conn.start(queue: .global())

            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                state.finish(false)
            }
        }
    }
}
