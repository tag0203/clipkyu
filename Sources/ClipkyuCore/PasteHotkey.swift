import Foundation

/// Modifier snapshot for one key event, so the chord test does not depend on AppKit.
public struct KeyChord: Equatable, Sendable {
    public var charactersIgnoringModifiers: String?
    public var command: Bool
    public var shift: Bool
    public var option: Bool
    public var control: Bool
    public var isRepeat: Bool

    public init(
        charactersIgnoringModifiers: String?,
        command: Bool,
        shift: Bool = false,
        option: Bool = false,
        control: Bool = false,
        isRepeat: Bool = false
    ) {
        self.charactersIgnoringModifiers = charactersIgnoringModifiers
        self.command = command
        self.shift = shift
        self.option = option
        self.control = control
        self.isRepeat = isRepeat
    }
}

public enum PasteHotkey {
    /// Plain ⌘V. Shift, Option, and Control are different shortcuts (paste-and-match, etc.).
    /// Caps Lock is ignored. The character is compared, not the physical key code, so the
    /// check follows the active keyboard layout.
    public static func isPlainCommandV(_ chord: KeyChord) -> Bool {
        guard !chord.isRepeat else { return false }
        guard chord.command, !chord.shift, !chord.option, !chord.control else { return false }
        return chord.charactersIgnoringModifiers?.lowercased() == "v"
    }
}

public enum KeyPhase: Equatable, Sendable {
    case down
    case up
}

public struct KeyEvent: Equatable, Sendable {
    public var phase: KeyPhase
    public var chord: KeyChord

    public init(phase: KeyPhase, chord: KeyChord) {
        self.phase = phase
        self.chord = chord
    }
}

/// Remembers whether the V key went down as plain ⌘V, then advances on its key-up.
///
/// Modifiers are read on key-down, which is when the destination app pastes.
/// Releasing Command before V still advances. Releasing Shift, Option, or Control
/// before V does not turn that press into a plain paste.
public enum PasteKeyEffect: Equatable, Sendable {
    case none
    /// Plain ⌘V went down. Capture the pasteboard before any poll runs.
    case pressBegan
    /// The matching V key came up. Apply the capture from `pressBegan`.
    case pressEnded
}

public struct PasteHotkeyTracker: Equatable, Sendable {
    private var armed = false

    public init() {}

    /// `.pressBegan` on a plain ⌘V key-down, `.pressEnded` on its key-up.
    public mutating func handle(_ event: KeyEvent) -> PasteKeyEffect {
        guard Self.isV(event.chord) else { return .none }
        switch event.phase {
        case .down:
            guard !event.chord.isRepeat else { return .none }
            armed = PasteHotkey.isPlainCommandV(event.chord)
            return armed ? .pressBegan : .none
        case .up:
            let shouldAdvance = armed
            armed = false
            return shouldAdvance ? .pressEnded : .none
        }
    }

    private static func isV(_ chord: KeyChord) -> Bool {
        chord.charactersIgnoringModifiers?.lowercased() == "v"
    }
}
