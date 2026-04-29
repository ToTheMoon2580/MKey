import Cocoa
import CoreGraphics

/// 键盘 + 鼠标侧键事件拦截器
/// 查找用户映射规则，匹配时替换 keyCode / flags；鼠标侧键映射触发时吞掉原始事件并发出键盘快捷键。
final class KeyInterceptor {

    private var eventTap: CFMachPort?

    func start() {
        guard eventTap == nil else { return }

        let eventMask = (1 << CGEventType.keyDown.rawValue)
                      | (1 << CGEventType.keyUp.rawValue)
                      | (1 << CGEventType.otherMouseDown.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (_, type, event, userInfo) -> Unmanaged<CGEvent>? in
                let interceptor = Unmanaged<KeyInterceptor>
                    .fromOpaque(userInfo!)
                    .takeUnretainedValue()
                return interceptor.handleEvent(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let tap = eventTap else {
            print("[MKey] KeyInterceptor: 无法创建事件监听，请确认已授予辅助功能权限")
            return
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
            eventTap = nil
        }
    }

    // MARK: - 事件路由

    private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .keyDown:
            return handleKeyEvent(event: event, isKeyDown: true)
        case .keyUp:
            return handleKeyEvent(event: event, isKeyDown: false)
        case .otherMouseDown:
            return handleMouseButton(event: event)
        default:
            return Unmanaged.passUnretained(event)
        }
    }

    // MARK: - 键盘映射

    private func handleKeyEvent(event: CGEvent, isKeyDown: Bool) -> Unmanaged<CGEvent>? {
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let mapping = findMapping(keyCode: keyCode, sourceType: .keyboard)

        // 推送到事件预览面板（替换前推送原始按键）
        EventBroadcaster.shared.pushKeyboard(keyCode: keyCode, isKeyDown: isKeyDown, mapping: mapping)

        guard let mapping = mapping else {
            return Unmanaged.passUnretained(event)
        }

        // 替换目标按键码
        event.setIntegerValueField(.keyboardEventKeycode, value: Int64(mapping.targetKeyCode))

        // 若有修饰键覆写，一并替换 flags
        if mapping.modifyFlags {
            event.flags = CGEventFlags(rawValue: mapping.targetFlags)
        }

        return Unmanaged.passUnretained(event)
    }

    // MARK: - 鼠标侧键映射

    private func handleMouseButton(event: CGEvent) -> Unmanaged<CGEvent>? {
        let buttonNumber = event.getIntegerValueField(.mouseEventButtonNumber)

        // 侧键 1 = 3, 侧键 2 = 4
        guard buttonNumber == 3 || buttonNumber == 4 else {
            return Unmanaged.passUnretained(event)
        }

        let mappingKeyCode = UInt16(buttonNumber)
        let mapping = findMapping(keyCode: mappingKeyCode, sourceType: .mouseButton)

        // 推送到事件预览面板
        EventBroadcaster.shared.pushMouseButton(buttonNumber: buttonNumber, mapping: mapping)

        guard let mapping = mapping else {
            return Unmanaged.passUnretained(event)
        }

        // 根据目标类型发出不同的事件
        if mapping.targetKeyCode >= 0x90 {
            // 系统动作（NX 特殊键）
            postSystemAction(keyCode: mapping.targetKeyCode, flags: mapping.modifyFlags ? CGEventFlags(rawValue: mapping.targetFlags) : [])
        } else {
            // 普通键盘快捷键
            postKeyboardShortcut(keyCode: mapping.targetKeyCode, flags: mapping.modifyFlags ? CGEventFlags(rawValue: mapping.targetFlags) : [])
        }

        // 吞掉原始鼠标事件
        return nil
    }

    // MARK: - 映射查找

    private func findMapping(keyCode: UInt16, sourceType: KeyMappingRule.SourceType) -> KeyMappingRule? {
        AppSettings.shared.keyMappings.first { rule in
            rule.enabled && rule.sourceType == sourceType && rule.sourceKeyCode == keyCode
        }
    }

    // MARK: - 事件发出

    /// 发出普通键盘快捷键（修饰键 + 按键）
    private func postKeyboardShortcut(keyCode: CGKeyCode, flags: CGEventFlags) {
        guard let down = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true) else { return }
        down.flags = flags
        down.post(tap: .cgSessionEventTap)

        guard let up = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else { return }
        up.flags = flags
        up.post(tap: .cgSessionEventTap)
    }

    /// 发出系统动作（亮度/音量/调度中心等）
    private func postSystemAction(keyCode: UInt16, flags: CGEventFlags) {
        let systemDefinedKeyMap: [UInt16: Int32] = [
            0x90: NX_KEYTYPE_BRIGHTNESS_DOWN,      // 亮度降低
            0x91: NX_KEYTYPE_BRIGHTNESS_UP,        // 亮度升高
            0x92: NX_KEYTYPE_SOUND_DOWN,           // 音量降低
            0x93: NX_KEYTYPE_SOUND_UP,             // 音量升高
            0x94: NX_KEYTYPE_MUTE,                 // 静音
            0x95: NX_KEYTYPE_PLAY,                 // 播放/暂停
            0x96: NX_KEYTYPE_NEXT,                 // 下一首
            0x97: NX_KEYTYPE_PREVIOUS,             // 上一首
            0x9A: NX_KEYTYPE_ILLUMINATION_DOWN,    // 键盘亮度降低
            0x9B: NX_KEYTYPE_ILLUMINATION_UP,      // 键盘亮度升高
        ]

        if let nxKeyType = systemDefinedKeyMap[keyCode] {
            // NX 系统事件：发送 keyDown + 短延迟后 keyUp
            postNXEvent(keyType: nxKeyType, keyState: 0xA) // keyDown
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.postNXEvent(keyType: nxKeyType, keyState: 0xB) // keyUp
            }
        }

        // 调度中心 / 启动台 需要特殊处理
        if keyCode == 0x98 {
            postKeyboardShortcut(keyCode: 0x7E, flags: .maskControl) // Ctrl+↑
        }
        if keyCode == 0x99 {
            postKeyboardShortcut(keyCode: 0x76, flags: []) // F4
        }
    }

    /// 发出 NX 系统定义事件
    private func postNXEvent(keyType: Int32, keyState: Int) {
        guard let event = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((Int(keyType) << 16) | (keyState << 8)),
            data2: 0
        ) else { return }
        event.cgEvent?.post(tap: .cgSessionEventTap)
    }
}
