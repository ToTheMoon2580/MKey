import SwiftUI

/// 按键捕获按钮：点击后进入"等待按键"模式，按下任意键即捕获其 keyCode。
struct KeyCaptureButton: View {
    let placeholder: String
    @Binding var keyCode: UInt16

    @State private var isCapturing = false
    @State private var capturedName: String = ""
    @State private var localMonitor: Any?

    var body: some View {
        Button(action: startCapture) {
            HStack(spacing: 4) {
                Image(systemName: isCapturing ? "record.circle" : "keyboard")
                    .foregroundColor(isCapturing ? .red : .accentColor)

                Text(displayText)
                    .foregroundColor(keyCode == 0 ? .secondary : .primary)

                if keyCode != 0 && !isCapturing {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isCapturing ? Color.red.opacity(0.08) : Color.gray.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(isCapturing ? Color.red.opacity(0.5) : Color.gray.opacity(0.2))
            )
        }
        .buttonStyle(.plain)
        .onDisappear {
            removeMonitor()
        }
    }

    private var displayText: String {
        if isCapturing {
            return "请按下目标按键…"
        }
        if keyCode == 0 {
            return placeholder
        }
        return capturedName.isEmpty ? KeyCodeHelper.displayName(for: keyCode) : capturedName
    }

    // MARK: - 捕获逻辑

    private func startCapture() {
        // 移除旧监听器
        removeMonitor()
        isCapturing = true

        // 使用本地事件监听捕获下一次按键（仅限本 App 内）
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard self.isCapturing else { return event }
            self.keyCode = UInt16(event.keyCode)
            self.capturedName = KeyCodeHelper.displayName(for: self.keyCode)
            self.isCapturing = false
            self.removeMonitor()
            return nil // 吞掉事件
        }
    }

    private func removeMonitor() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        isCapturing = false
    }
}

// MARK: - 系统动作选择器

/// 系统动作选择组件：下拉选择亮度/音量/调度中心等
struct SystemActionPicker: View {
    let placeholder: String
    @Binding var keyCode: UInt16

    var body: some View {
        Picker(selection: $keyCode) {
            Text(placeholder).tag(UInt16(0))
            ForEach(KeyCodeHelper.systemActions, id: \.code) { action in
                Text(action.name).tag(action.code)
            }
        } label: {
            EmptyView()
        }
        .labelsHidden()
    }
}
