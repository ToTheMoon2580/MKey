import SwiftUI
import Cocoa

struct ScrollTab: View {
    @StateObject private var settings = AppSettings.shared
    @State private var isTrusted = AXIsProcessTrusted()
    @State private var frontAppName: String = ""
    @State private var frontAppBundleID: String = ""

    /// 权限轮询定时器
    @State private var trustPollTimer: Timer?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 权限警告
                if !isTrusted {
                    permissionWarning
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                }

                // 全局开关
                globalSection
                    .padding(.horizontal, 12)
                    .padding(.top, 12)

                Divider().padding(.horizontal, 12)

                // 行为说明
                behaviorSection
                    .padding(.horizontal, 12)

                // 冲突提示
                conflictNote
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)

                Divider().padding(.horizontal, 12)

                // 应用规则
                appFilterSection
                    .padding(.horizontal, 12)
            }
        }
        .onAppear {
            refreshTrustStatus()
            refreshFrontApp()
            startTrustPollingIfNeeded()
        }
        .onDisappear {
            stopTrustPolling()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshTrustStatus()
            refreshFrontApp()
        }
    }

    // MARK: - 全局开关

    private var globalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("触控板 / 鼠标滚动方向独立控制")
                .font(.headline)
            Text("触控板保持自然滚动，鼠标滚轮方向反转")
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)

            HStack {
                Text("启用滚动方向独立控制")
                    .font(.body)
                Spacer()
                Toggle("", isOn: $settings.scrollReverseEnabled)
                    .toggleStyle(.switch)
                    .disabled(!isTrusted)
            }

            HStack {
                Text("开机自动启动")
                    .font(.body)
                Spacer()
                Toggle("", isOn: $settings.launchAtLogin)
                    .toggleStyle(.switch)
            }
        }
    }

    // MARK: - 行为说明

    private var behaviorSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "trackpad")
                    Text("触控板：保持自然滚动")
                }
                HStack(spacing: 8) {
                    Image(systemName: "computermouse")
                    Text("鼠标滚轮：方向反转")
                }
            }
            .font(.body)
            .padding(.vertical, 4)
        } label: {
            Text("当前行为")
        }
        .padding(.top, 8)
    }

    // MARK: - 冲突提示

    private var conflictNote: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle.fill")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("如已用 Mos、Scroll Reverser 等软件，请确保只开一处")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - 应用规则

    private var appFilterSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("应用单独设置").fontWeight(.medium)
                Spacer()
            }
            .padding(.top, 8)

            if !frontAppName.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "app.fill")
                        .foregroundColor(.accentColor)
                    Text("当前：\(frontAppName)")
                        .fontWeight(.medium)
                }
                .font(.callout)
                .padding(.vertical, 4)
            }

            if !settings.perAppScrollRules.isEmpty {
                ForEach(Array(settings.perAppScrollRules.enumerated()), id: \.element.id) { index, rule in
                    AppRuleRow(
                        rule: rule,
                        onToggle: { settings.perAppScrollRules[index].enabled = $0 },
                        onBehaviorChange: { settings.perAppScrollRules[index].scrollBehavior = $0 },
                        onDelete: { settings.perAppScrollRules.remove(at: index) }
                    )
                    Divider()
                }
            } else {
                Text("未设置应用单独规则")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }

            if !frontAppBundleID.isEmpty, !alreadyHasRule(for: frontAppBundleID) {
                Button(action: addCurrentApp) {
                    Label("为「\(frontAppName)」添加规则", systemImage: "plus")
                        .font(.body)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - 权限提示

    private var permissionWarning: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("未授权辅助功能权限")
                    .fontWeight(.medium)
                Text("系统设置中关闭再勾选 MKey，然后重启生效")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("打开设置") { openAccessibilitySettings() }
                .buttonStyle(.bordered).controlSize(.small)
            Button("刷新") { refreshTrustStatus() }
                .buttonStyle(.bordered).controlSize(.small)
            Button("退出并重启") { restartApp() }
                .buttonStyle(.borderedProminent).controlSize(.small)
        }
        .font(.callout)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.1)))
    }

    // MARK: - 权限轮询

    private func startTrustPollingIfNeeded() {
        guard !isTrusted else { return }
        stopTrustPolling()
        trustPollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if AXIsProcessTrusted() {
                    isTrusted = true
                    stopTrustPolling()
                }
            }
        }
    }

    private func stopTrustPolling() {
        trustPollTimer?.invalidate()
        trustPollTimer = nil
    }

    // MARK: - 辅助

    private func refreshTrustStatus() { isTrusted = AXIsProcessTrusted() }

    private func refreshFrontApp() {
        if let app = NSWorkspace.shared.frontmostApplication {
            frontAppName = app.localizedName ?? ""
            frontAppBundleID = app.bundleIdentifier ?? ""
        }
    }

    private func alreadyHasRule(for id: String) -> Bool {
        settings.perAppScrollRules.contains { $0.bundleID == id }
    }

    private func addCurrentApp() {
        guard !frontAppBundleID.isEmpty else { return }
        settings.perAppScrollRules.append(PerAppScrollRule(
            bundleID: frontAppBundleID,
            appName: frontAppName,
            scrollBehavior: .reversed
        ))
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// 重启：用独立 shell 进程执行 open，确保父进程退出后 shell 仍存活
    private func restartApp() {
        let appPath = Bundle.main.bundlePath
        let script = "sleep 0.3; open \"\(appPath)\""
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", script]
        try? task.run()
        NSApp.terminate(nil)
    }
}

// MARK: - 应用规则行

struct AppRuleRow: View {
    let rule: PerAppScrollRule
    let onToggle: (Bool) -> Void
    let onBehaviorChange: (PerAppScrollRule.ScrollBehavior) -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Toggle("", isOn: Binding(get: { rule.enabled }, set: onToggle))
                .toggleStyle(.switch)
                .scaleEffect(0.75)
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 1) {
                Text(rule.appName).font(.callout)
                Text(rule.bundleID).font(.caption).foregroundColor(.secondary)
            }

            Spacer()

            Picker("", selection: Binding(get: { rule.scrollBehavior }, set: onBehaviorChange)) {
                ForEach(PerAppScrollRule.ScrollBehavior.allCases, id: \.self) { b in
                    Text(b.displayName).tag(b)
                }
            }
            .labelsHidden()
            .frame(width: 80)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}
