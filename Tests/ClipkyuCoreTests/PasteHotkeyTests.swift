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

    func testKeyUpAdvancesWhenCommandWasReleasedFirst() {
        var tracker = PasteHotkeyTracker()
        XCTAssertFalse(tracker.handle(.down(command: true)))
        XCTAssertTrue(tracker.handle(.up(command: false)))
    }

    func testReleasingShiftBeforeVDoesNotLookLikePlainPaste() {
        var tracker = PasteHotkeyTracker()
        XCTAssertFalse(tracker.handle(.down(command: true, shift: true)))
        XCTAssertFalse(tracker.handle(.up(command: true, shift: false)))
    }

    func testOptionAndControlChordsAreNotArmed() {
        var tracker = PasteHotkeyTracker()
        XCTAssertFalse(tracker.handle(.down(command: true, option: true)))
        XCTAssertFalse(tracker.handle(.up(command: true)))
        XCTAssertFalse(tracker.handle(.down(command: true, control: true)))
        XCTAssertFalse(tracker.handle(.up(command: true, control: false)))
    }

    func testRepeatDoesNotAdvanceTwice() {
        var tracker = PasteHotkeyTracker()
        XCTAssertFalse(tracker.handle(.down(command: true)))
        XCTAssertFalse(tracker.handle(.down(command: true, isRepeat: true)))
        XCTAssertTrue(tracker.handle(.up(command: true)))
        XCTAssertFalse(tracker.handle(.up(command: true)))
    }

    func testPlainPressAdvancesOnceOnKeyUp() {
        var tracker = PasteHotkeyTracker()
        XCTAssertFalse(tracker.handle(.down(command: true)))
        XCTAssertTrue(tracker.handle(.up(command: true)))
        XCTAssertFalse(tracker.handle(.up(command: false)))
    }

    func testOtherKeysDoNotConsumeAnArmedPaste() {
        var tracker = PasteHotkeyTracker()
        XCTAssertFalse(tracker.handle(.down(command: true)))
        XCTAssertFalse(tracker.handle(KeyEvent(
            phase: .down,
            chord: KeyChord(charactersIgnoringModifiers: "c", command: true)
        )))
        XCTAssertFalse(tracker.handle(KeyEvent(
            phase: .up,
            chord: KeyChord(charactersIgnoringModifiers: "c", command: true)
        )))
        XCTAssertTrue(tracker.handle(.up(command: false)))
    }
}

private extension KeyEvent {
    static func down(
        command: Bool,
        shift: Bool = false,
        option: Bool = false,
        control: Bool = false,
        isRepeat: Bool = false
    ) -> KeyEvent {
        KeyEvent(
            phase: .down,
            chord: KeyChord(
                charactersIgnoringModifiers: "v",
                command: command,
                shift: shift,
                option: option,
                control: control,
                isRepeat: isRepeat
            )
        )
    }

    static func up(command: Bool, shift: Bool = false, control: Bool = false) -> KeyEvent {
        KeyEvent(
            phase: .up,
            chord: KeyChord(
                charactersIgnoringModifiers: "v",
                command: command,
                shift: shift,
                control: control
            )
        )
    }
}
