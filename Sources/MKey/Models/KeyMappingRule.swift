import Foundation

/// 单条按键映射规则（键盘键 + 鼠标侧键共用模型）
struct KeyMappingRule: Codable, Identifiable, Equatable {
    let id: UUID

    /// 源按键码（CGKeyCode）
    var sourceKeyCode: UInt16

    /// 目标按键码
    var targetKeyCode: UInt16

    /// 是否同时修改修饰键标志
    var modifyFlags: Bool

    /// 目标修饰键标志（CGEventFlags 的 rawValue）
    var targetFlags: UInt64

    /// 规则名称（用户可自定义，如 "Alt → Command"）
    var displayName: String

    /// 是否启用
    var enabled: Bool

    /// 来源类型：键盘按键 or 鼠标侧键
    var sourceType: SourceType

    enum SourceType: String, Codable {
        case keyboard
        case mouseButton
    }

    init(
        id: UUID = UUID(),
        sourceKeyCode: UInt16,
        targetKeyCode: UInt16,
        modifyFlags: Bool = false,
        targetFlags: UInt64 = 0,
        displayName: String = "",
        enabled: Bool = true,
        sourceType: SourceType = .keyboard
    ) {
        self.id = id
        self.sourceKeyCode = sourceKeyCode
        self.targetKeyCode = targetKeyCode
        self.modifyFlags = modifyFlags
        self.targetFlags = targetFlags
        self.displayName = displayName
        self.enabled = enabled
        self.sourceType = sourceType
    }
}
