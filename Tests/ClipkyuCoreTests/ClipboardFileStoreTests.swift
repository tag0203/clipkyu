import XCTest
@testable import ClipkyuCore

final class ClipboardFileStoreTests: XCTestCase {
    private var directory: URL!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("clipkyu-tests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        directory = nil
        super.tearDown()
    }

    func testRoundTripPreservesHistoryQueueModeAndStage() throws {
        let url = directory.appendingPathComponent("store.json")
        let files = ClipboardFileStore(url: url)
        var fixture = ClipboardStore(mode: .fifo, maxHistory: 25)
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        _ = fixture.ingest(PasteboardSnapshot(text: "A", types: ["public.utf8-plain-text"]), now: t0)
        _ = fixture.ingest(
            PasteboardSnapshot(text: "B", types: ["public.utf8-plain-text"]),
            now: Date(timeIntervalSince1970: 1_700_000_001)
        )

        try files.save(fixture)
        guard case .loaded(let loaded) = files.load() else {
            return XCTFail("expected a loaded store")
        }
        XCTAssertEqual(loaded, fixture)

        let raw = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(raw.contains("\"version\""))
        XCTAssertTrue(raw.contains("\"fifo\""))
        XCTAssertTrue(raw.contains("25"))
        XCTAssertFalse(raw.contains("secret-should-not-be-here"))

        let permissions = try FileManager.default.attributesOfItem(atPath: url.path)
        let mode = (permissions[.posixPermissions] as? NSNumber)?.intValue ?? -1
        XCTAssertEqual(mode & 0o777, 0o600)
    }

    func testMissingFileCreatesANewStore() {
        let url = directory.appendingPathComponent("missing.json")
        let outcome = ClipboardFileStore(url: url).load()
        guard case .createdNew(let store) = outcome else {
            return XCTFail("expected a new store")
        }
        XCTAssertEqual(store, ClipboardStore())
    }

    func testCorruptFileIsMovedAsideAndReset() throws {
        let url = directory.appendingPathComponent("store.json")
        try Data("not json".utf8).write(to: url)
        let outcome = ClipboardFileStore(url: url).load()
        guard case .resetAfterCorruptFile(let store, let backup) = outcome else {
            return XCTFail("expected a reset")
        }
        XCTAssertEqual(store, ClipboardStore())
        let backupURL = try XCTUnwrap(backup)
        XCTAssertTrue(FileManager.default.fileExists(atPath: backupURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(try String(contentsOf: backupURL, encoding: .utf8), "not json")
    }

    func testLoadTrimsHistoryToTheSavedMaximum() throws {
        let url = directory.appendingPathComponent("store.json")
        let items = (0..<4).map {
            ClipItem(id: UUID(), text: "n\($0)", createdAt: Date(timeIntervalSince1970: Double($0)))
        }
        let oversized = ClipboardStore(maxHistory: 4, history: items)
        var persisted = PersistedClipboard(store: oversized)
        persisted.maxHistory = 2
        let data = try ClipboardFileStore.makeEncoder().encode(persisted)
        try data.write(to: url)
        guard case .loaded(let loaded) = ClipboardFileStore(url: url).load() else {
            return XCTFail("expected a loaded store")
        }
        XCTAssertEqual(loaded.maxHistory, 2)
        XCTAssertEqual(loaded.history.map(\.text), ["n0", "n1"])
    }
}
