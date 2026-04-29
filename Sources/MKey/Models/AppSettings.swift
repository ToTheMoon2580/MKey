import SwiftUI

/// 用户偏好设置，通过 UserDefaults 持久化。
final class AppSettings: ObservableObject {

    static let shared = AppSettings()

    // MARK: - 滚动方向

    @Published var scrollReverseEnabled: Bool {
        didSet {
            UserDefaults.standard.set(scrollReverseEnabled, forKey: .scrollReverseEnabled)
        }
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

        self.scrollReverseEnabled = defaults.bool(forKey: .scrollReverseEnabled)

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
}

// MARK: - UserDefaults Keys

fileprivate extension String {
    static let scrollReverseEnabled = "scrollReverseEnabled"
    static let keyMappings = "keyMappings"
    static let launchAtLogin = "launchAtLogin"
    static let perAppScrollRules = "perAppScrollRules"
    static let eventPreviewExpanded = "eventPreviewExpanded"
}
