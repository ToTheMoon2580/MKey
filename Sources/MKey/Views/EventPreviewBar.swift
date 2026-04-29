import SwiftUI

/// 设置窗口底部常驻事件预览条：窄条状，可折叠（默认展开）。
struct EventPreviewBar: View {
    @StateObject private var broadcaster = EventBroadcaster.shared
    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            // 折叠/展开按钮
            HStack {
                Text("事件预览")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: { withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help(isExpanded ? "收起预览" : "展开预览")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            if isExpanded {
                previewContent
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 预览内容

    private var previewContent: some View {
        HStack(spacing: 0) {
            // 键盘区域
            keyboardSection

            if hasAnyEvent {
                Divider().frame(height: 24)
            }

            // 滚轮区域
            scrollSection

            if hasScrollAndButton {
                Divider().frame(height: 24)
            }

            // 鼠标按键区域
            mouseSection

            Spacer(minLength: 8)

            // 清空提示
            if !hasAnyEvent {
                Text("等待输入…")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(height: 36)
    }

    // MARK: - 键盘段

    @ViewBuilder
    private var keyboardSection: some View {
        if let event = broadcaster.keyboardEvent, event.isKeyDown {
            HStack(spacing: 6) {
                Image(systemName: "keyboard")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // 按键名
                Text(event.keyName ?? "?")
                    .font(.system(.callout, design: .monospaced))
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primary.opacity(0.08))
                    )

                // 映射触发提示
                if event.isMapped, let ruleName = event.mappingRuleName {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.swap")
                            .font(.system(size: 8))
                        Text(ruleName)
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
        }
    }

    // MARK: - 滚轮段

    @ViewBuilder
    private var scrollSection: some View {
        if let event = broadcaster.scrollEvent {
            HStack(spacing: 6) {
                Image(systemName: "scroll")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // 方向箭头
                Text(event.scrollDirection?.rawValue ?? "?")
                    .font(.system(.callout, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(event.scrollDirection == .up ? .green : .blue)

                // 设备类型
                Text(event.isTrackpad ? "触控板" : "鼠标")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.08))
                    )
            }
        }
    }

    // MARK: - 鼠标按键段

    @ViewBuilder
    private var mouseSection: some View {
        if let event = broadcaster.mouseButtonEvent {
            HStack(spacing: 6) {
                Image(systemName: "computermouse")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(event.buttonName ?? "?")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primary.opacity(0.08))
                    )

                // 映射触发
                if event.isMapped, let ruleName = event.mappingRuleName {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.swap")
                            .font(.system(size: 8))
                        Text(ruleName)
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
        }
    }

    // MARK: - 辅助

    private var hasAnyEvent: Bool {
        keyboardSectionActive || scrollSectionActive || mouseSectionActive
    }

    private var keyboardSectionActive: Bool {
        broadcaster.keyboardEvent?.isKeyDown == true
    }

    private var scrollSectionActive: Bool {
        broadcaster.scrollEvent != nil
    }

    private var mouseSectionActive: Bool {
        broadcaster.mouseButtonEvent != nil
    }

    private var hasScrollAndButton: Bool {
        scrollSectionActive && mouseSectionActive
    }
}
