import SwiftUI
import Cocoa

struct ScrollTab: View {
    @StateObject private var settings = AppSettings.shared
    @State private var isTrusted = AXIsProcessTrusted()
    @State private var frontAppName: String = ""
    @State private var frontAppBundleID: String = ""
    @State private var trustPollTimer: Timer?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 权限警告
                if !isTrusted { permissionWarning }

                // 区域一：全局控制
                SectionHeader(icon: "arrow.up.arrow.down",
                              title: "滚动方向",
                              subtitle: "分别控制触控板和鼠标的滚动方向")
                    .padding(.top, isTrusted ? 16 : 8)

                ToggleRow(label: "启用独立控制",
                          description: "开启后触控板与鼠标各管各的",
                          isOn: $settings.scrollReverseEnabled)
                    .disabled(!isTrusted)

                thinDivider

                ToggleRow(label: "开机自动启动",
                          description: "登录时自动在后台运行",
                          isOn: $settings.launchAtLogin)

                thickDivider

                // 区域二：当前效果
                SectionHeader(icon: "eye",
                              title: "当前效果",
                              subtitle: "开启后触控板保持原生，鼠标滚轮反转")

                StatusRow(icon: "hand.point.up.fill",
                          label: "触控板",
                          value: settings.scrollReverseEnabled ? "自然滚动（原生）" : "跟随系统",
                          active: settings.scrollReverseEnabled)

                thinDivider

                StatusRow(icon: "computermouse.fill",
                          label: "鼠标滚轮",
                          value: settings.scrollReverseEnabled ? "方向反转 ↑→↓" : "跟随系统",
                          active: settings.scrollReverseEnabled,
                          accentColor: .orange)

                thickDivider

                // 区域三：应用单独设置
                SectionHeader(icon: "apps.iphone",
                              title: "应用单独设置",
                              subtitle: "为特定 App 单独设定滚动方向")

                // 当前前台应用 + 提示 + 添加按钮
                if !frontAppName.isEmpty {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "app.fill")
                                .foregroundColor(.accentColor)
                            Text(frontAppName)
                                .fontWeight(.medium)
                            Text("· 当前前台")
                                .foregroundColor(.secondary)
                        }
                        .font(.callout)

                        Spacer()

                        if alreadyHasRule(for: frontAppBundleID) {
                            Label("已添加", systemImage: "checkmark.circle.fill")
                                .font(.callout)
                                .foregroundColor(.green)
                        } else {
                            Button(action: addCurrentApp) {
                                Label("添加规则", systemImage: "plus")
                                    .font(.callout)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                Text("也可通过菜单栏 «为当前应用添加滚动规则» 快捷添加")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)

                // 规则列表或空状态
                if settings.perAppScrollRules.isEmpty {
                    emptyRulesView
                } else {
                    VStack(spacing: 0) {
                        thinDivider
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
                }

                Color.clear.frame(height: 24)
            }
        }
        .onAppear {
            refreshTrustStatus()
            refreshFrontApp()
            startTrustPollingIfNeeded()
            startFrontAppObserver()
        }
        .onDisappear {
            stopTrustPolling()
            stopFrontAppObserver()
        }
        // 当 MKey 自身被激活时也刷新
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshTrustStatus()
            refreshFrontApp()
        }
    }

    // MARK: - 前台 App 实时追踪

    /// 监听全局前台 App 切换：设置窗口浮动置顶时，点其他 App 也会实时更新
    private func startFrontAppObserver() {
        stopFrontAppObserver()
        let observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let runningApp = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                frontAppName = runningApp.localizedName ?? ""
                frontAppBundleID = runningApp.bundleIdentifier ?? ""
            }
        }
        // 用 UUID 存储引用，绕过 @State 对 non-Sendable 的限制
        let token = UUID().uuidString
        _frontAppObserverToken = token
        Self.activeObservers[token] = observer
    }

    private func stopFrontAppObserver() {
        if let token = _frontAppObserverToken {
            if let observer = Self.activeObservers[token] {
                NSWorkspace.shared.notificationCenter.removeObserver(observer)
                Self.activeObservers.removeValue(forKey: token)
            }
            _frontAppObserverToken = nil
        }
    }

    @State private var _frontAppObserverToken: String?
    private static var activeObservers: [String: NSObjectProtocol] = [:]

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
            Text("切换到目标 App 后，点击上方「添加规则」即可")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
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
                .foregroundColor(active ? .primary : .secondary)

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(active ? accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
                Text(value)
                    .font(.callout)
                    .foregroundColor(active ? .primary : .secondary)
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
                Image(systemName: "trash").foregroundColor(.red)
            }
            .buttonStyle(.borderless).controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}
