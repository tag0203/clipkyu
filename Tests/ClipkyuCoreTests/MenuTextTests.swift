import XCTest
@testable import ClipkyuCore

final class MenuTextTests: XCTestCase {
    func testNewlinesAndTabsBecomeSpaces() {
        XCTAssertEqual(MenuText.preview("hello\nworld"), "hello world")
        XCTAssertEqual(MenuText.preview("a\r\nb\tc"), "a b c")
    }

    func testTruncationUsesAnEllipsisInsideTheLimit() {
        let text = String(repeating: "あ", count: 80)
        let preview = MenuText.preview(text, limit: 10)
        XCTAssertEqual(preview.count, 10)
        XCTAssertTrue(preview.hasSuffix("…"))
        XCTAssertEqual(MenuText.preview("short", limit: 10), "short")
        XCTAssertEqual(MenuText.preview("x", limit: 0), "")
    }
}
