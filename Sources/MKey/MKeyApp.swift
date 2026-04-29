import SwiftUI

@main
struct MKeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 菜单栏 App 不需要主窗口，AppDelegate 自行管理设置窗口
        WindowGroup {
            EmptyView()
        }
    }
}
