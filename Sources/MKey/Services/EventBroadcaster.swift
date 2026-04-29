import SwiftUI

/// 共享事件流：拦截器推送事件，UI 层订阅并渲染预览。
/// 使用三个独立的 @Published 属性，使键盘/滚轮/鼠标可同时显示。
final class EventBroadcaster: ObservableObject {

    static let shared = EventBroadcaster()

    @Published var keyboardEvent: InputEventSnapshot?
    @Published var scrollEvent: InputEventSnapshot?
    @Published var mouseButtonEvent: InputEventSnapshot?

    private init() {}

    /// 推送键盘事件（keyDown / keyUp 均推送）
    func pushKeyboard(keyCode: UInt16, isKeyDown: Bool, mapping: KeyMappingRule?) {
        let snapshot = InputEventSnapshot.keyboardEvent(
            keyCode: keyCode,
            isKeyDown: isKeyDown,
            mapping: mapping
        )
        DispatchQueue.main.async { [weak self] in
            self?.keyboardEvent = snapshot
            // keyUp 且无映射：延迟清除（先存快照再延迟，避免覆盖后续事件）
            if !isKeyDown && mapping == nil {
                let captured = snapshot
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    // 仅在仍为同一快照时清除，防止覆盖后来的 keyDown
                    if self?.keyboardEvent == captured {
                        self?.keyboardEvent = nil
                    }
                }
            }
        }
    }

    /// 推送滚轮事件
    func pushScroll(isTrackpad: Bool, deltaY: Double) {
        DispatchQueue.main.async { [weak self] in
            self?.scrollEvent = InputEventSnapshot.scrollEvent(
                isTrackpad: isTrackpad,
                deltaY: deltaY
            )
            self?.debounceClearScroll()
        }
    }

    /// 推送鼠标按键事件
    func pushMouseButton(buttonNumber: Int64, mapping: KeyMappingRule?) {
        let snapshot = InputEventSnapshot.mouseButtonEvent(
            buttonNumber: buttonNumber,
            mapping: mapping
        )
        DispatchQueue.main.async { [weak self] in
            self?.mouseButtonEvent = snapshot
            let captured = snapshot
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                if self?.mouseButtonEvent == captured {
                    self?.mouseButtonEvent = nil
                }
            }
        }
    }

    // MARK: - 防抖

    private var scrollClearWorkItem: DispatchWorkItem?

    private func debounceClearScroll() {
        scrollClearWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.scrollEvent = nil
        }
        scrollClearWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
    }
}
