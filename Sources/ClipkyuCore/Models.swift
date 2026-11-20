import Foundation

/// How copies are staged for the next paste.
///
/// FIFO pastes the oldest queued item first. FILO pastes the newest first.
/// Normal mode records history and does not touch the queue.
public enum ClipMode: String, Codable, Sendable, CaseIterable, Equatable {
    case normal
    case fifo
    case filo
}

/// One plain-text clip. History items and queue items are separate values
/// even when the text matches, so removing a queue item cannot remove history.
public struct ClipItem: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let text: String
    public let createdAt: Date

    public init(id: UUID = UUID(), text: String, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
    }
}

/// A plain-text reading of the general pasteboard, with the type names the
/// source app declared. The app target builds this; the core decides what to do.
public struct PasteboardSnapshot: Equatable, Sendable {
    public var text: String?
    public var types: [String]

    public init(text: String?, types: [String]) {
        self.text = text
        self.types = types
    }
}

public enum IngestSkip: String, Equatable, Sendable {
    case empty
    case sensitive
    case internalWrite
    case notText
}

public struct IngestResult: Equatable, Sendable {
    public var skip: IngestSkip?
    /// True when a new history row was inserted. Consecutive duplicates do not insert.
    public var historyInserted: Bool
    /// True when FIFO/FILO mode appended a queue item.
    public var enqueued: Bool
    /// When set, the app should place this item on the pasteboard as an internal write.
    /// FIFO returns the oldest item (the user's latest copy is not what should be pasted next).
    /// FILO returns the newest item.
    public var stage: ClipItem?

    public var shouldPersist: Bool {
        historyInserted || enqueued
    }

    public init(skip: IngestSkip?, historyInserted: Bool, enqueued: Bool, stage: ClipItem?) {
        self.skip = skip
        self.historyInserted = historyInserted
        self.enqueued = enqueued
        self.stage = stage
    }
}
