import SwiftUI
import Cocoa

struct ScrollTab: View {
    @StateObject private var settings = AppSettings.shared
    @State private var isTrusted = AXIsProcessTrusted()
    @State private var frontAppName: String = ""
    @State private var frontAppBundleID: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 权限状态提示
            if !isTrusted {
                permissionWarning
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            // 全局开关 + 开机自启
            globalSection
                .padding(.horizontal)

            Divider().padding(.horizontal)

            // 行为说明
            behaviorSection
                .padding(.horizontal)

            Divider().padding(.horizontal)

            // 应用过滤
            appFilterSection

            Spacer(minLength: 0)
        }
        .onAppear {
            refreshTrustStatus()
            refreshFrontApp()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshTrustStatus()
            refreshFrontApp()
        }
    }

    // MARK: - 全局开关 + 开机自启

    private var globalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            VStack(alignment: .leading, spacing: 2) {
                Text("触控板 / 鼠标滚动方向独立控制")
                    .font(.headline)
                Text("触控板保持自然滚动，鼠标滚轮方向反转")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)

            // 全局开关
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("启用滚动方向独立控制")
                        .font(.body)
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(statusColor)
                }
                Spacer()
                Toggle("", isOn: $settings.scrollReverseEnabled)
                    .toggleStyle(.switch)
            }

            // 开机自启
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("开机自动启动")
                        .font(.body)
                    Text(settings.launchAtLogin ? "登录时自动运行" : "需手动启动")
                        .font(.caption)
                        .foregroundColor(settings.launchAtLogin ? .green : .secondary)
                }
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
                        .font(.callout)
                }
                HStack(spacing: 8) {
                    Image(systemName: "computermouse")
                    Text("鼠标滚轮：方向反转 ↑→↓")
                        .font(.callout)
                }
            }
            .padding(.vertical, 4)
        } label: {
            Text("当前行为")
        }
        .padding(.top, 4)
    }

    // MARK: - 应用过滤

    private var appFilterSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("应用单独设置")
                    .font(.callout)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 6)

            // 当前前台应用
            if !frontAppName.isEmpty {
                currentAppBar
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }

            // 规则列表
            if settings.perAppScrollRules.isEmpty {
                emptyRulesHint
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(settings.perAppScrollRules.enumerated()), id: \.element.id) { index, rule in
                            AppRuleRow(
                                rule: rule,
                                onToggle: { enabled in
                                    settings.perAppScrollRules[index].enabled = enabled
                                },
                                onBehaviorChange: { behavior in
                                    settings.perAppScrollRules[index].scrollBehavior = behavior
                                },
                                onDelete: {
                                    settings.perAppScrollRules.remove(at: index)
                                }
                            )
                            if rule.id != settings.perAppScrollRules.last?.id {
                                Divider().padding(.leading, 42)
                            }
                        }
                    }
                }
                .frame(maxHeight: 160)
            }

            // 添加当前 App 按钮
            if !frontAppBundleID.isEmpty && !alreadyHasRule(for: frontAppBundleID) {
                Button(action: addCurrentApp) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                        Text("为「\(frontAppName)」添加规则")
                    }
                }
                .buttonStyle(.borderless)
                .padding(.horizontal)
                .padding(.top, 4)
            }
        }
    }

    private var currentAppBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "app.fill")
                .font(.caption)
                .foregroundColor(.accentColor)
            Text("当前前台应用: ")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(frontAppName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.08))
        )
    }

    private var emptyRulesHint: some View {
        VStack(spacing: 4) {
            Image(systemName: "app.dashed")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("未设置应用单独规则")
                .font(.callout)
                .foregroundColor(.secondary)
            Text("切换到目标应用后，点击上方按钮添加")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    // MARK: - 权限提示

    private var permissionWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("未授权辅助功能权限")
                    .font(.callout).fontWeight(.medium)
                Text("MKey 需要此权限才能拦截鼠标事件")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Button("打开系统设置") { openAccessibilitySettings() }
                .buttonStyle(.borderedProminent).controlSize(.small)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.1)))
    }

    // MARK: - 状态文案

    private var statusText: String {
        if !isTrusted { return "缺少权限，无法生效" }
        return settings.scrollReverseEnabled ? "鼠标滚轮方向已反转" : "已关闭"
    }

    private var statusColor: Color {
        if !isTrusted { return .orange }
        return settings.scrollReverseEnabled ? .green : .secondary
    }

    // MARK: - 辅助方法

    private func refreshTrustStatus() {
        isTrusted = AXIsProcessTrusted()
    }

    private func refreshFrontApp() {
        if let app = NSWorkspace.shared.frontmostApplication {
            frontAppName = app.localizedName ?? ""
            frontAppBundleID = app.bundleIdentifier ?? ""
        }
    }

    private func alreadyHasRule(for bundleID: String) -> Bool {
        settings.perAppScrollRules.contains { $0.bundleID == bundleID }
    }

    private func addCurrentApp() {
        guard !frontAppBundleID.isEmpty, !alreadyHasRule(for: frontAppBundleID) else { return }
        let rule = PerAppScrollRule(
            bundleID: frontAppBundleID,
            appName: frontAppName,
            scrollBehavior: .reversed
        )
        settings.perAppScrollRules.append(rule)
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
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
                .scaleEffect(0.7)
                .frame(width: 32)

            Image(systemName: "app.fill")
                .font(.caption)
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 1) {
                Text(rule.appName)
                    .font(.callout)
                Text(rule.bundleID)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Picker("", selection: Binding(get: { rule.scrollBehavior }, set: onBehaviorChange)) {
                ForEach(PerAppScrollRule.ScrollBehavior.allCases, id: \.self) { behavior in
                    Text(behavior.displayName).tag(behavior)
                }
            }
            .labelsHidden()
            .frame(width: 80)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}
