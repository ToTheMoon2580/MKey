import SwiftUI
import UniformTypeIdentifiers

struct KeyboardTab: View {
    @StateObject private var settings = AppSettings.shared

    @State private var showAddSheet = false
    @State private var editingRule: KeyMappingRule?
    @State private var showDeleteAlert = false
    @State private var ruleToDelete: KeyMappingRule?
    @State private var showImportSheet = false

    // 预设
    @State private var selectedPresetID = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            Divider()
            presetSection
            Divider()
            rulesSection
            Divider()
            mouseSection
        }
        .sheet(isPresented: $showAddSheet) {
            RuleEditSheet(mode: .add) { rule in
                settings.keyMappings.append(rule)
            }
        }
        .sheet(item: $editingRule) { rule in
            RuleEditSheet(mode: .edit(rule)) { updatedRule in
                if let index = settings.keyMappings.firstIndex(where: { $0.id == rule.id }) {
                    settings.keyMappings[index] = updatedRule
                }
            }
        }
        .alert("删除映射规则", isPresented: $showDeleteAlert, presenting: ruleToDelete) { rule in
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                settings.keyMappings.removeAll { $0.id == rule.id }
            }
        } message: { rule in
            Text("确定要删除「\(rule.displayName)」吗？此操作不可撤销。")
        }
    }

    // MARK: - 标题

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("键盘映射")
                    .font(.headline)
                Text("自定义按键映射，适配外接键盘键位")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - 预设方案

    private var presetSection: some View {
        HStack(spacing: 8) {
            Text("预设方案")
                .font(.callout)
            Picker("", selection: $selectedPresetID) {
                Text("不使用预设").tag("")
                ForEach(KeyMappingPreset.builtInPresets) { preset in
                    Text(preset.name).tag(preset.id)
                }
            }
            .labelsHidden()
            .frame(width: 180)

            Button("应用") {
                applyPreset()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(selectedPresetID.isEmpty)

            Spacer()

            // 导入导出按钮
            Button(action: { exportMappings() }) {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.borderless)
            .help("导出配置")

            Button(action: { showImportSheet = true }) {
                Image(systemName: "square.and.arrow.down")
            }
            .buttonStyle(.borderless)
            .help("导入配置")
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    // MARK: - 映射规则列表

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("键盘映射规则")
                    .font(.callout)
                    .fontWeight(.medium)
                Spacer()
                Button(action: { showAddSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("添加规则")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)

            let keyboardRules = settings.keyMappings.filter { $0.sourceType == .keyboard }

            if keyboardRules.isEmpty {
                emptyRulesHint
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(keyboardRules) { rule in
                            RuleRowView(
                                rule: rule,
                                onToggle: { enabled in
                                    if let i = settings.keyMappings.firstIndex(where: { $0.id == rule.id }) {
                                        settings.keyMappings[i].enabled = enabled
                                    }
                                },
                                onEdit: { editingRule = rule },
                                onDelete: {
                                    ruleToDelete = rule
                                    showDeleteAlert = true
                                }
                            )
                            if rule.id != keyboardRules.last?.id {
                                Divider().padding(.leading, 42)
                            }
                        }
                    }
                }
                .frame(minHeight: 100, maxHeight: 220)
            }
        }
    }

    private var emptyRulesHint: some View {
        VStack(spacing: 8) {
            Image(systemName: "keyboard.badge.ellipsis")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("暂无映射规则")
                .font(.callout)
                .foregroundColor(.secondary)
            Text("添加规则或从预设方案应用")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - 鼠标侧键

    private var mouseSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            HStack {
                Image(systemName: "computermouse")
                Text("鼠标按键")
                    .font(.callout)
                    .fontWeight(.medium)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)

            let mouseRules = settings.keyMappings.filter { $0.sourceType == .mouseButton }

            if mouseRules.isEmpty {
                mouseEmptyHint
            } else {
                ForEach(mouseRules) { rule in
                    RuleRowView(
                        rule: rule,
                        onToggle: { enabled in
                            if let i = settings.keyMappings.firstIndex(where: { $0.id == rule.id }) {
                                settings.keyMappings[i].enabled = enabled
                            }
                        },
                        onEdit: { editingRule = rule },
                        onDelete: {
                            ruleToDelete = rule
                            showDeleteAlert = true
                        }
                    )
                }
            }

            // 快速添加侧键绑定
            Button(action: { addSideButtonMapping(button: 3) }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle")
                    Text("绑定侧键 1（前进键）")
                }
            }
            .buttonStyle(.borderless)
            .padding(.horizontal)
            .padding(.bottom, 2)

            Button(action: { addSideButtonMapping(button: 4) }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle")
                    Text("绑定侧键 2（后退键）")
                }
            }
            .buttonStyle(.borderless)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private var mouseEmptyHint: some View {
        HStack(spacing: 4) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("未绑定侧键，点击下方按钮绑定")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
    }

    // MARK: - 操作方法

    private func applyPreset() {
        guard let preset = KeyMappingPreset.builtInPresets.first(where: { $0.id == selectedPresetID }) else { return }

        // 移除现有键盘映射，保留鼠标侧键映射
        settings.keyMappings.removeAll { $0.sourceType == .keyboard }
        settings.keyMappings.append(contentsOf: preset.rules)
        selectedPresetID = ""
    }

    private func addSideButtonMapping(button: UInt16) {
        let rule = KeyMappingRule(
            sourceKeyCode: button,
            targetKeyCode: 0,
            displayName: "侧键 \(button == 3 ? 1 : 2) (\(button == 3 ? "前进" : "后退"))",
            sourceType: .mouseButton
        )
        settings.keyMappings.append(rule)
        editingRule = rule
    }

    private func exportMappings() {
        guard let data = try? JSONEncoder().encode(settings.keyMappings),
              let json = String(data: data, encoding: .utf8) else { return }

        let savePanel = NSSavePanel()
        savePanel.title = "导出按键映射"
        savePanel.nameFieldStringValue = "MKey_Mappings.json"
        savePanel.allowedContentTypes = [UTType.json]

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                try? json.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    private func importMappings() {
        let openPanel = NSOpenPanel()
        openPanel.title = "导入按键映射"
        openPanel.allowedContentTypes = [UTType.json]
        openPanel.allowsMultipleSelection = false

        openPanel.begin { response in
            if response == .OK, let url = openPanel.urls.first {
                guard let data = try? Data(contentsOf: url),
                      let mappings = try? JSONDecoder().decode([KeyMappingRule].self, from: data) else {
                    // 解析失败提示
                    let alert = NSAlert()
                    alert.messageText = "导入失败"
                    alert.informativeText = "无法解析文件内容，请确认是有效的 MKey 映射文件。"
                    alert.runModal()
                    return
                }
                settings.keyMappings = mappings
            }
        }
    }
}

