import Foundation

/// 实时预览用的事件快照
struct InputEventSnapshot: Equatable {
    let type: EventType
    let timestamp: Date
    var keyCode: UInt16?
    var keyName: String?
    var isKeyDown: Bool
    var mappingRuleName: String?
    var isMapped: Bool
    var scrollDirection: ScrollDirection?
    var isTrackpad: Bool
    var buttonNumber: Int64?
    var buttonName: String?

    enum EventType: Equatable {
        case keyboard
        case mouseScroll
        case mouseButton
    }

    enum ScrollDirection: String, Equatable {
        case up = "↑"
        case down = "↓"
    }

    // MARK: - 工厂方法

    static func keyboardEvent(
        keyCode: UInt16,
        isKeyDown: Bool,
        mapping: KeyMappingRule? = nil
    ) -> InputEventSnapshot {
        InputEventSnapshot(
            type: .keyboard,
            timestamp: Date(),
            keyCode: keyCode,
            keyName: KeyCodeHelper.displayName(for: keyCode),
            isKeyDown: isKeyDown,
            mappingRuleName: mapping?.displayName,
            isMapped: mapping != nil,
            isTrackpad: false
        )
    }

    static func scrollEvent(
        isTrackpad: Bool,
        deltaY: Double
    ) -> InputEventSnapshot {
        InputEventSnapshot(
            type: .mouseScroll,
            timestamp: Date(),
            isKeyDown: false,
            isMapped: false,
            scrollDirection: deltaY > 0 ? .down : .up,
            isTrackpad: isTrackpad
        )
    }

    static func mouseButtonEvent(
        buttonNumber: Int64,
        mapping: KeyMappingRule? = nil
    ) -> InputEventSnapshot {
        let name: String
        switch buttonNumber {
        case 3: name = "侧键 1 (前进)"
        case 4: name = "侧键 2 (后退)"
        default: name = "按键 \(buttonNumber)"
        }

        return InputEventSnapshot(
            type: .mouseButton,
            timestamp: Date(),
            isKeyDown: false,
            mappingRuleName: mapping?.displayName,
            isMapped: mapping != nil,
            isTrackpad: false,
            buttonNumber: buttonNumber,
            buttonName: name
        )
    }
}
