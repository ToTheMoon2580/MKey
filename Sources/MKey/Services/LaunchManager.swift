import Foundation

/// 开机自启管理：通过 ~/Library/LaunchAgents/ 下的 plist 实现。
/// 兼容 macOS 12+，不依赖 SMAppService（需 macOS 13+）。
final class LaunchManager {

    static let shared = LaunchManager()

    private var plistURL: URL {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
        return dir.appendingPathComponent("com.mkey.launcher.plist")
    }

    /// 当前是否已启用开机自启
    var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    /// 启用开机自启
    func enable() {
        guard !isEnabled else { return }

        // 确保 LaunchAgents 目录存在
        let dir = plistURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let executablePath = ProcessInfo.processInfo.arguments[0]

        let plist: [String: Any] = [
            "Label": "com.mkey.launcher",
            "ProgramArguments": [executablePath],
            "RunAtLoad": true,
            "KeepAlive": false,
            "ProcessType": "Background",
        ]

        guard let data = try? PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        ) else {
            print("[MKey] 无法生成 LaunchAgent plist")
            return
        }

        do {
            try data.write(to: plistURL, options: .atomic)
            print("[MKey] 已启用开机自启: \(plistURL.path)")
        } catch {
            print("[MKey] 写入 LaunchAgent 失败: \(error)")
        }
    }

    /// 禁用开机自启
    func disable() {
        guard isEnabled else { return }
        do {
            try FileManager.default.removeItem(at: plistURL)
            print("[MKey] 已禁用开机自启")
        } catch {
            print("[MKey] 移除 LaunchAgent 失败: \(error)")
        }
    }

    /// 切换开关
    func setEnabled(_ enabled: Bool) {
        if enabled {
            enable()
        } else {
            disable()
        }
    }
}
