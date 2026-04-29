import Foundation

/// 预设方案模型
struct KeyMappingPreset: Identifiable {
    let id: String
    let name: String
    let description: String
    let rules: [KeyMappingRule]

    /// 内置预设方案
    static let builtInPresets: [KeyMappingPreset] = [
        filcoStandard,
        cherryStandard,
        keychronStandard,
    ]

    // MARK: - Filco / 标准 PC 键盘

    /// PC 键盘经典映射：Alt → Command，Win → Option
    static let filcoStandard = KeyMappingPreset(
        id: "filco_standard",
        name: "Filco / 标准 PC 键盘",
        description: "交换 Alt 与 Win 键，使 PC 键盘的 Alt 映射为 Command，Win 映射为 Option",
        rules: [
            // 左 Alt (0x3A) → 左 Command (0x37)
            KeyMappingRule(
                sourceKeyCode: 0x3A,
                targetKeyCode: 0x37,
                displayName: "Alt (左) → Command (左)",
                sourceType: .keyboard
            ),
            // 右 Alt (0x3D) → 右 Command (0x36)
            KeyMappingRule(
                sourceKeyCode: 0x3D,
                targetKeyCode: 0x36,
                displayName: "Alt (右) → Command (右)",
                sourceType: .keyboard
            ),
            // 左 Win (0x37) → 左 Option (0x3A)
            KeyMappingRule(
                sourceKeyCode: 0x37,
                targetKeyCode: 0x3A,
                displayName: "Win (左) → Option (左)",
                sourceType: .keyboard
            ),
            // 右 Win (0x36) → 右 Option (0x3D)
            KeyMappingRule(
                sourceKeyCode: 0x36,
                targetKeyCode: 0x3D,
                displayName: "Win (右) → Option (右)",
                sourceType: .keyboard
            ),
        ]
    )

    // MARK: - Cherry 键盘

    /// Cherry 键盘默认映射（与 Filco 类似，部分型号可能需要额外映射）
    static let cherryStandard = KeyMappingPreset(
        id: "cherry_standard",
        name: "Cherry 键盘",
        description: "适配 Cherry 机械键盘，交换 Alt / Win 键位",
        rules: [
            KeyMappingRule(
                sourceKeyCode: 0x3A,
                targetKeyCode: 0x37,
                displayName: "Alt (左) → Command (左)",
                sourceType: .keyboard
            ),
            KeyMappingRule(
                sourceKeyCode: 0x3D,
                targetKeyCode: 0x36,
                displayName: "Alt (右) → Command (右)",
                sourceType: .keyboard
            ),
            KeyMappingRule(
                sourceKeyCode: 0x37,
                targetKeyCode: 0x3A,
                displayName: "Win (左) → Option (左)",
                sourceType: .keyboard
            ),
            KeyMappingRule(
                sourceKeyCode: 0x36,
                targetKeyCode: 0x3D,
                displayName: "Win (右) → Option (右)",
                sourceType: .keyboard
            ),
        ]
    )

    // MARK: - Keychron 键盘

    /// Keychron 键盘：出厂 Mac 模式无需映射，Win 模式下与 Filco 相同
    static let keychronStandard = KeyMappingPreset(
        id: "keychron_standard",
        name: "Keychron 键盘 (Win 模式)",
        description: "Keychron 切换到 Win 模式时的键位映射，使 Win / Alt 键符合 Mac 习惯",
        rules: [
            KeyMappingRule(
                sourceKeyCode: 0x3A,
                targetKeyCode: 0x37,
                displayName: "Alt (左) → Command (左)",
                sourceType: .keyboard
            ),
            KeyMappingRule(
                sourceKeyCode: 0x3D,
                targetKeyCode: 0x36,
                displayName: "Alt (右) → Command (右)",
                sourceType: .keyboard
            ),
            KeyMappingRule(
                sourceKeyCode: 0x37,
                targetKeyCode: 0x3A,
                displayName: "Win (左) → Option (左)",
                sourceType: .keyboard
            ),
            KeyMappingRule(
                sourceKeyCode: 0x36,
                targetKeyCode: 0x3D,
                displayName: "Win (右) → Option (右)",
                sourceType: .keyboard
            ),
        ]
    )
}
