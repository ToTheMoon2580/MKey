import SwiftUI

struct SettingsWindow: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标签页
            TabView(selection: $selectedTab) {
                ScrollTab()
                    .tabItem { Label("滚动方向", systemImage: "arrow.up.arrow.down") }
                    .tag(0)

                KeyboardTab()
                    .tabItem { Label("键盘映射", systemImage: "keyboard") }
                    .tag(1)
            }

            // 底部事件预览（始终展开，更直观）
            EventPreviewBar()
        }
        .frame(minWidth: 540, minHeight: 520)
    }
}
