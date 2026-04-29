# MKey

macOS 菜单栏小工具：**触控板/鼠标滚动方向独立控制** + **键盘按键映射**。

- 触控板保持自然滚动，鼠标滚轮方向反转（各管各的）
- 支持按应用单独设置滚动行为
- 支持键盘按键重映射（Alt ↔ Command 等）
- 支持鼠标侧键自定义

## 系统要求

- macOS 12+
- Apple Silicon (arm64)

## 快速开始

### 编译 + 打包

```bash
./build.sh
```

一步完成：编译 → 拷贝到 .app → ad-hoc 签名。生成 `MKey.app` 可直接双击运行。

### 首次授权

macOS 要求辅助功能权限才能拦截键盘/滚动事件：

1. 双击 `MKey.app` 启动
2. 如果弹出权限请求 → 点 **允许**，跳转到系统设置勾选 MKey
3. 如果没弹窗 → 手动打开 **系统设置 → 隐私与安全性 → 辅助功能**，勾选 MKey
4. **如果勾选了还是提示无权限**：
   - 在辅助功能列表中选中 MKey → 点 `-` 删除
   - 重新双击打开 MKey.app → 重新授权

> 每次重新编译后会自动 ad-hoc 签名，授权不会丢失。

### 启动方式

- **手动启动**：双击 `MKey.app`
- **开机自启**：打开设置窗口，勾选「开机自动启动」

菜单栏会出现 ⌨ 图标，点击打开设置。

## 项目结构

```
Sources/MKey/
├── MKeyApp.swift          # SwiftUI 入口
├── AppDelegate.swift      # 菜单栏 + 权限 + 拦截器生命周期
├── Models/
│   ├── AppSettings.swift        # 用户配置（持久化）
│   ├── KeyMappingRule.swift     # 按键映射规则模型
│   └── PerAppScrollRule.swift   # 应用滚动规则模型
├── Services/
│   ├── ScrollInterceptor.swift  # CGEvent 滚动拦截
│   ├── KeyInterceptor.swift     # CGEvent 按键拦截
│   ├── EventBroadcaster.swift   # 事件广播给 UI 预览
│   ├── PermissionChecker.swift  # 辅助功能权限检查
│   └── KeyCodeHelper.swift      # 键码 ↔ 显示名
└── Views/
    ├── SettingsWindow.swift      # 设置窗口容器
    ├── ScrollTab.swift           # 滚动方向设置页
    ├── KeyboardTab.swift         # 键盘映射设置页
    └── KeyCaptureButton.swift    # 按键捕获控件
```

## 常见问题

**勾选了权限还是提示无权限？**
删除旧的授权记录再重新打开 App（见上方「首次授权」第 4 步）。每次重新编译后 `build.sh` 会自动签名，一般不会遇到这个问题。

**和其他同类软件冲突？**
MKey 与 Mos、Scroll Reverser 等同类工具功能重叠，只开一个即可。

**没有 Windows 版本吗？**
没有。MKey 基于 macOS CGEvent API，只支持 macOS。
