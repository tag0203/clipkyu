import Foundation

/// Single-line menu titles. The stored clip is never rewritten.
public enum MenuText {
    public static func preview(_ text: String, limit: Int = 60) -> String {
        let flat = text
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
        guard limit > 0 else { return "" }
        if flat.count <= limit { return flat }
        if limit == 1 { return "…" }
        return String(flat.prefix(limit - 1)) + "…"
    }
}
