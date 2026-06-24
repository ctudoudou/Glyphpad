import AppKit
import Combine
import SwiftUI

@MainActor
final class LauncherAppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: LauncherWindow?
    private var settingsWindow: NSWindow?
    private let settingsController = LauncherSettingsController()
    private var hotKeyManager: GlobalHotKeyManager?
    private var settingsCancellable: AnyCancellable?
    private var isDismissingLauncher = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMenu()
        installGlobalHotKey()
        NSApplication.shared.presentationOptions = [.autoHideDock, .autoHideMenuBar]
        NotificationCenter.default.addObserver(
            forName: .glyphpadToggleSettings,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.showSettingsWindow()
            }
        }
        showLauncher()
    }

    func applicationWillTerminate(_ notification: Notification) {
        settingsController.flush()
    }

    private func toggleLauncher() {
        if window != nil {
            dismissLauncher()
        } else {
            showLauncher()
        }
    }

    private func showLauncher() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        let startedAt = PerformanceLog.start()
        let screen = NSScreen.main ?? NSScreen.screens.first
        let screenFrame = screen?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let windowFrame = screenFrame.insetBy(dx: -2, dy: -2)
        let window = LauncherWindow(contentRect: windowFrame)
        window.dismissHandler = { [weak self] in self?.dismissLauncher() }
        window.shouldHandlePageNavigation = { [weak settingsController] in
            settingsController?.settings.navigationMode == .horizontalPages
        }

        let rootView = LauncherView(settingsController: settingsController) { [weak self] in
            self?.dismissLauncher()
        }

        let hostingView = EdgePinnedHostingView(rootView: rootView)
        hostingView.frame = NSRect(origin: .zero, size: windowFrame.size)
        hostingView.autoresizingMask = [.width, .height]
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.black.cgColor
        window.contentView = hostingView
        window.setFrame(windowFrame, display: true)
        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        self.window = window
        isDismissingLauncher = false

        NSApplication.shared.unhide(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
        } completionHandler: {
            PerformanceLog.finish("launcher.open", startedAt: startedAt)
            Task { @MainActor in
                NSApplication.shared.setActivationPolicy(.accessory)
            }
        }
    }

    private func dismissLauncher() {
        let startedAt = PerformanceLog.start()
        guard let window else {
            PerformanceLog.finish("launcher.close.no-window", startedAt: startedAt)
            return
        }
        guard !isDismissingLauncher else {
            PerformanceLog.finish("launcher.close.already-dismissing", startedAt: startedAt)
            return
        }

        isDismissingLauncher = true
        window.ignoresMouseEvents = true
        NotificationCenter.default.post(name: .glyphpadLauncherWillDismiss, object: window)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: {
            DispatchQueue.main.async {
                PerformanceLog.finish("launcher.close", startedAt: startedAt)
                window.orderOut(nil)
                window.close()
                self.window = nil
                self.isDismissingLauncher = false
                if self.settingsWindow?.isVisible == true {
                    return
                }
                self.settingsController.flush()
                NSApplication.shared.hide(nil)
            }
        }
    }

    @objc private func openSettingsFromMenu(_ sender: Any?) {
        showSettingsWindow()
    }

    private func showSettingsWindow() {
        removeLauncherWindowForSettings()

        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 560),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.title = "Glyphpad Settings"
        settingsWindow.isReleasedWhenClosed = false
        settingsWindow.delegate = self
        settingsWindow.level = .floating
        settingsWindow.minSize = NSSize(width: 700, height: 520)
        settingsWindow.center()
        settingsWindow.contentView = NSHostingView(rootView: SettingsWindowView(controller: settingsController))
        settingsWindow.makeKeyAndOrderFront(nil)
        self.settingsWindow = settingsWindow
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func removeLauncherWindowForSettings() {
        guard let window else {
            return
        }

        window.ignoresMouseEvents = true
        window.alphaValue = 0
        window.orderOut(nil)
        window.close()
        self.window = nil
        isDismissingLauncher = false
    }

    func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow, closingWindow === settingsWindow else {
            return
        }

        settingsWindow = nil
        if window == nil {
            settingsController.flush()
        }
    }

    private func installGlobalHotKey() {
        hotKeyManager = GlobalHotKeyManager {
            Task { @MainActor [weak self] in
                self?.toggleLauncher()
            }
        }
        hotKeyManager?.register(settingsController.settings.showHotKey)
        settingsCancellable = settingsController.$settings
            .map(\.showHotKey)
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] hotKey in
                self?.hotKeyManager?.register(hotKey)
            }
    }

    private func installMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(
            NSMenuItem(
                title: "Settings...",
                action: #selector(openSettingsFromMenu(_:)),
                keyEquivalent: ","
            )
        )
        appMenu.items.last?.target = self
        appMenu.addItem(.separator())
        appMenu.addItem(
            NSMenuItem(
                title: "Quit Glyphpad",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )
        appMenuItem.submenu = appMenu

        mainMenu.addItem(appMenuItem)
        NSApplication.shared.mainMenu = mainMenu
    }
}
