import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let store = ProfileStore.shared
    private let settings = AppSettings.shared

    private var mainWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyAppearanceSettings()
        buildMainMenu()

        // Áp dụng lại mỗi khi cài đặt thay đổi (objectWillChange bắn trước khi giá trị đổi → async).
        settings.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.applyAppearanceSettings()
                self?.buildMainMenu()
                self?.updateWindowTitles()
            }
            .store(in: &cancellables)

        if !settings.startHidden {
            showMain()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    /// Mở lại app từ Finder/Launchpad/Dock khi đang ẩn → hiện cửa sổ chính.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMain()
        return true
    }

    // MARK: Windows

    @objc func showMain() {
        if mainWindow == nil {
            let root = MainView().environmentObject(store).environmentObject(settings)
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 440),
                             styleMask: [.titled, .closable, .miniaturizable, .resizable],
                             backing: .buffered, defer: false)
            w.contentView = NSHostingView(rootView: root)
            w.isReleasedWhenClosed = false
            w.title = "Claude Instances"
            w.center()
            w.setFrameAutosaveName("MainWindow")
            mainWindow = w
        }
        NSApp.activate(ignoringOtherApps: true)
        mainWindow?.makeKeyAndOrderFront(nil)
    }

    @objc func showSettings() {
        if settingsWindow == nil {
            let root = SettingsView().environmentObject(settings)
            let w = NSWindow(contentViewController: NSHostingController(rootView: root))
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            w.center()
            settingsWindow = w
        }
        updateWindowTitles()
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    private func updateWindowTitles() {
        settingsWindow?.title = tr(.settings)
    }

    // MARK: Dock / menu bar

    private func applyAppearanceSettings() {
        let policy: NSApplication.ActivationPolicy = settings.hideDock ? .accessory : .regular
        if NSApp.activationPolicy() != policy {
            let visible = NSApp.windows.filter(\.isVisible)
            NSApp.setActivationPolicy(policy)
            // Đổi policy có thể làm mất focus/ẩn cửa sổ — đưa lại lên trước.
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                visible.forEach { $0.makeKeyAndOrderFront(nil) }
            }
        }

        if settings.hideMenuBar {
            if let item = statusItem { NSStatusBar.system.removeStatusItem(item) }
            statusItem = nil
        } else if statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            if let button = item.button {
                let image = NSImage(systemSymbolName: "square.stack.3d.up.fill", accessibilityDescription: "Claude Instances")
                image?.isTemplate = true
                button.image = image
                button.toolTip = "Claude Instances"
            }
            let menu = NSMenu()
            menu.delegate = self
            item.menu = menu
            statusItem = item
        }
    }

    // Dựng lại menu thanh trạng thái mỗi lần mở để luôn đúng trạng thái/ngôn ngữ.
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === statusItem?.menu else { return }
        menu.removeAllItems()

        let header = NSMenuItem(title: tr(.profiles), action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        for p in store.profiles {
            let item = NSMenuItem(title: store.displayName(p), action: #selector(launchFromMenu(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = p.id
            item.state = store.isRunning(p) ? .on : .off
            item.toolTip = p.path
            item.image = NSImage(systemSymbolName: store.isRunning(p) ? "macwindow" : "play.fill",
                                 accessibilityDescription: nil)
            menu.addItem(item)
        }

        menu.addItem(.separator())
        menu.addItem(withTitle: tr(.showWindow), action: #selector(showMain), keyEquivalent: "").target = self
        menu.addItem(withTitle: tr(.settings) + "…", action: #selector(showSettings), keyEquivalent: ",").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: tr(.quitApp), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    @objc private func launchFromMenu(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID, let p = store.profile(id) else { return }
        store.launch(p)
    }

    // MARK: Main menu (cần cho Cmd+Q/W/, và copy/paste trong text field)

    private func buildMainMenu() {
        let main = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: tr(.about), action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: tr(.settings) + "…", action: #selector(showSettings), keyEquivalent: ",").target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: tr(.hideApp), action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: tr(.quitApp), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        main.addItem(appItem)

        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: tr(.editMenu))
        editMenu.addItem(withTitle: tr(.undo), action: Selector(("undo:")), keyEquivalent: "z")
        let redo = editMenu.addItem(withTitle: tr(.redo), action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: tr(.cut), action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: tr(.copy), action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: tr(.paste), action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: tr(.selectAll), action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu
        main.addItem(editItem)

        let windowItem = NSMenuItem()
        let windowMenu = NSMenu(title: tr(.windowMenu))
        windowMenu.addItem(withTitle: tr(.minimize), action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: tr(.close), action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowItem.submenu = windowMenu
        main.addItem(windowItem)

        NSApp.mainMenu = main
        NSApp.windowsMenu = windowMenu
    }
}
