import Cocoa
import CoreGraphics

/// 滚动事件拦截器：区分触控板/鼠标，各自独立控制方向。
/// 支持按应用单独设置（PerAppScrollRule）。
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

        let isTrackpad = event.getIntegerValueField(.scrollWheelEventIsContinuous) == 1
            || event.getIntegerValueField(.scrollWheelEventMomentumPhase) != 0

        // 推送到事件预览面板
        let deltaY = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1)
        EventBroadcaster.shared.pushScroll(isTrackpad: isTrackpad, deltaY: deltaY)

        // 确定是否需要反转
        let shouldReverse: Bool
        if let appRule = perAppRule(), appRule.enabled {
            // 应用级规则覆盖
            shouldReverse = (appRule.scrollBehavior == .reversed)
        } else {
            // 全局独立设置
            let settings = AppSettings.shared
            if isTrackpad {
                shouldReverse = (settings.trackpadScrollBehavior == .reversed)
            } else {
                shouldReverse = (settings.mouseScrollBehavior == .reversed)
            }
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
