import XCTest
@testable import ClipkyuCore

final class QueuePastePolicyTests: XCTestCase {
    func testAdvanceOnlyWhenStagedTextWasPastedInQueueMode() {
        XCTAssertEqual(
            QueuePastePolicy.decide(
                mode: .fifo,
                hasStagedItem: true,
                stagedText: "A",
                pastedText: "A",
                oneShotOverride: false,
                hasUnobservedChange: false
            ),
            .advance
        )
        XCTAssertEqual(
            QueuePastePolicy.decide(
                mode: .filo,
                hasStagedItem: true,
                stagedText: "C",
                pastedText: "C",
                oneShotOverride: false,
                hasUnobservedChange: false
            ),
            .advance
        )
    }

    func testNormalModeAndMismatchedTextDoNotAdvance() {
        XCTAssertEqual(
            QueuePastePolicy.decide(
                mode: .normal,
                hasStagedItem: false,
                stagedText: nil,
                pastedText: "A",
                oneShotOverride: false,
                hasUnobservedChange: false
            ),
            .ignore
        )
        XCTAssertEqual(
            QueuePastePolicy.decide(
                mode: .fifo,
                hasStagedItem: true,
                stagedText: "A",
                pastedText: "B",
                oneShotOverride: false,
                hasUnobservedChange: false
            ),
            .ignore
        )
        XCTAssertEqual(
            QueuePastePolicy.decide(
                mode: .fifo,
                hasStagedItem: false,
                stagedText: nil,
                pastedText: "A",
                oneShotOverride: false,
                hasUnobservedChange: false
            ),
            .ignore
        )
    }

    func testUnobservedChangeWinsOverAdvanceAndOneShot() {
        XCTAssertEqual(
            QueuePastePolicy.decide(
                mode: .fifo,
                hasStagedItem: true,
                stagedText: "A",
                pastedText: "A",
                oneShotOverride: true,
                hasUnobservedChange: true
            ),
            .ingestFirst
        )
    }

    func testKeyDownCaptureDoesNotDropTheFIFOHeadWhenTheNewCopyIsPasted() {
        var store = ClipboardStore(mode: .fifo)
        _ = store.ingest(PasteboardSnapshot(text: "A", types: ["public.utf8-plain-text"]))
        _ = store.ingest(PasteboardSnapshot(text: "B", types: ["public.utf8-plain-text"]))
        let head = store.stagedItem()
        let captured = QueuePastePolicy.capture(
            changeCount: 7,
            mode: store.mode,
            stagedID: head?.id,
            stagedText: head?.text,
            pasteboardText: "C",
            oneShotOverride: false,
            hasUnobservedChange: true
        )
        XCTAssertEqual(captured.changeCount, 7)
        XCTAssertEqual(captured.decision, .ingestFirst)
        XCTAssertEqual(captured.stagedID, head?.id)

        _ = store.ingest(PasteboardSnapshot(text: "C", types: ["public.utf8-plain-text"]))
        XCTAssertEqual(store.stagedItem()?.text, "A")
        let rereadAfterRestore = QueuePastePolicy.decide(
            mode: .fifo,
            hasStagedItem: true,
            stagedText: "A",
            pastedText: "A",
            oneShotOverride: false,
            hasUnobservedChange: false
        )
        XCTAssertEqual(rereadAfterRestore, .advance)
        XCTAssertNotEqual(captured.decision, rereadAfterRestore)
        XCTAssertEqual(store.queue.map(\.text), ["A", "B", "C"])
        XCTAssertEqual(store.history.map(\.text), ["C", "B", "A"])
    }

    func testAdvanceRemovesTheCapturedItemWhenTheStageMoved() {
        var store = ClipboardStore(mode: .filo)
        _ = store.ingest(PasteboardSnapshot(text: "A", types: ["public.utf8-plain-text"]))
        _ = store.ingest(PasteboardSnapshot(text: "B", types: ["public.utf8-plain-text"]))
        let oldest = store.queue[0].id
        let history = store.history
        XCTAssertEqual(store.stagedItem()?.text, "B")
        XCTAssertEqual(store.advanceAfterPaste(of: oldest)?.text, "B")
        XCTAssertEqual(store.queue.map(\.text), ["B"])
        XCTAssertEqual(store.history, history)
    }

    func testHistoryOneShotResumesTheQueueWithoutPopping() {
        XCTAssertEqual(
            QueuePastePolicy.decide(
                mode: .filo,
                hasStagedItem: true,
                stagedText: "C",
                pastedText: "from history",
                oneShotOverride: true,
                hasUnobservedChange: false
            ),
            .resumeQueue
        )
    }
}
