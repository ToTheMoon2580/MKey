import Cocoa
import CoreGraphics

/// 滚动事件拦截器：监听 CGEvent 滚动事件，区分触控板/鼠标，对鼠标滚轮反转 deltaY。
/// 支持按应用单独设置滚动方向（PerAppScrollRule）。
final class ScrollInterceptor {

    private var eventTap: CFMachPort?

    func start() {
        guard eventTap == nil else { return }

        let eventMask = (1 << CGEventType.scrollWheel.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (_, type, event, userInfo) -> Unmanaged<CGEvent>? in
                let interceptor = Unmanaged<ScrollInterceptor>
                    .fromOpaque(userInfo!)
                    .takeUnretainedValue()
                return interceptor.handleScroll(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let tap = eventTap else {
            print("[MKey] 无法创建事件监听，请确认已授予辅助功能权限")
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

    private func handleScroll(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .scrollWheel else {
            return Unmanaged.passUnretained(event)
        }

        // 触控板事件带 kCGEventFlagMaskNonCoalesced / NSEventSubtypeTouch 特征
        // 鼠标滚轮事件 flag 不含 subtype 标志，且 scrollCount 通常为 1
        let isTrackpad = event.getIntegerValueField(.scrollWheelEventIsContinuous) == 1
            || event.getIntegerValueField(.scrollWheelEventMomentumPhase) != 0

        // 推送到事件预览面板（反转前推送原始方向）
        let deltaY = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1)
        EventBroadcaster.shared.pushScroll(isTrackpad: isTrackpad, deltaY: deltaY)

        // 确定是否需要反转
        let shouldReverse: Bool
        if !isTrackpad, let appRule = perAppRule(), appRule.enabled {
            // 应用级规则覆盖
            shouldReverse = (appRule.scrollBehavior == .reversed)
        } else {
            // 全局设置（触控板永不反转）
            shouldReverse = AppSettings.shared.scrollReverseEnabled && !isTrackpad
        }

        if shouldReverse {
            event.setDoubleValueField(.scrollWheelEventPointDeltaAxis1, value: -deltaY)
            let fixedDeltaY = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
            event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: -fixedDeltaY)
        }

        return Unmanaged.passUnretained(event)
    }

    // MARK: - 应用过滤

    /// 获取当前前台应用匹配的滚动规则
    private func perAppRule() -> PerAppScrollRule? {
        guard let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return nil
        }
        return AppSettings.shared.perAppScrollRules.first { rule in
            rule.bundleID == bundleID
        }
    }
}
