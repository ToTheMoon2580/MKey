import SwiftUI

struct SettingsWindow: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                ScrollTab()
                    .tabItem {
                        Label("滚动方向", systemImage: "scroll")
                    }
                    .tag(0)

                KeyboardTab()
                    .tabItem {
                        Label("键盘映射", systemImage: "keyboard")
                    }
                    .tag(1)
            }
            .padding()

            // 底部事件实时预览条
            EventPreviewBar()
        }
        .frame(minWidth: 540, minHeight: 560)
    }
}
