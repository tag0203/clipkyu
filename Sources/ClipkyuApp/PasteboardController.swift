import AppKit
import ClipkyuCore

/// Polls the general pasteboard and writes clips this app owns.
/// Writes include `ClipboardStore.internalTypeIdentifier` so the watcher does not
/// treat queue staging as a user copy.
final class PasteboardController {
    private let pasteboard: NSPasteboard
    private var lastChangeCount: Int
    private let markerType = NSPasteboard.PasteboardType(ClipboardStore.internalTypeIdentifier)

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
        self.lastChangeCount = pasteboard.changeCount
    }

    var hasUnobservedChange: Bool {
        pasteboard.changeCount != lastChangeCount
    }

    func currentString() -> String? {
        pasteboard.string(forType: .string)
    }

    /// Returns a snapshot when `changeCount` moved, including internal writes.
    /// The core drops internal writes; this object only reports the change.
    func poll() -> PasteboardSnapshot? {
        let count = pasteboard.changeCount
        guard count != lastChangeCount else { return nil }
        lastChangeCount = count
        return PasteboardSnapshot(
            text: pasteboard.string(forType: .string),
            types: (pasteboard.types ?? []).map(\.rawValue)
        )
    }

    func writeInternal(_ text: String) {
        let item = NSPasteboardItem()
        _ = item.setString(text, forType: .string)
        _ = item.setString("1", forType: markerType)
        pasteboard.clearContents()
        _ = pasteboard.writeObjects([item])
        lastChangeCount = pasteboard.changeCount
    }
}
