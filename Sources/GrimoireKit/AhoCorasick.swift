import Foundation

/// Minimal Aho-Corasick multi-substring matcher used as a presence gate for
/// `HighlightProcessor`. Built once per rule set, it answers "which of these N
/// needles occur in this line?" in one O(lineLength) pass instead of N scans.
///
/// It reports only presence (the set of needle ids), not positions; the exact
/// matcher re-derives positions itself.
///
/// Matching is case-sensitive here; callers lower-case both needles and search
/// text for case-insensitive behavior. ASCII case-folding is identical between
/// Swift and Foundation, so this stays in lock-step with the `NSString`
/// substring search (non-ASCII rules are handled by the caller, not gated here).
final class AhoCorasick {

    private final class Node {
        var transitions: [Character: Int] = [:]
        var fail = 0
        /// Needle ids that terminate at (or are suffixes ending at) this node.
        var outputs: [Int] = []
    }

    private var nodes: [Node] = [Node()]   // index 0 is the root

    /// Adds `pattern` (already lower-cased by the caller) under `id`. Empty
    /// patterns are ignored — they'd "occur" everywhere and defeat the gate.
    func add(_ pattern: String, id: Int) {
        guard !pattern.isEmpty else { return }
        var cur = 0
        for ch in pattern {
            if let nxt = nodes[cur].transitions[ch] {
                cur = nxt
            } else {
                nodes.append(Node())
                let n = nodes.count - 1
                nodes[cur].transitions[ch] = n
                cur = n
            }
        }
        nodes[cur].outputs.append(id)
    }

    /// Wires up failure links (BFS) and folds suffix-link outputs forward so
    /// `search` can collect all hits without walking fail links per node.
    /// Call once after all `add`s, before `search`.
    func build() {
        var queue: [Int] = []
        for (_, child) in nodes[0].transitions {
            nodes[child].fail = 0
            queue.append(child)
        }
        var head = 0
        while head < queue.count {
            let u = queue[head]; head += 1
            for (ch, v) in nodes[u].transitions {
                queue.append(v)
                var f = nodes[u].fail
                while f != 0 && nodes[f].transitions[ch] == nil {
                    f = nodes[f].fail
                }
                let fallback = nodes[f].transitions[ch]
                nodes[v].fail = (fallback != nil && fallback != v) ? fallback! : 0
                // Inherit the fail node's outputs so a hit at `v` also reports
                // every shorter needle that ends here.
                nodes[v].outputs.append(contentsOf: nodes[nodes[v].fail].outputs)
            }
        }
    }

    /// Returns the set of needle ids that occur anywhere in `text`
    /// (which the caller has already lower-cased).
    func search(_ text: String) -> Set<Int> {
        var result = Set<Int>()
        var cur = 0
        for ch in text {
            while cur != 0 && nodes[cur].transitions[ch] == nil {
                cur = nodes[cur].fail
            }
            cur = nodes[cur].transitions[ch] ?? 0
            let outs = nodes[cur].outputs
            if !outs.isEmpty { result.formUnion(outs) }
        }
        return result
    }
}
