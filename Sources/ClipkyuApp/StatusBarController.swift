import AppKit
import ClipkyuCore

/// Menu-bar item. The title shows the mode and how many clips are still in the queue.
final class StatusBarController: NSObject, NSMenuDelegate {
    struct Snapshot {
        var version: String
        var mode: ClipMode
        var maxHistory: Int
        var history: [ClipItem]
        var queue: [ClipItem]
        var stagedID: UUID?
        var accessibilityTrusted: Bool
        var saveFailed: Bool
        var notice: String?

        static let empty = Snapshot(
            version: "0.1.0",
            mode: .normal,
            maxHistory: ClipboardStore.defaultMaxHistory,
            history: [],
            queue: [],
            stagedID: nil,
            accessibilityTrusted: false,
            saveFailed: false,
            notice: nil
        )
    }

    var snapshotProvider: () -> Snapshot = { .empty }
    var onSelectMode: ((ClipMode) -> Void)?
    var onSelectHistory: ((UUID) -> Void)?
    var onClearQueue: (() -> Void)?
    var onSelectMaxHistory: ((Int) -> Void)?
    var onRequestAccess: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onQuit: (() -> Void)?

    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private let maxHistoryPresets = [25, 50, 100, 200]

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        menu.delegate = self
        menu.autoenablesItems = false
        statusItem.menu = menu
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Clipkyu") {
                image.isTemplate = true
                button.image = image
            }
            button.imagePosition = .imageLeading
            button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        }
        refreshTitle()
    }

    func refreshTitle() {
        let snapshot = snapshotProvider()
        let title = Self.statusTitle(mode: snapshot.mode, queueCount: snapshot.queue.count)
        statusItem.button?.title = title
        statusItem.button?.toolTip = "Clipkyu \(title)"
        statusItem.button?.setAccessibilityLabel("Clipkyu \(title)")
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuild(snapshotProvider())
    }

    private static func statusTitle(mode: ClipMode, queueCount: Int) -> String {
        switch mode {
        case .normal:
            return "通常 \(queueCount)"
        case .fifo:
            return "FIFO \(queueCount)"
        case .filo:
            return "FILO \(queueCount)"
        }
    }

    private func rebuild(_ snapshot: Snapshot) {
        menu.removeAllItems()
        addDisabled("Clipkyu \(snapshot.version)")
        if let notice = snapshot.notice {
            addDisabled(notice)
        }
        if snapshot.saveFailed {
            addDisabled("保存に失敗しました。メモリ上の内容は維持しています。")
        }
        menu.addItem(.separator())

        addDisabled("モード")
        for mode in ClipMode.allCases {
            let item = NSMenuItem(
                title: modeTitle(mode),
                action: #selector(selectMode(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = mode.rawValue
            item.state = snapshot.mode == mode ? .on : .off
            menu.addItem(item)
        }
        addDisabled("キューを消費しても履歴は変わりません")
        menu.addItem(.separator())

        addDisabled("キュー（\(snapshot.queue.count)）")
        if snapshot.queue.isEmpty {
            addDisabled("キューは空です")
        } else {
            let ordered = displayQueue(snapshot)
            let limit = 20
            for item in ordered.prefix(limit) {
                let marker = item.id == snapshot.stagedID ? "次  " : "    "
                addDisabled(marker + MenuText.preview(item.text))
            }
            if ordered.count > limit {
                addDisabled("ほか \(ordered.count - limit) 件")
            }
        }
        let clear = NSMenuItem(title: "キューをクリア", action: #selector(clearQueue(_:)), keyEquivalent: "")
        clear.target = self
        clear.isEnabled = !snapshot.queue.isEmpty
        menu.addItem(clear)
        menu.addItem(.separator())

        addDisabled("履歴（\(snapshot.history.count)）")
        if snapshot.history.isEmpty {
            addDisabled("履歴はありません")
        } else {
            for item in snapshot.history {
                let menuItem = NSMenuItem(
                    title: MenuText.preview(item.text),
                    action: #selector(selectHistory(_:)),
                    keyEquivalent: ""
                )
                menuItem.target = self
                menuItem.representedObject = item.id.uuidString
                menuItem.toolTip = item.text.count > 2000 ? String(item.text.prefix(2000)) + "…" : item.text
                menu.addItem(menuItem)
            }
        }
        menu.addItem(.separator())

        let limitMenu = NSMenu()
        limitMenu.autoenablesItems = false
        var limits = maxHistoryPresets
        if !limits.contains(snapshot.maxHistory) {
            limits.append(snapshot.maxHistory)
            limits.sort()
        }
        for value in limits {
            let item = NSMenuItem(
                title: "\(value) 件",
                action: #selector(selectMaxHistory(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = NSNumber(value: value)
            item.state = value == snapshot.maxHistory ? .on : .off
            limitMenu.addItem(item)
        }
        let limitItem = NSMenuItem(title: "履歴の上限", action: nil, keyEquivalent: "")
        limitItem.submenu = limitMenu
        menu.addItem(limitItem)
        menu.addItem(.separator())

        if snapshot.accessibilityTrusted {
            addDisabled("⌘V でキューを送ります")
        } else {
            addDisabled("自動送りにはアクセシビリティ権限がまだありません")
            addDisabled("コピーはキューに入りますが、⌘V では進みません")
            addAction("アクセシビリティ権限をリクエスト…", #selector(requestAccess(_:)))
        }
        addAction("システム設定の「アクセシビリティ」を開く…", #selector(openSettings(_:)))
        menu.addItem(.separator())
        addAction("終了", #selector(quit(_:)))
    }

    private func displayQueue(_ snapshot: Snapshot) -> [ClipItem] {
        switch snapshot.mode {
        case .filo:
            return Array(snapshot.queue.reversed())
        case .normal, .fifo:
            return snapshot.queue
        }
    }

    private func modeTitle(_ mode: ClipMode) -> String {
        switch mode {
        case .normal:
            return "通常"
        case .fifo:
            return "FIFO（古い順）"
        case .filo:
            return "FILO（新しい順）"
        }
    }

    private func addDisabled(_ title: String) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
    }

    private func addAction(_ title: String, _ action: Selector) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
    }

    @objc private func selectMode(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let mode = ClipMode(rawValue: raw) else { return }
        onSelectMode?(mode)
    }

    @objc private func selectHistory(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let id = UUID(uuidString: raw) else { return }
        onSelectHistory?(id)
    }

    @objc private func clearQueue(_ sender: NSMenuItem) {
        onClearQueue?()
    }

    @objc private func selectMaxHistory(_ sender: NSMenuItem) {
        guard let number = sender.representedObject as? NSNumber else { return }
        onSelectMaxHistory?(number.intValue)
    }

    @objc private func requestAccess(_ sender: NSMenuItem) {
        onRequestAccess?()
    }

    @objc private func openSettings(_ sender: NSMenuItem) {
        onOpenSettings?()
    }

    @objc private func quit(_ sender: NSMenuItem) {
        onQuit?()
    }
}
