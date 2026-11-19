import XCTest
@testable import ClipkyuCore

final class PasteHotkeyTests: XCTestCase {
    func testPlainCommandV() {
        XCTAssertTrue(PasteHotkey.isPlainCommandV(KeyChord(
            charactersIgnoringModifiers: "v",
            command: true
        )))
        XCTAssertTrue(PasteHotkey.isPlainCommandV(KeyChord(
            charactersIgnoringModifiers: "V",
            command: true
        )))
    }

    func testModifiedOrRepeatedChordsAreNotQueueAdvances() {
        XCTAssertFalse(PasteHotkey.isPlainCommandV(KeyChord(
            charactersIgnoringModifiers: "v",
            command: true,
            shift: true
        )))
        XCTAssertFalse(PasteHotkey.isPlainCommandV(KeyChord(
            charactersIgnoringModifiers: "v",
            command: true,
            option: true
        )))
        XCTAssertFalse(PasteHotkey.isPlainCommandV(KeyChord(
            charactersIgnoringModifiers: "v",
            command: true,
            control: true
        )))
        XCTAssertFalse(PasteHotkey.isPlainCommandV(KeyChord(
            charactersIgnoringModifiers: "v",
            command: false
        )))
        XCTAssertFalse(PasteHotkey.isPlainCommandV(KeyChord(
            charactersIgnoringModifiers: "v",
            command: true,
            isRepeat: true
        )))
        XCTAssertFalse(PasteHotkey.isPlainCommandV(KeyChord(
            charactersIgnoringModifiers: nil,
            command: true
        )))
        XCTAssertFalse(PasteHotkey.isPlainCommandV(KeyChord(
            charactersIgnoringModifiers: "c",
            command: true
        )))
    }
}