// MARK: - 单行规则视图

struct RuleRowView: View {
    let rule: KeyMappingRule
    let onToggle: (Bool) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // 启用开关
            Toggle("", isOn: Binding(
                get: { rule.enabled },
                set: { onToggle($0) }
            ))
            .toggleStyle(.switch)
            .scaleEffect(0.7)
            .frame(width: 32)

            // 规则名称
            VStack(alignment: .leading, spacing: 1) {
                Text(rule.displayName.isEmpty ? ruleDisplay : rule.displayName)
                    .font(.callout)
                    .foregroundColor(rule.enabled ? .primary : .secondary)
                Text("源: \(KeyCodeHelper.displayName(for: rule.sourceKeyCode)) → 目标: \(targetDisplay)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 操作按钮
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .help("编辑")

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
            .help("删除")
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    private var ruleDisplay: String {
        let src = KeyCodeHelper.displayName(for: rule.sourceKeyCode)
        let tgt = KeyCodeHelper.displayName(for: rule.targetKeyCode)
        return "\(src) → \(tgt)"
    }

    private var targetDisplay: String {
        if rule.targetKeyCode >= 0x90 {
            return KeyCodeHelper.displayName(for: rule.targetKeyCode)
        }
        if rule.modifyFlags {
            return KeyCodeHelper.shortcutName(keyCode: rule.targetKeyCode, flags: rule.targetFlags)
        }
        return KeyCodeHelper.displayName(for: rule.targetKeyCode)
    }
}

// MARK: - 添加/编辑规则 Sheet

struct RuleEditSheet: View {
    enum Mode {
        case add
        case edit(KeyMappingRule)
    }

    let mode: Mode
    let onSave: (KeyMappingRule) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var sourceType: KeyMappingRule.SourceType = .keyboard
    @State private var sourceKeyCode: UInt16 = 0
    @State private var targetKeyCode: UInt16 = 0
    @State private var targetIsSystemAction = false
    @State private var modifyFlags = false
    @State private var cmdFlag = false
    @State private var optFlag = false
    @State private var ctrlFlag = false
    @State private var shiftFlag = false
    @State private var displayName = ""

    private var ruleID: UUID?

    init(mode: Mode, onSave: @escaping (KeyMappingRule) -> Void) {
        self.mode = mode
        self.onSave = onSave

        if case .edit(let rule) = mode {
            _sourceType = State(initialValue: rule.sourceType)
            _sourceKeyCode = State(initialValue: rule.sourceKeyCode)
            _targetKeyCode = State(initialValue: rule.targetKeyCode)
            _targetIsSystemAction = State(initialValue: rule.targetKeyCode >= 0x90)
            _modifyFlags = State(initialValue: rule.modifyFlags)
            _displayName = State(initialValue: rule.displayName)
            ruleID = rule.id

            if rule.modifyFlags {
                let f = CGEventFlags(rawValue: rule.targetFlags)
                _cmdFlag = State(initialValue: f.contains(.maskCommand))
                _optFlag = State(initialValue: f.contains(.maskAlternate))
                _ctrlFlag = State(initialValue: f.contains(.maskControl))
                _shiftFlag = State(initialValue: f.contains(.maskShift))
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isAdd ? "添加映射规则" : "编辑映射规则")
                .font(.headline)
                .padding(.top)

            // 来源类型
            Picker("来源类型", selection: $sourceType) {
                Text("键盘按键").tag(KeyMappingRule.SourceType.keyboard)
                Text("鼠标侧键 1（前进）").tag(KeyMappingRule.SourceType.mouseButton)
            }
            .labelsHidden()
            .disabled(!isAdd) // 编辑时不允许改类型

            // 来源按键
            if sourceType == .keyboard {
                VStack(alignment: .leading, spacing: 4) {
                    Text("按下来源按键").font(.caption).foregroundColor(.secondary)
                    KeyCaptureButton(placeholder: "点击后按下键盘按键", keyCode: $sourceKeyCode)
                }
            } else {
                // 鼠标侧键：固定 keyCode
                HStack {
                    Text("侧键").font(.callout)
                    Picker("", selection: $sourceKeyCode) {
                        Text("侧键 1 (前进)").tag(UInt16(3))
                        Text("侧键 2 (后退)").tag(UInt16(4))
                    }
                    .labelsHidden()
                }
            }

            Divider()

            // 目标：普通按键 or 系统动作
            Toggle("目标为系统动作（亮度/音量等）", isOn: $targetIsSystemAction)
                .font(.callout)

            if targetIsSystemAction {
                SystemActionPicker(placeholder: "选择系统动作", keyCode: $targetKeyCode)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("按下目标按键").font(.caption).foregroundColor(.secondary)
                    KeyCaptureButton(placeholder: "点击后按下目标按键", keyCode: $targetKeyCode)
                }

                // 修饰键开关
                Toggle("附加修饰键", isOn: $modifyFlags)
                    .font(.callout)

                if modifyFlags {
                    HStack(spacing: 16) {
                        Toggle("⌘", isOn: $cmdFlag).toggleStyle(.switch)
                        Toggle("⌥", isOn: $optFlag).toggleStyle(.switch)
                        Toggle("⌃", isOn: $ctrlFlag).toggleStyle(.switch)
                        Toggle("⇧", isOn: $shiftFlag).toggleStyle(.switch)
                    }
                }
            }

            // 规则名称
            HStack {
                Text("名称")
                TextField("如「Alt → Command」", text: $displayName)
                    .textFieldStyle(.roundedBorder)
            }

            // 按钮
            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("保存") { save() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
            .padding(.bottom)
        }
        .padding()
        .frame(width: 400, height: 420)
    }

    private var isAdd: Bool {
        if case .add = mode { return true }
        return false
    }

    private var isValid: Bool {
        guard sourceType == .mouseButton || sourceKeyCode != 0 else { return false }
        guard targetKeyCode != 0 else { return false }
        return true
    }

    private func save() {
        var flags: UInt64 = 0
        if modifyFlags {
            if cmdFlag   { flags |= CGEventFlags.maskCommand.rawValue }
            if optFlag   { flags |= CGEventFlags.maskAlternate.rawValue }
            if ctrlFlag  { flags |= CGEventFlags.maskControl.rawValue }
            if shiftFlag { flags |= CGEventFlags.maskShift.rawValue }
        }

        let rule = KeyMappingRule(
            id: ruleID ?? UUID(),
            sourceKeyCode: sourceKeyCode,
            targetKeyCode: targetKeyCode,
            modifyFlags: modifyFlags,
            targetFlags: flags,
            displayName: displayName.isEmpty ? autoName : displayName,
            enabled: true,
            sourceType: sourceType
        )

        onSave(rule)
        dismiss()
    }

    private var autoName: String {
        let src = KeyCodeHelper.displayName(for: sourceKeyCode)
        let tgt = targetIsSystemAction
            ? KeyCodeHelper.displayName(for: targetKeyCode)
            : KeyCodeHelper.shortcutName(keyCode: targetKeyCode, flags: modifyFlags ? combinedFlagsRaw : 0)
        return "\(src) → \(tgt)"
    }

    private var combinedFlagsRaw: UInt64 {
        var f: UInt64 = 0
        if cmdFlag   { f |= CGEventFlags.maskCommand.rawValue }
        if optFlag   { f |= CGEventFlags.maskAlternate.rawValue }
        if ctrlFlag  { f |= CGEventFlags.maskControl.rawValue }
        if shiftFlag { f |= CGEventFlags.maskShift.rawValue }
        return f
    }
}
