import SwiftUI
import Cocoa

struct ScrollTab: View {
    @StateObject private var settings = AppSettings.shared
    @State private var isTrusted = AXIsProcessTrusted()
    @State private var trustPollTimer: Timer?
    @State private var showAppPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 权限警告
                if !isTrusted { permissionWarning }

                // 区域一：全局控制
                SectionHeader(icon: "arrow.up.arrow.down",
                              title: "滚动方向",
                              subtitle: "触控板和鼠标各自独立设置，互不影响")
                    .padding(.top, isTrusted ? 16 : 8)

                // 触控板
                BehaviorRow(
                    icon: "hand.point.up.fill",
                    label: "触控板",
                    behavior: $settings.trackpadScrollBehavior,
                    disabled: !isTrusted
                )

                thinDivider

                // 鼠标
                BehaviorRow(
                    icon: "computermouse.fill",
                    label: "鼠标滚轮",
                    behavior: $settings.mouseScrollBehavior,
                    disabled: !isTrusted
                )

                thinDivider

                ToggleRow(label: "开机自动启动",
                          description: "登录时自动在后台运行",
                          isOn: $settings.launchAtLogin)

                thickDivider
                
                // 区域二：应用单独设置
                SectionHeader(icon: "apps.iphone",
                              title: "应用单独设置",
                              subtitle: "为特定 App 单独设定滚动方向")

                if settings.perAppScrollRules.isEmpty {
                    emptyRulesView
                } else {
                    ForEach(Array(settings.perAppScrollRules.enumerated()), id: \.element.id) { index, rule in
                        AppRuleRow(
                            rule: rule,
                            onToggle: { settings.perAppScrollRules[index].enabled = $0 },
                            onBehaviorChange: { settings.perAppScrollRules[index].scrollBehavior = $0 },
                            onDelete: { settings.perAppScrollRules.remove(at: index) }
                        )
                        if index < settings.perAppScrollRules.count - 1 {
                            thinDivider
                        }
                    }
                }

                HStack {
                    Button(action: { showAppPicker = true }) {
                        Label("添加应用", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    Spacer()
                }

                Text("也可通过菜单栏 ⌨ →「为当前应用添加滚动规则」快捷添加")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                Color.clear.frame(height: 24)
            }
        }
        .onAppear {
            refreshTrustStatus()
            startTrustPollingIfNeeded()
        }
        .onDisappear { stopTrustPolling() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshTrustStatus()
        }
        .sheet(isPresented: $showAppPicker) {
            AppPickerSheet(isPresented: $showAppPicker) { bundleID, name in
                guard !settings.perAppScrollRules.contains(where: { $0.bundleID == bundleID }) else { return }
                settings.perAppScrollRules.append(PerAppScrollRule(
                    bundleID: bundleID,
                    appName: name,
                    scrollBehavior: .reversed
                ))
            }
        }
    }

    // MARK: - 权限警告

    private var permissionWarning: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("需要辅助功能权限")
                    .fontWeight(.medium)
                Text("请在系统设置中授权 MKey 以拦截事件")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 6) {
                Button("打开设置") { openAccessibilitySettings() }
                    .buttonStyle(.bordered).controlSize(.small)
                Button("刷新") { refreshTrustStatus() }
                    .buttonStyle(.bordered).controlSize(.small)
                Button("退出并重启") { restartApp() }
                    .buttonStyle(.borderedProminent).controlSize(.small)
            }
        }
        .font(.callout)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.1)))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - 空规则提示

    private var emptyRulesView: some View {
        VStack(spacing: 8) {
            Image(systemName: "app.dashed")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("还没有为任何应用设置特殊规则")
                .font(.callout)
                .foregroundColor(.secondary)
            Text("点击下方按钮，从已安装应用中选择")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - 分隔线

    private var thinDivider: some View {
        Divider().padding(.leading, 16)
    }

    private var thickDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.06))
            .frame(height: 8)
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

    private func refreshTrustStatus() { isTrusted = AXIsProcessTrusted() }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func restartApp() {
        let appPath = Bundle.main.bundlePath
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "sleep 0.3; open \"\(appPath)\""]
        try? task.run()
        NSApp.terminate(nil)
    }
}

// MARK: - 通用组件

/// 区域标题
struct SectionHeader: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                    .frame(width: 18)
                Text(title)
                    .font(.headline)
            }
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 24)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

/// 开关行
struct ToggleRow: View {
    let label: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.body)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

/// 设备行为选择行
struct BehaviorRow: View {
    let icon: String
    let label: String
    @Binding var behavior: PerAppScrollRule.ScrollBehavior
    var disabled: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(label)
                .font(.callout)

            Spacer()

            Picker("", selection: $behavior) {
                Text("自然滚动").tag(PerAppScrollRule.ScrollBehavior.natural)
                Text("反转滚动").tag(PerAppScrollRule.ScrollBehavior.reversed)
                Text("跟随系统").tag(PerAppScrollRule.ScrollBehavior.systemDefault)
            }
            .labelsHidden()
            .frame(width: 100)
            .disabled(disabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

/// 状态指示行
struct StatusRow: View {
    let icon: String
    let label: String
    let value: String
    var active: Bool = true
    var accentColor: Color = .green

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(label)
                .font(.callout)
                .foregroundColor(.primary)

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(active ? accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
                Text(value)
                    .font(.callout)
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - 应用规则行

struct AppRuleRow: View {
    let rule: PerAppScrollRule
    let onToggle: (Bool) -> Void
    let onBehaviorChange: (PerAppScrollRule.ScrollBehavior) -> Void
    let onDelete: () -> Void

    /// 应用规则只允许 自然/反转，不显示「跟随系统」
    private var appBehaviors: [PerAppScrollRule.ScrollBehavior] {
        [.natural, .reversed]
    }

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
                ForEach(appBehaviors, id: \.self) { b in
                    Text(b.displayName).tag(b)
                }
            }
            .labelsHidden()
            .frame(width: 80)

            Button(action: onDelete) {
                Image(systemName: "trash").foregroundColor(.red)
            }
            .buttonStyle(.borderless).controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}
