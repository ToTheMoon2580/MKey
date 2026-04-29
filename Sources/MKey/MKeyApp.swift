import SwiftUI

@main
struct MKeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 菜单栏 App 不创建默认窗口；Settings 场景不会自启，仅响应 Cmd+,
        // AppDelegate 自行管理 NSWindow
        Settings {
            EmptyView()
        }
    }
}
