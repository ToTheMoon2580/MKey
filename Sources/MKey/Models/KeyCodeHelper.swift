import Carbon

/// CGKeyCode → 中文显示名 映射表
enum KeyCodeHelper {

    /// 返回按键中文名
    static func displayName(for keyCode: UInt16) -> String {
        keyNameMap[Int(keyCode)] ?? "按键 \(keyCode)"
    }

    /// 返回修饰键列表的合并名称（如 "⌘⇧A"）
    static func shortcutName(keyCode: UInt16, flags: UInt64) -> String {
        let f = CGEventFlags(rawValue: flags)
        var parts: [String] = []
        if f.contains(.maskCommand) { parts.append("⌘") }
        if f.contains(.maskShift)   { parts.append("⇧") }
        if f.contains(.maskAlternate){ parts.append("⌥") }
        if f.contains(.maskControl) { parts.append("⌃") }
        parts.append(displayName(for: keyCode))
        return parts.joined()
    }

    /// 常用按键的中文名字典
    static let keyNameMap: [Int: String] = [
        // 字母
        0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F",
        0x04: "H", 0x05: "G", 0x06: "Z", 0x07: "X",
        0x08: "C", 0x09: "V", 0x0B: "B", 0x0C: "Q",
        0x0D: "W", 0x0E: "E", 0x0F: "R", 0x10: "Y",
        0x11: "T", 0x1F: "O", 0x20: "U", 0x22: "I",
        0x23: "P", 0x25: "L", 0x26: "J", 0x28: "K",
        0x2D: "N", 0x2E: "M",

        // 数字
        0x12: "1", 0x13: "2", 0x14: "3", 0x15: "4",
        0x16: "6", 0x17: "5", 0x19: "9", 0x1A: "7",
        0x1C: "8", 0x1D: "0",

        // 标点
        0x18: "=", 0x1B: "-", 0x1E: "]", 0x21: "[",
        0x27: "'", 0x29: ";", 0x2A: "\\", 0x2B: ",",
        0x2C: "/", 0x2F: ".", 0x32: "`",

        // 功能键
        0x7A: "F1",  0x78: "F2",  0x63: "F3",  0x76: "F4",
        0x60: "F5",  0x61: "F6",  0x62: "F7",  0x64: "F8",
        0x65: "F9",  0x6D: "F10", 0x67: "F11", 0x6F: "F12",
        0x69: "F13", 0x6B: "F14", 0x71: "F15", 0x6A: "F16",
        0x40: "F17", 0x4F: "F18", 0x50: "F19", 0x5A: "F20",

        // 修饰键
        0x37: "Command (左)", 0x36: "Command (右)",
        0x3A: "Option (左)",  0x3D: "Option (右)",
        0x3B: "Control (左)", 0x3E: "Control (右)",
        0x38: "Shift (左)",   0x3C: "Shift (右)",
        0x39: "Caps Lock",    0x3F: "Fn",

        // 特殊键
        0x24: "Return / Enter",
        0x30: "Tab",
        0x31: "空格",
        0x33: "Delete (退格)",
        0x35: "Escape",
        0x75: "Delete (前删)",
        0x73: "Home",
        0x77: "End",
        0x74: "Page Up",
        0x79: "Page Down",
        0x72: "Insert",

        // 方向键
        0x7B: "←", 0x7C: "→",
        0x7E: "↑", 0x7D: "↓",

        // 数字键盘
        0x52: "Num 0", 0x53: "Num 1", 0x54: "Num 2",
        0x55: "Num 3", 0x56: "Num 4", 0x57: "Num 5",
        0x58: "Num 6", 0x59: "Num 7", 0x5B: "Num 8",
        0x5C: "Num 9", 0x41: "Num .", 0x4B: "Num /",
        0x43: "Num *", 0x45: "Num +", 0x4E: "Num -",
        0x4C: "Num Enter", 0x51: "Num =", 0x47: "Num Clear",

        // 系统动作（NX 特殊键，用作目标）
        0x90: "亮度降低", 0x91: "亮度升高",
        0x92: "音量降低", 0x93: "音量升高",
        0x94: "静音",
        0x95: "播放/暂停", 0x96: "下一首", 0x97: "上一首",
        0x98: "调度中心", 0x99: "启动台",
        0x9A: "键盘亮度降低", 0x9B: "键盘亮度升高",
    ]

    /// 可选的系统动作目标列表（用于映射目标选择器）
    static let systemActions: [(code: UInt16, name: String)] = [
        (0x90, "亮度降低"),
        (0x91, "亮度升高"),
        (0x92, "音量降低"),
        (0x93, "音量升高"),
        (0x94, "静音"),
        (0x95, "播放/暂停"),
        (0x96, "下一首"),
        (0x97, "上一首"),
        (0x98, "调度中心"),
        (0x99, "启动台"),
        (0x9A, "键盘亮度降低"),
        (0x9B, "键盘亮度升高"),
    ]
}
