import AppKit
import ClipkyuCore
import os

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let log = Logger(subsystem: "app.clipkyu.Clipkyu", category: "app")
    private let pasteboard = PasteboardController()
    private let hotkeys = HotkeyMonitor()
    private let fileStore: ClipboardFileStore
    private var store: ClipboardStore
    private var status: StatusBarController?
    private var timer: Timer?
    private var oneShotOverride = false
    private var saveFailed = false
    private var startupNotice: String?
    private let version: String

    override init() {
        let files = ClipboardFileStore(url: ClipboardFileStore.defaultURL())
        fileStore = files
        switch files.load() {
        case .loaded(let loaded), .createdNew(let loaded):
            store = loaded
            startupNotice = nil
        case .resetAfterCorruptFile(let loaded, _):
            store = loaded
            startupNotice = "保存データが壊れていたため、退避して空の状態で起動しました。"
        }
        if let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           !short.isEmpty {
            version = short
        } else {
            version = "0.1.0"
        }
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        if let staged = store.restage() {
            pasteboard.writeInternal(staged.text)
        }
        persist()

        let status = StatusBarController()
        status.snapshotProvider = { [weak self] in
            self?.makeSnapshot() ?? .empty
        }
        status.onSelectMode = { [weak self] mode in
            self?.selectMode(mode)
        }
        status.onSelectHistory = { [weak self] id in
            self?.selectHistory(id)
        }
        status.onClearQueue = { [weak self] in
            self?.clearQueue()
        }
        status.onSelectMaxHistory = { [weak self] value in
            self?.selectMaxHistory(value)
        }
        status.onRequestAccess = { [weak self] in
            self?.requestAccess()
        }
        status.onOpenSettings = { [weak self] in
            self?.openSettings()
        }
        status.onQuit = { [weak self] in
            self?.quit()
        }
        self.status = status
        status.refreshTitle()

        hotkeys.onCommandV = { [weak self] in
            self?.handleCommandV()
        }
        hotkeys.refresh()
        startTimer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        timer = nil
        persist()
    }

    private func startTimer() {
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.pollPasteboard()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func pollPasteboard() {
        hotkeys.refresh()
        guard let snapshot = pasteboard.poll() else { return }
        let result = store.ingest(snapshot)
        guard result.skip == nil else { return }
        oneShotOverride = false
        if let stage = result.stage {
            pasteboard.writeInternal(stage.text)
        }
        if result.shouldPersist {
            persist()
        }
        status?.refreshTitle()
    }

    private func handleCommandV() {
        let decision = QueuePastePolicy.decide(
            mode: store.mode,
            hasStagedItem: store.stagedItem() != nil,
            stagedText: store.stagedItem()?.text,
            pastedText: pasteboard.currentString(),
            oneShotOverride: oneShotOverride,
            hasUnobservedChange: pasteboard.hasUnobservedChange
        )
        switch decision {
        case .ingestFirst:
            oneShotOverride = false
            pollPasteboard()
        case .resumeQueue:
            oneShotOverride = false
            if let stage = store.stagedItem() {
                pasteboard.writeInternal(stage.text)
            }
            status?.refreshTitle()
        case .advance:
            oneShotOverride = false
            _ = store.advanceAfterPaste()
            if let next = store.stagedItem() {
                pasteboard.writeInternal(next.text)
            }
            persist()
            status?.refreshTitle()
        case .ignore:
            break
        }
    }

    private func selectMode(_ mode: ClipMode) {
        if let stage = store.setMode(mode) {
            pasteboard.writeInternal(stage.text)
        }
        oneShotOverride = false
        persist()
        status?.refreshTitle()
    }

    private func selectHistory(_ id: UUID) {
        guard let item = store.historyItem(id: id) else { return }
        pasteboard.writeInternal(item.text)
        oneShotOverride = store.mode != .normal && store.stagedItem() != nil
    }

    private func clearQueue() {
        store.clearQueue()
        oneShotOverride = false
        persist()
        status?.refreshTitle()
    }

    private func selectMaxHistory(_ value: Int) {
        store.setMaxHistory(value)
        persist()
        status?.refreshTitle()
    }

    private func requestAccess() {
        hotkeys.requestPermission()
        hotkeys.refresh()
        status?.refreshTitle()
    }

    private func openSettings() {
        hotkeys.openSystemSettings()
    }

    private func quit() {
        persist()
        NSApp.terminate(nil)
    }

    private func persist() {
        do {
            try fileStore.save(store)
            saveFailed = false
        } catch {
            saveFailed = true
            log.error("Could not write the local clipboard store")
        }
    }

    private func makeSnapshot() -> StatusBarController.Snapshot {
        StatusBarController.Snapshot(
            version: version,
            mode: store.mode,
            maxHistory: store.maxHistory,
            history: store.history,
            queue: store.queue,
            stagedID: store.stagedID,
            accessibilityTrusted: hotkeys.isTrusted,
            saveFailed: saveFailed,
            notice: startupNotice
        )
    }
}
