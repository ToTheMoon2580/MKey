import Foundation

/// 单个应用滚动方向规则
struct PerAppScrollRule: Codable, Identifiable, Equatable {
    let id: UUID
    var bundleID: String
    var appName: String
    var scrollBehavior: ScrollBehavior
    var enabled: Bool

    enum ScrollBehavior: String, Codable, CaseIterable {
        /// 自然滚动（触控板风格：手指上推 = 页面上滚）
        case natural
        /// 反转滚动（鼠标风格：滚轮上滚 = 页面上滚，即反转系统方向）
        case reversed

        var displayName: String {
            switch self {
            case .natural: return "自然滚动"
            case .reversed: return "反转滚动"
            }
        }
    }

    init(
        id: UUID = UUID(),
        bundleID: String,
        appName: String,
        scrollBehavior: ScrollBehavior = .reversed,
        enabled: Bool = true
    ) {
        self.id = id
        self.bundleID = bundleID
        self.appName = appName
        self.scrollBehavior = scrollBehavior
        self.enabled = enabled
    }
}
