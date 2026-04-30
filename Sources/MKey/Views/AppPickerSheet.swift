import SwiftUI
import AppKit

// MARK: - App 信息

struct AppInfo: Identifiable, Hashable {
    let id = UUID()
    let bundleID: String
    let name: String
    let icon: NSImage?
    let path: URL?
    let isRunning: Bool

    func hash(into hasher: inout Hasher) { hasher.combine(bundleID) }
    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool { lhs.bundleID == rhs.bundleID }
}

// MARK: - App 选择 Sheet

struct AppPickerSheet: View {
    @Binding var isPresented: Bool
    let onSelect: (String, String) -> Void

    @State private var searchText = ""
    @State private var runningApps: [AppInfo] = []
    @State private var installedApps: [AppInfo] = []

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            HStack {
                Text("添加应用")
                    .font(.headline)
                Spacer()
                Button("取消") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // 搜索框
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("搜索应用名称…", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.05)))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // 列表
            List {
                if !filteredRunning.isEmpty {
                    Section("正在运行") {
                        ForEach(filteredRunning) { app in
                            AppRow(app: app) {
                                select(app)
                            }
                        }
                    }
                }

                if !filteredInstalled.isEmpty {
                    Section("已安装") {
                        ForEach(filteredInstalled) { app in
                            AppRow(app: app) {
                                select(app)
                            }
                        }
                    }
                }

                if filteredRunning.isEmpty && filteredInstalled.isEmpty && !searchText.isEmpty {
                    Text("未找到匹配的应用")
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.inset)
        }
        .frame(width: 420, height: 440)
        .onAppear { loadApps() }
    }

    // MARK: - 过滤

    private var filteredRunning: [AppInfo] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return runningApps }
        return runningApps.filter { $0.name.lowercased().contains(query) }
    }

    private var filteredInstalled: [AppInfo] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return [] }
        // 如果正在运行列表中已有同名 App，不重复显示
        let runningIDs = Set(runningApps.map(\.bundleID))
        return installedApps.filter {
            $0.name.lowercased().contains(query) && !runningIDs.contains($0.bundleID)
        }
    }

    // MARK: - 选择

    private func select(_ app: AppInfo) {
        onSelect(app.bundleID, app.name)
        isPresented = false
    }

    // MARK: - 加载

    private func loadApps() {
        // 正在运行的 App
        var running: [AppInfo] = []
        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular,
                  let bundleID = app.bundleIdentifier,
                  bundleID != Bundle.main.bundleIdentifier, // 排除 MKey 自身
                  let name = app.localizedName,
                  let url = app.bundleURL ?? app.executableURL else { continue }
            // 排除系统进程
            guard !bundleID.hasPrefix("com.apple.") || isSystemApp(bundleID) else { continue }
            running.append(AppInfo(
                bundleID: bundleID,
                name: name,
                icon: app.icon,
                path: url,
                isRunning: true
            ))
        }
        runningApps = running.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        // 已安装的 App（扫描 Applications 目录）
        var installed: [AppInfo] = []
        let runningIDs = Set(running.map(\.bundleID))
        let searchDirs: [URL] = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]

        for dir in searchDirs {
            guard let apps = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { continue }
            for url in apps where url.pathExtension == "app" {
                guard let bundle = Bundle(url: url),
                      let bundleID = bundle.bundleIdentifier,
                      !runningIDs.contains(bundleID),
                      bundleID != Bundle.main.bundleIdentifier else { continue }
                let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                    ?? url.deletingPathExtension().lastPathComponent
                let icon = NSWorkspace.shared.icon(forFile: url.path)
                installed.append(AppInfo(
                    bundleID: bundleID,
                    name: name,
                    icon: icon,
                    path: url,
                    isRunning: false
                ))
            }
        }
        installedApps = installed.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// 部分系统 App（如 Safari、计算器）允许添加，排除纯后台进程
    private func isSystemApp(_ bundleID: String) -> Bool {
        let allowlist: Set<String> = [
            "com.apple.Safari", "com.apple.mail", "com.apple.calculator",
            "com.apple.TextEdit", "com.apple.Preview", "com.apple.Maps",
            "com.apple.finder", "com.apple.iCal", "com.apple.Music",
            "com.apple.TV", "com.apple.QuickTimePlayerX", "com.apple.Notes",
            "com.apple.reminders", "com.apple.iWork.Pages",
            "com.apple.iWork.Numbers", "com.apple.iWork.Keynote",
            "com.apple.systempreferences"
        ]
        return allowlist.contains(bundleID)
    }
}

// MARK: - App 行

struct AppRow: View {
    let app: AppInfo
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 28, height: 28)
                } else {
                    Image(systemName: "app.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(app.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    Text(app.bundleID)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if app.isRunning {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
}
