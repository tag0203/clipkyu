import Foundation

/// What a detected ⌘V should do to the queue. The app applies this; tests lock it.
public enum QueuePasteDecision: Equatable, Sendable {
    /// A copy landed that this process has not ingested yet. Record it and do not pop.
    case ingestFirst
    /// The user picked a history item for a single paste. Do not pop; put the staged item back after.
    case resumeQueue
    /// The staged queue item was pasted. Remove it and stage the next one.
    case advance
    /// Normal mode, empty queue, or the clipboard is not the staged item.
    case ignore
}

public enum QueuePastePolicy {
    public static func decide(
        mode: ClipMode,
        hasStagedItem: Bool,
        stagedText: String?,
        pastedText: String?,
        oneShotOverride: Bool,
        hasUnobservedChange: Bool
    ) -> QueuePasteDecision {
        // A change we have not ingested yet means the pasteboard is no longer the
        // item we staged (or it was replaced with the same text by a new copy).
        // Recording that change is safer than popping the queue.
        if hasUnobservedChange {
            return .ingestFirst
        }
        if oneShotOverride {
            return .resumeQueue
        }
        guard mode == .fifo || mode == .filo else {
            return .ignore
        }
        guard hasStagedItem, let stagedText, let pastedText, stagedText == pastedText else {
            return .ignore
        }
        return .advance
    }

    /// Freezes the consume decision at key-down, when the other app reads the pasteboard.
    /// A later poll may put the staged item back before key-up; that restore must not be
    /// treated as the text that was pasted.
    public static func capture(
        changeCount: Int,
        mode: ClipMode,
        stagedID: UUID?,
        stagedText: String?,
        pasteboardText: String?,
        oneShotOverride: Bool,
        hasUnobservedChange: Bool
    ) -> PastePressCapture {
        PastePressCapture(
            changeCount: changeCount,
            decision: decide(
                mode: mode,
                hasStagedItem: stagedID != nil,
                stagedText: stagedText,
                pastedText: pasteboardText,
                oneShotOverride: oneShotOverride,
                hasUnobservedChange: hasUnobservedChange
            ),
            stagedID: stagedID
        )
    }
}

/// Clipboard and queue identity observed on the ⌘V key-down.
public struct PastePressCapture: Equatable, Sendable {
    public var changeCount: Int
    public var decision: QueuePasteDecision
    public var stagedID: UUID?

    public init(changeCount: Int, decision: QueuePasteDecision, stagedID: UUID?) {
        self.changeCount = changeCount
        self.decision = decision
        self.stagedID = stagedID
    }
}
