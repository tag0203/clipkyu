import Foundation

public enum LoadOutcome: Equatable, Sendable {
    case loaded(ClipboardStore)
    case createdNew(ClipboardStore)
    /// The previous file could not be decoded. When `backupURL` is set, the bytes were moved aside.
    case resetAfterCorruptFile(ClipboardStore, backupURL: URL?)
}

/// JSON file in Application Support. Local only; permissions are owner-read/write.
public struct ClipboardFileStore {
    public static let currentFileVersion = 1

    public let url: URL
    private let fileManager: FileManager

    public init(url: URL, fileManager: FileManager = .default) {
        self.url = url
        self.fileManager = fileManager
    }

    /// `~/Library/Application Support/Clipkyu/store.json` on macOS.
    public static func defaultURL(fileManager: FileManager = .default) -> URL {
        let base: URL
        if let support = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) {
            base = support
        } else {
            base = fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support", isDirectory: true)
        }
        let directory = base.appendingPathComponent("Clipkyu", isDirectory: true)
        try? fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try? fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
        return directory.appendingPathComponent("store.json")
    }

    public func load() -> LoadOutcome {
        guard fileManager.fileExists(atPath: url.path) else {
            return .createdNew(ClipboardStore())
        }
        do {
            let data = try Data(contentsOf: url)
            let persisted = try Self.makeDecoder().decode(PersistedClipboard.self, from: data)
            return .loaded(ClipboardStore(persisted: persisted))
        } catch {
            let backup = quarantine()
            return .resetAfterCorruptFile(ClipboardStore(), backupURL: backup)
        }
    }

    public func save(_ store: ClipboardStore) throws {
        let directory = url.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
        let data = try Self.makeEncoder().encode(PersistedClipboard(store: store))
        try data.write(to: url, options: [.atomic])
        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    private func quarantine() -> URL? {
        let backup = url.deletingLastPathComponent()
            .appendingPathComponent("store.json.corrupt-\(UUID().uuidString)")
        do {
            try fileManager.moveItem(at: url, to: backup)
            return backup
        } catch {
            return nil
        }
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.timeIntervalSince1970)
        }
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let interval = try container.decode(Double.self)
            return Date(timeIntervalSince1970: interval)
        }
        return decoder
    }
}

struct PersistedClipboard: Codable, Equatable {
    var version: Int
    var mode: ClipMode
    var maxHistory: Int
    var history: [ClipItem]
    var queue: [ClipItem]
    var stagedID: UUID?

    init(store: ClipboardStore) {
        version = ClipboardFileStore.currentFileVersion
        mode = store.mode
        maxHistory = store.maxHistory
        history = store.history
        queue = store.queue
        stagedID = store.stagedID
    }
}

extension ClipboardStore {
    init(persisted: PersistedClipboard) {
        self.init(
            mode: persisted.mode,
            maxHistory: persisted.maxHistory,
            history: persisted.history,
            queue: persisted.queue,
            stagedID: persisted.stagedID
        )
    }
}
