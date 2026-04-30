import SwiftUI

/// 用户偏好设置，通过 UserDefaults 持久化。
final class AppSettings: ObservableObject {

    static let shared = AppSettings()

    // MARK: - 滚动方向（触控板 / 鼠标各自独立）

    @Published var trackpadScrollBehavior: PerAppScrollRule.ScrollBehavior {
        didSet { saveScrollBehavior(.trackpadScrollBehavior, value: trackpadScrollBehavior.rawValue) }
    }

    @Published var mouseScrollBehavior: PerAppScrollRule.ScrollBehavior {
        didSet { saveScrollBehavior(.mouseScrollBehavior, value: mouseScrollBehavior.rawValue) }
    }

    private func saveScrollBehavior(_ key: String, value: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    // MARK: - 键盘映射

    @Published var keyMappings: [KeyMappingRule] {
        didSet {
            if let data = try? JSONEncoder().encode(keyMappings) {
                UserDefaults.standard.set(data, forKey: .keyMappings)
            }
        }
    }

    // MARK: - 开机自启

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: .launchAtLogin)
            LaunchManager.shared.setEnabled(launchAtLogin)
        }
    }

    // MARK: - 应用过滤滚动规则

    @Published var perAppScrollRules: [PerAppScrollRule] {
        didSet {
            if let data = try? JSONEncoder().encode(perAppScrollRules) {
                UserDefaults.standard.set(data, forKey: .perAppScrollRules)
            }
        }
    }

    // MARK: - 事件预览

    @Published var eventPreviewExpanded: Bool {
        didSet {
            UserDefaults.standard.set(eventPreviewExpanded, forKey: .eventPreviewExpanded)
        }
    }

    private init() {
        let defaults = UserDefaults.standard

        // 读取滚动行为（含旧版迁移）
        let behaviors = Self.loadScrollBehaviors(from: defaults)
        self.trackpadScrollBehavior = behaviors.trackpad
        self.mouseScrollBehavior = behaviors.mouse

        // 键盘映射
        if let data = defaults.data(forKey: .keyMappings),
           let mappings = try? JSONDecoder().decode([KeyMappingRule].self, from: data) {
            self.keyMappings = mappings
        } else {
            self.keyMappings = []
        }

        self.launchAtLogin = defaults.bool(forKey: .launchAtLogin)

        if let data = defaults.data(forKey: .perAppScrollRules),
           let rules = try? JSONDecoder().decode([PerAppScrollRule].self, from: data) {
            self.perAppScrollRules = rules
        } else {
            self.perAppScrollRules = []
        }

        if defaults.object(forKey: .eventPreviewExpanded) != nil {
            self.eventPreviewExpanded = defaults.bool(forKey: .eventPreviewExpanded)
        } else {
            self.eventPreviewExpanded = true
        }
    }

    /// 读取触控板/鼠标行为，含旧版单 bool 自动迁移
    private static func loadScrollBehaviors(from defaults: UserDefaults) -> (trackpad: PerAppScrollRule.ScrollBehavior, mouse: PerAppScrollRule.ScrollBehavior) {
        // 新版数据
        if let rawT = defaults.string(forKey: .trackpadScrollBehavior),
           let rawM = defaults.string(forKey: .mouseScrollBehavior),
           let t = PerAppScrollRule.ScrollBehavior(rawValue: rawT),
           let m = PerAppScrollRule.ScrollBehavior(rawValue: rawM) {
            return (t, m)
        }

        // 旧版迁移
        let wasEnabled = defaults.bool(forKey: .scrollReverseEnabled)
        let trackpad: PerAppScrollRule.ScrollBehavior = wasEnabled ? .natural : .systemDefault
        let mouse: PerAppScrollRule.ScrollBehavior    = wasEnabled ? .reversed : .systemDefault

        // 写入新版 key，清理旧版
        defaults.set(trackpad.rawValue, forKey: .trackpadScrollBehavior)
        defaults.set(mouse.rawValue, forKey: .mouseScrollBehavior)
        defaults.removeObject(forKey: .scrollReverseEnabled)

        return (trackpad, mouse)
    }
}

// MARK: - UserDefaults Keys

fileprivate extension String {
    static let scrollReverseEnabled = "scrollReverseEnabled"
    static let trackpadScrollBehavior = "trackpadScrollBehavior"
    static let mouseScrollBehavior = "mouseScrollBehavior"
    static let keyMappings = "keyMappings"
    static let launchAtLogin = "launchAtLogin"
    static let perAppScrollRules = "perAppScrollRules"
    static let eventPreviewExpanded = "eventPreviewExpanded"
}
