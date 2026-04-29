import SwiftUI
import UniformTypeIdentifiers

struct KeyboardTab: View {
    @StateObject private var settings = AppSettings.shared

    @State private var showAddSheet = false
    @State private var editingRule: KeyMappingRule?
    @State private var showDeleteAlert = false
    @State private var ruleToDelete: KeyMappingRule?
    @State private var selectedPresetID = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                Divider()
                presetSection
                Divider()
                rulesSection
                Divider()
                mouseSection
            }
        }
        .sheet(isPresented: $showAddSheet) {
            RuleEditSheet(mode: .add) { rule in
                settings.keyMappings.append(rule)
            }
        }
        .sheet(item: $editingRule) { rule in
            RuleEditSheet(mode: .edit(rule)) { updatedRule in
                if let i = settings.keyMappings.firstIndex(where: { $0.id == rule.id }) {
                    settings.keyMappings[i] = updatedRule
                }
            }
        }
        .alert("删除映射规则", isPresented: $showDeleteAlert, presenting: ruleToDelete) { rule in
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                settings.keyMappings.removeAll { $0.id == rule.id }
            }
        } message: { rule in
            Text("确定要删除「\(rule.displayName)」吗？")
        }
    }

    // MARK: - 标题

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("键盘映射").font(.headline)
                Text("自定义按键映射，适配外接键盘键位")
                    .font(.body).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 12).padding(.top, 10).padding(.bottom, 6)
    }

    // MARK: - 预设

    private var presetSection: some View {
        HStack(spacing: 8) {
            Picker("预设方案", selection: $selectedPresetID) {
                Text("不使用预设").tag("")
                ForEach(KeyMappingPreset.builtInPresets) { preset in
                    Text(preset.name).tag(preset.id)
                }
            }
            .frame(width: 160)

            Button("应用") { applyPreset() }
                .buttonStyle(.bordered).controlSize(.small)
                .disabled(selectedPresetID.isEmpty)

            Spacer()

            Button(action: { importMappings() }) {
                Image(systemName: "square.and.arrow.down")
            }
            .buttonStyle(.bordered).controlSize(.small)
            .help("导入配置")

            Button(action: { exportMappings() }) {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.bordered).controlSize(.small)
            .help("导出配置")
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }

    // MARK: - 规则列表

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("键盘映射规则").fontWeight(.medium)
                Spacer()
                Button(action: { showAddSheet = true }) {
                    Label("添加规则", systemImage: "plus").font(.body)
                }
                .buttonStyle(.bordered).controlSize(.regular)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)

            let keyboardRules = settings.keyMappings.filter { $0.sourceType == .keyboard }
            if keyboardRules.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "keyboard.badge.ellipsis")
                        .font(.title3).foregroundColor(.secondary)
                    Text("暂无映射规则").font(.callout).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 20)
            } else {
                ForEach(keyboardRules) { rule in
                    RuleRowView(
                        rule: rule,
                        onToggle: { enabled in
                            if let i = settings.keyMappings.firstIndex(where: { $0.id == rule.id }) {
                                settings.keyMappings[i].enabled = enabled
                            }
                        },
                        onEdit: { editingRule = rule },
                        onDelete: { ruleToDelete = rule; showDeleteAlert = true }
                    )
                    Divider().padding(.leading, 12)
                }
            }
        }
    }

    // MARK: - 鼠标侧键

    private var mouseSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "computermouse")
                Text("鼠标按键").fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 8)

            let mouseRules = settings.keyMappings.filter { $0.sourceType == .mouseButton }
            if mouseRules.isEmpty {
                Text("未绑定侧键").font(.callout).foregroundColor(.secondary)
                    .padding(.horizontal, 12).padding(.bottom, 4)
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
                        onDelete: { ruleToDelete = rule; showDeleteAlert = true }
                    )
                }
            }

            HStack(spacing: 8) {
                Button(action: { addSideButtonMapping(button: 3) }) {
                    Label("侧键 1（前进）", systemImage: "plus").font(.callout)
                }
                .buttonStyle(.bordered).controlSize(.small)

                Button(action: { addSideButtonMapping(button: 4) }) {
                    Label("侧键 2（后退）", systemImage: "plus").font(.callout)
                }
                .buttonStyle(.bordered).controlSize(.small)
            }
            .padding(.horizontal, 12).padding(.bottom, 12)
        }
    }

    // MARK: - 操作方法

    private func applyPreset() {
        guard let preset = KeyMappingPreset.builtInPresets.first(where: { $0.id == selectedPresetID }) else { return }
        settings.keyMappings.removeAll { $0.sourceType == .keyboard }
        settings.keyMappings.append(contentsOf: preset.rules)
        selectedPresetID = ""
    }

    private func addSideButtonMapping(button: UInt16) {
        let rule = KeyMappingRule(
            sourceKeyCode: button, targetKeyCode: 0,
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
                    let alert = NSAlert()
                    alert.messageText = "导入失败"
                    alert.informativeText = "无法解析文件内容"
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
            Toggle("", isOn: Binding(get: { rule.enabled }, set: onToggle))
                .toggleStyle(.switch).scaleEffect(0.75).frame(width: 34)

            VStack(alignment: .leading, spacing: 1) {
                Text(rule.displayName.isEmpty ? ruleDisplay : rule.displayName)
                    .font(.callout)
                    .foregroundColor(rule.enabled ? .primary : .secondary)
                Text("源: \(KeyCodeHelper.displayName(for: rule.sourceKeyCode)) -> \(targetDisplay)")
                    .font(.caption).foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(.bordered).controlSize(.small)

            Button(action: onDelete) {
                Image(systemName: "trash").foregroundColor(.red)
            }
            .buttonStyle(.bordered).controlSize(.small)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
    }

    private var ruleDisplay: String {
        "\(KeyCodeHelper.displayName(for: rule.sourceKeyCode)) -> \(KeyCodeHelper.displayName(for: rule.targetKeyCode))"
    }

    private var targetDisplay: String {
        if rule.targetKeyCode >= 0x90 { return KeyCodeHelper.displayName(for: rule.targetKeyCode) }
        if rule.modifyFlags { return KeyCodeHelper.shortcutName(keyCode: rule.targetKeyCode, flags: rule.targetFlags) }
        return KeyCodeHelper.displayName(for: rule.targetKeyCode)
    }
}

// MARK: - 编辑 Sheet

struct RuleEditSheet: View {
    enum Mode { case add; case edit(KeyMappingRule) }

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
        self.mode = mode; self.onSave = onSave
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
        VStack(alignment: .leading, spacing: 14) {
            Text(isAdd ? "添加映射规则" : "编辑映射规则").font(.headline).padding(.top)

            Picker("来源类型", selection: $sourceType) {
                Text("键盘按键").tag(KeyMappingRule.SourceType.keyboard)
                Text("鼠标侧键 1（前进）").tag(KeyMappingRule.SourceType.mouseButton)
            }
            .labelsHidden().disabled(!isAdd)

            if sourceType == .keyboard {
                VStack(alignment: .leading, spacing: 4) {
                    Text("按下来源按键").font(.callout).foregroundColor(.secondary)
                    KeyCaptureButton(placeholder: "点击后按下键盘按键", keyCode: $sourceKeyCode)
                }
            } else {
                HStack {
                    Text("侧键").font(.body)
                    Picker("", selection: $sourceKeyCode) {
                        Text("侧键 1 (前进)").tag(UInt16(3))
                        Text("侧键 2 (后退)").tag(UInt16(4))
                    }.labelsHidden()
                }
            }

            Divider()

            Toggle("目标为系统动作（亮度/音量等）", isOn: $targetIsSystemAction)

            if targetIsSystemAction {
                SystemActionPicker(placeholder: "选择系统动作", keyCode: $targetKeyCode)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("按下目标按键").font(.callout).foregroundColor(.secondary)
                    KeyCaptureButton(placeholder: "点击后按下目标按键", keyCode: $targetKeyCode)
                }
                Toggle("附加修饰键", isOn: $modifyFlags)
                if modifyFlags {
                    HStack(spacing: 16) {
                        Toggle("Cmd", isOn: $cmdFlag).toggleStyle(.switch)
                        Toggle("Opt", isOn: $optFlag).toggleStyle(.switch)
                        Toggle("Ctrl", isOn: $ctrlFlag).toggleStyle(.switch)
                        Toggle("Shift", isOn: $shiftFlag).toggleStyle(.switch)
                    }
                }
            }

            HStack {
                Text("名称").font(.body)
                TextField("如 Alt -> Command", text: $displayName).textFieldStyle(.roundedBorder)
            }

            HStack {
                Spacer()
                Button("取消") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("保存") { save() }
                    .buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction).disabled(!isValid)
            }
        }
        .padding()
        .frame(width: 400, height: 420)
    }

    private var isAdd: Bool { if case .add = mode { return true }; return false }
    private var isValid: Bool {
        guard sourceType == .mouseButton || sourceKeyCode != 0 else { return false }
        return targetKeyCode != 0
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
            id: ruleID ?? UUID(), sourceKeyCode: sourceKeyCode, targetKeyCode: targetKeyCode,
            modifyFlags: modifyFlags, targetFlags: flags,
            displayName: displayName.isEmpty ? autoName : displayName,
            enabled: true, sourceType: sourceType
        )
        onSave(rule)
        dismiss()
    }

    private var autoName: String {
        let src = KeyCodeHelper.displayName(for: sourceKeyCode)
        let tgt = targetIsSystemAction
            ? KeyCodeHelper.displayName(for: targetKeyCode)
            : KeyCodeHelper.shortcutName(keyCode: targetKeyCode, flags: modifyFlags ? combinedFlagsRaw : 0)
        return "\(src) -> \(tgt)"
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
