import Foundation

/// Modifier snapshot for a key-up, so the chord test does not depend on AppKit.
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
