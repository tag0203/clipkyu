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
