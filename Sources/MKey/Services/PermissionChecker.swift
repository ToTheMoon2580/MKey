import Cocoa

/// 辅助功能权限检测与引导
final class PermissionChecker {

    /// 是否已授权辅助功能权限
    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// 检查权限状态，若未授权则弹出提示引导用户开启
    func checkAndPrompt() -> Bool {
        if isTrusted {
            return true
        }

        let alert = NSAlert()
        alert.messageText = "需要辅助功能权限"
        alert.informativeText = """
        MKey 需要辅助功能权限才能拦截鼠标和键盘事件。

        请在弹出的「系统设置」窗口中：
        1. 点击左下角 🔒 解锁
        2. 找到并勾选 MKey
        3. 返回 MKey 即可生效
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后设置")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            // 打开系统设置 → 辅助功能面板
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }

        return false
    }
}
