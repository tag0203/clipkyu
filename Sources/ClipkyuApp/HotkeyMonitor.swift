import AppKit
import ApplicationServices
import ClipkyuCore

/// Watches plain ⌘V in other apps.
///
/// The destination app pastes on keyDown. By the time keyUp is delivered, that read
/// has happened, so the queue advances synchronously here. Deferring to a later turn
/// would race a second ⌘V and skip an item. A pasteboard-owner callback was rejected:
/// opening the Edit menu and other clipboard reads would look like a paste and pop
/// the queue. This monitor only sees the shortcut the user actually pressed.
///
/// `addGlobalMonitorForEvents` delivers nothing until Accessibility is granted.
/// Events sent to this process are not included, which is what we want.
final class HotkeyMonitor {
    private var monitor: Any?
    var onCommandV: (() -> Void)?

    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    func refresh() {
        if isTrusted {
            startIfNeeded()
        } else {
            stop()
        }
    }

    func requestPermission() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func openSystemSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
        ]
        for raw in candidates {
            guard let url = URL(string: raw) else { continue }
            if NSWorkspace.shared.open(url) {
                return
            }
        }
        NSSound.beep()
    }

    private func startIfNeeded() {
        guard monitor == nil, isTrusted else { return }
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyUp) { [weak self] event in
            guard let self else { return }
            guard PasteHotkey.isPlainCommandV(self.chord(from: event)) else { return }
            self.onCommandV?()
        }
    }

    private func stop() {
        guard let monitor else { return }
        NSEvent.removeMonitor(monitor)
        self.monitor = nil
    }

    private func chord(from event: NSEvent) -> KeyChord {
        let flags = event.modifierFlags
        return KeyChord(
            charactersIgnoringModifiers: event.charactersIgnoringModifiers,
            command: flags.contains(.command),
            shift: flags.contains(.shift),
            option: flags.contains(.option),
            control: flags.contains(.control),
            isRepeat: event.isARepeat
        )
    }
}
