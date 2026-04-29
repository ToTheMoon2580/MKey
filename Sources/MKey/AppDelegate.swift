import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?

    private let scrollInterceptor = ScrollInterceptor()
    private let keyInterceptor = KeyInterceptor()
    private let permissionChecker = PermissionChecker()

    private var isInterceptorRunning = false
    private var permissionPollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()
        handleLaunchPermission()
    }

    // MARK: - 菜单栏

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "keyboard",
                accessibilityDescription: "MKey"
            )
            button.imagePosition = .imageOnly
            button.toolTip = "MKey"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: "设置…",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "退出",
            action: #selector(quitApp),
            keyEquivalent: "q"
        ))
        statusItem.menu = menu
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let contentView = SettingsWindow()
            let hostingController = NSHostingController(rootView: contentView)

            let window = NSWindow(contentViewController: hostingController)
            window.title = "MKey 设置"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.setContentSize(NSSize(width: 560, height: 580))
            window.center()
            settingsWindow = window
            // 窗口关闭时不销毁，保留引用以复用（AppSettings 为单例，状态总是最新）
            window.isReleasedWhenClosed = false
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        stopInterceptor()
        NSApplication.shared.terminate(nil)
    }

    // MARK: - 权限与拦截器生命周期

    private func handleLaunchPermission() {
        if permissionChecker.isTrusted {
            startInterceptor()
        } else {
            // 延迟弹窗，避免启动瞬间抢占焦点
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self else { return }
                if !self.permissionChecker.isTrusted {
                    let prompted = self.permissionChecker.checkAndPrompt()
                    if !prompted {
                        self.startPermissionPolling()
                    } else {
                        self.startInterceptor()
                    }
                }
            }
        }
    }

    private func startPermissionPolling() {
        permissionPollTimer?.invalidate()
        permissionPollTimer = Timer.scheduledTimer(
            withTimeInterval: 2.0,
            repeats: true
        ) { [weak self] _ in
            guard let self else { return }
            if self.permissionChecker.isTrusted {
                self.permissionPollTimer?.invalidate()
                self.permissionPollTimer = nil
                self.startInterceptor()
            }
        }
    }

    private func startInterceptor() {
        guard !isInterceptorRunning else { return }
        scrollInterceptor.start()
        keyInterceptor.start()
        isInterceptorRunning = true
    }

    private func stopInterceptor() {
        scrollInterceptor.stop()
        keyInterceptor.stop()
        isInterceptorRunning = false
        permissionPollTimer?.invalidate()
        permissionPollTimer = nil
    }

    /// 供 UI 层触发：用户手动授权后重试启动
    func retryStartIfNeeded() {
        guard permissionChecker.isTrusted, !isInterceptorRunning else { return }
        startInterceptor()
    }
}
