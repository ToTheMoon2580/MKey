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
            title: "为当前应用添加滚动规则",
            action: #selector(quickAddRule),
            keyEquivalent: ""
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
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.setContentSize(NSSize(width: 540, height: 540))
            window.center()
            // 浮动置顶：切到其他 App 窗口也不消失
            window.level = .floating
            settingsWindow = window
            window.isReleasedWhenClosed = false
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// 菜单栏快捷操作：直接为当前前台 App 添加一条反转滚轮规则
    @objc private func quickAddRule() {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleID = app.bundleIdentifier else { return }

        let settings = AppSettings.shared
        guard !settings.perAppScrollRules.contains(where: { $0.bundleID == bundleID }) else {
            showAlert(message: "已存在规则", info: "「\(app.localizedName ?? bundleID)」已有滚动规则，无需重复添加。")
            return
        }

        let rule = PerAppScrollRule(
            bundleID: bundleID,
            appName: app.localizedName ?? bundleID,
            scrollBehavior: .reversed
        )
        settings.perAppScrollRules.append(rule)
        showAlert(message: "已添加", info: "已为「\(rule.appName)」添加滚动反转规则。")
    }

    private func showAlert(message: String, info: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = info
        alert.runModal()
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

    func retryStartIfNeeded() {
        guard permissionChecker.isTrusted, !isInterceptorRunning else { return }
        startInterceptor()
    }
}
