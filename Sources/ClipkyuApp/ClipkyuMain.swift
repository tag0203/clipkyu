import AppKit

/// Retains the delegate. `NSApplication.delegate` is weak.
private final class AppBox {
    static var delegate: AppDelegate?
}

@main
struct ClipkyuMain {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = AppDelegate()
        AppBox.delegate = delegate
        app.delegate = delegate
        app.run()
    }
}
