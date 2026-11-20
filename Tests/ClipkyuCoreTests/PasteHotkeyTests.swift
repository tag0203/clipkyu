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
        XCTAssertEqual(tracker.handle(.down(command: true)), .pressBegan)
        XCTAssertEqual(tracker.handle(.up(command: false)), .pressEnded)
    }

    func testReleasingShiftBeforeVDoesNotLookLikePlainPaste() {
        var tracker = PasteHotkeyTracker()
        XCTAssertEqual(tracker.handle(.down(command: true, shift: true)), .none)
        XCTAssertEqual(tracker.handle(.up(command: true, shift: false)), .none)
    }

    func testOptionAndControlChordsAreNotArmed() {
        var tracker = PasteHotkeyTracker()
        XCTAssertEqual(tracker.handle(.down(command: true, option: true)), .none)
        XCTAssertEqual(tracker.handle(.up(command: true)), .none)
        XCTAssertEqual(tracker.handle(.down(command: true, control: true)), .none)
        XCTAssertEqual(tracker.handle(.up(command: true, control: false)), .none)
    }

    func testRepeatDoesNotAdvanceTwice() {
        var tracker = PasteHotkeyTracker()
        XCTAssertEqual(tracker.handle(.down(command: true)), .pressBegan)
        XCTAssertEqual(tracker.handle(.down(command: true, isRepeat: true)), .none)
        XCTAssertEqual(tracker.handle(.up(command: true)), .pressEnded)
        XCTAssertEqual(tracker.handle(.up(command: true)), .none)
    }

    func testPlainPressAdvancesOnceOnKeyUp() {
        var tracker = PasteHotkeyTracker()
        XCTAssertEqual(tracker.handle(.down(command: true)), .pressBegan)
        XCTAssertEqual(tracker.handle(.up(command: true)), .pressEnded)
        XCTAssertEqual(tracker.handle(.up(command: false)), .none)
    }

    func testOtherKeysDoNotConsumeAnArmedPaste() {
        var tracker = PasteHotkeyTracker()
        XCTAssertEqual(tracker.handle(.down(command: true)), .pressBegan)
        XCTAssertEqual(tracker.handle(KeyEvent(
            phase: .down,
            chord: KeyChord(charactersIgnoringModifiers: "c", command: true)
        )), .none)
        XCTAssertEqual(tracker.handle(KeyEvent(
            phase: .up,
            chord: KeyChord(charactersIgnoringModifiers: "c", command: true)
        )), .none)
        XCTAssertEqual(tracker.handle(.up(command: false)), .pressEnded)
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
