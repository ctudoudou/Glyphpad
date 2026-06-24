import AppKit
import Carbon
import GlyphpadCore
import SwiftUI
import UniformTypeIdentifiers

struct SettingsWindowView: View {
    @ObservedObject var controller: LauncherSettingsController
    @State private var selectedSection: SettingsSection = .layout
    @State private var isRecordingHotKey = false

    var body: some View {
        HStack(spacing: 0) {
            settingsSidebar

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    sectionHeader
                    selectedSectionContent
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 26)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.74))
        }
        .toggleStyle(.switch)
        .controlSize(.regular)
        .frame(width: 760, height: 560)
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
    }

    private var settingsSidebar: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Glyphpad")
                    .font(.system(size: 22, weight: .semibold))
                Text("Launchpad controls")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)

            VStack(spacing: 5) {
                ForEach(SettingsSection.allCases) { section in
                    SettingsSidebarButton(
                        section: section,
                        isSelected: selectedSection == section
                    ) {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            selectedSection = section
                        }
                    }
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                Text("Local state")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Label("SQLite backed", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.green)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .frame(width: 190)
    }

    private var sectionHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: selectedSection.symbolName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 42, height: 42)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(selectedSection.title)
                    .font(.system(size: 25, weight: .semibold))
                Text(selectedSection.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var selectedSectionContent: some View {
        switch selectedSection {
        case .layout:
            layoutSettings
        case .appearance:
            appearanceSettings
        case .automation:
            automationSettings
        }
    }

    private var layoutSettings: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsGroup(title: "Grid", subtitle: "Tune density while keeping icons inside the screen bounds.") {
                SettingToggleRow(
                    title: "Auto arrange",
                    detail: "Fit rows and columns to the current display automatically.",
                    isOn: Binding(
                        get: { controller.settings.autoArrange },
                        set: { value in controller.update { $0.autoArrange = value } }
                    )
                )

                Divider()

                SettingStepperRow(
                    title: "Columns",
                    detail: "Icons shown per row.",
                    value: controller.settings.clampedColumns,
                    range: 4...12,
                    isDisabled: controller.settings.autoArrange,
                    binding: Binding(
                        get: { controller.settings.columns },
                        set: { value in controller.update { $0.columns = value } }
                    )
                )

                SettingStepperRow(
                    title: "Rows",
                    detail: "Rows shown per page.",
                    value: controller.settings.clampedRows,
                    range: 3...8,
                    isDisabled: controller.settings.autoArrange,
                    binding: Binding(
                        get: { controller.settings.rows },
                        set: { value in controller.update { $0.rows = value } }
                    )
                )

                Divider()

                SettingSliderRow(
                    title: "Icon size",
                    detail: "Controls the visual weight of apps and folders.",
                    valueText: "\(Int(controller.settings.clampedIconSize)) pt",
                    value: Binding(
                        get: { Double(controller.settings.iconSize) },
                        set: { value in controller.update { $0.iconSize = CGFloat(value) } }
                    ),
                    range: 48...112,
                    step: 2
                )
            }

            SettingsGroup(title: "Navigation", subtitle: "Vertical mode scrolls. Horizontal mode snaps page by page.") {
                Picker("Navigation", selection: Binding(
                    get: { controller.settings.navigationMode },
                    set: { value in controller.update { $0.navigationMode = value } }
                )) {
                    Text("Vertical Scroll").tag(LauncherNavigationMode.verticalScroll)
                    Text("Horizontal Pages").tag(LauncherNavigationMode.horizontalPages)
                }
                .pickerStyle(.segmented)

                LayoutPreview(settings: controller.settings)
            }

            SettingsGroup(title: "Keyboard", subtitle: "Keep Glyphpad ready without showing a Dock icon.") {
                HStack(spacing: 16) {
                    SettingFieldLabel(
                        title: "Show or hide launcher",
                        detail: isRecordingHotKey ? "Press a shortcut. Escape cancels." : "Glyphpad stays in the background after closing the launcher."
                    )
                    Spacer()

                    VStack(alignment: .trailing, spacing: 10) {
                        HStack(spacing: 5) {
                            ForEach(HotKeyFormatter.components(for: controller.settings.showHotKey), id: \.self) { component in
                                KeyCap(component)
                            }
                        }

                        HStack(spacing: 8) {
                            Button {
                                isRecordingHotKey = true
                            } label: {
                                Label(isRecordingHotKey ? "Recording" : "Change", systemImage: "keyboard")
                            }
                            .disabled(isRecordingHotKey)

                            Button {
                                controller.update { $0.showHotKey = .default }
                            } label: {
                                Label("Reset", systemImage: "arrow.counterclockwise")
                            }
                            .disabled(controller.settings.showHotKey == .default)
                        }
                    }
                }
                .background(
                    HotKeyCaptureView(
                        isRecording: isRecordingHotKey,
                        onRecord: { hotKey in
                            controller.update { $0.showHotKey = hotKey }
                            isRecordingHotKey = false
                        },
                        onCancel: {
                            isRecordingHotKey = false
                        }
                    )
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
                )
            }
        }
    }

    private var appearanceSettings: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsGroup(title: "Background", subtitle: "Choose the launcher backdrop and blur strength.") {
                BackgroundPreview(settings: controller.settings)

                HStack(spacing: 10) {
                    Button {
                        chooseBackgroundImage()
                    } label: {
                        Label("Choose Image", systemImage: "photo")
                    }

                    Button {
                        controller.update { $0.backgroundImagePath = nil }
                    } label: {
                        Label("Clear", systemImage: "xmark.circle")
                    }
                    .disabled(controller.settings.backgroundImagePath == nil)
                }

                if let backgroundImagePath = controller.settings.backgroundImagePath {
                    Text(backgroundImagePath)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }

                SettingSliderRow(
                    title: "Blur",
                    detail: "Softens the selected image behind app icons.",
                    valueText: "\(Int(controller.settings.clampedBackgroundBlurRadius))",
                    value: Binding(
                        get: { Double(controller.settings.backgroundBlurRadius) },
                        set: { value in controller.update { $0.backgroundBlurRadius = CGFloat(value) } }
                    ),
                    range: 0...48,
                    step: 1
                )
            }
        }
    }

    private var automationSettings: some View {
        SettingsGroup(title: "Classifier API", subtitle: "Used later by automatic app classification.") {
            VStack(alignment: .leading, spacing: 8) {
                SettingFieldLabel(title: "Endpoint", detail: "OpenAI-compatible endpoint for classification.")
                TextField("https://api.example.com/v1", text: Binding(
                    get: { controller.settings.apiEndpoint ?? "" },
                    set: { value in controller.update { $0.apiEndpoint = value } }
                ))
                .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                SettingFieldLabel(title: "API Key", detail: "Stored locally in the Glyphpad SQLite settings record.")
                SecureField("API key", text: Binding(
                    get: { controller.settings.apiKey ?? "" },
                    set: { value in controller.update { $0.apiKey = value } }
                ))
                .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 8) {
                Image(systemName: apiStatusSymbol)
                    .foregroundStyle(apiStatusColor)
                Text(apiStatusText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
    }

    private func chooseBackgroundImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        NSApplication.shared.activate(ignoringOtherApps: true)

        let responseHandler: (NSApplication.ModalResponse) -> Void = { response in
            guard response == .OK, let url = panel.url else {
                return
            }
            controller.update { $0.backgroundImagePath = url.path }
        }

        if let settingsWindow = NSApplication.shared.windows.first(where: { window in
            window.title == "Glyphpad Settings" && window.isVisible
        }) {
            settingsWindow.makeKeyAndOrderFront(nil)
            panel.beginSheetModal(for: settingsWindow, completionHandler: responseHandler)
        } else {
            panel.begin(completionHandler: responseHandler)
        }
    }

    private var apiStatusText: String {
        if controller.settings.apiEndpoint != nil, controller.settings.apiKey != nil {
            return "Endpoint and key configured"
        }
        if controller.settings.apiEndpoint != nil {
            return "Endpoint configured, API key missing"
        }
        return "API is not configured"
    }

    private var apiStatusSymbol: String {
        controller.settings.apiEndpoint != nil && controller.settings.apiKey != nil
            ? "checkmark.circle.fill"
            : "exclamationmark.circle"
    }

    private var apiStatusColor: Color {
        controller.settings.apiEndpoint != nil && controller.settings.apiKey != nil
            ? .green
            : .secondary
    }
}

enum SettingsSection: CaseIterable, Identifiable {
    case layout
    case appearance
    case automation

    var id: Self { self }

    var title: String {
        switch self {
        case .layout:
            return "Layout"
        case .appearance:
            return "Appearance"
        case .automation:
            return "API"
        }
    }

    var subtitle: String {
        switch self {
        case .layout:
            return "Rows, columns, icon size, and paging"
        case .appearance:
            return "Background image and blur"
        case .automation:
            return "Provider settings for classification"
        }
    }

    var symbolName: String {
        switch self {
        case .layout:
            return "square.grid.3x3.fill"
        case .appearance:
            return "photo.fill"
        case .automation:
            return "sparkles"
        }
    }
}

struct SettingsSidebarButton: View {
    let section: SettingsSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: section.symbolName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(section.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(section.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.accentColor.opacity(0.14))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct SettingsGroup<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                content()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }
}

struct SettingFieldLabel: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            Text(detail)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }
}

struct HotKeyCaptureView: NSViewRepresentable {
    let isRecording: Bool
    let onRecord: (LauncherHotKey) -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> HotKeyCaptureNSView {
        let view = HotKeyCaptureNSView()
        view.onRecord = onRecord
        view.onCancel = onCancel
        return view
    }

    func updateNSView(_ nsView: HotKeyCaptureNSView, context: Context) {
        nsView.isRecording = isRecording
        nsView.onRecord = onRecord
        nsView.onCancel = onCancel

        if isRecording {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }
}

final class HotKeyCaptureNSView: NSView {
    var isRecording = false
    var onRecord: ((LauncherHotKey) -> Void)?
    var onCancel: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        if event.keyCode == 53 {
            onCancel?()
            return
        }

        let modifiers = HotKeyFormatter.carbonModifiers(from: event.modifierFlags)
        guard modifiers != 0 else {
            NSSound.beep()
            return
        }

        onRecord?(LauncherHotKey(keyCode: Int(event.keyCode), carbonModifiers: modifiers))
    }
}

enum HotKeyFormatter {
    static func components(for hotKey: LauncherHotKey) -> [String] {
        modifierComponents(for: hotKey.carbonModifiers) + [keyName(for: hotKey.keyCode)]
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        let normalized = flags.intersection(.deviceIndependentFlagsMask)
        var result: UInt32 = 0

        if normalized.contains(.command) {
            result |= UInt32(cmdKey)
        }
        if normalized.contains(.shift) {
            result |= UInt32(shiftKey)
        }
        if normalized.contains(.option) {
            result |= UInt32(optionKey)
        }
        if normalized.contains(.control) {
            result |= UInt32(controlKey)
        }

        return result
    }

    private static func modifierComponents(for carbonModifiers: UInt32) -> [String] {
        var components: [String] = []

        if carbonModifiers & UInt32(controlKey) != 0 {
            components.append("Control")
        }
        if carbonModifiers & UInt32(optionKey) != 0 {
            components.append("Option")
        }
        if carbonModifiers & UInt32(shiftKey) != 0 {
            components.append("Shift")
        }
        if carbonModifiers & UInt32(cmdKey) != 0 {
            components.append("Command")
        }

        return components
    }

    private static func keyName(for keyCode: Int) -> String {
        keyNames[keyCode] ?? "Key \(keyCode)"
    }

    private static let keyNames: [Int: String] = [
        0: "A",
        1: "S",
        2: "D",
        3: "F",
        4: "H",
        5: "G",
        6: "Z",
        7: "X",
        8: "C",
        9: "V",
        11: "B",
        12: "Q",
        13: "W",
        14: "E",
        15: "R",
        16: "Y",
        17: "T",
        18: "1",
        19: "2",
        20: "3",
        21: "4",
        22: "6",
        23: "5",
        24: "=",
        25: "9",
        26: "7",
        27: "-",
        28: "8",
        29: "0",
        30: "]",
        31: "O",
        32: "U",
        33: "[",
        34: "I",
        35: "P",
        37: "L",
        38: "J",
        39: "'",
        40: "K",
        41: ";",
        42: "\\",
        43: ",",
        44: "/",
        45: "N",
        46: "M",
        47: ".",
        48: "Tab",
        49: "Space",
        50: "`",
        51: "Delete",
        53: "Escape",
        76: "Enter",
        96: "F5",
        97: "F6",
        98: "F7",
        99: "F3",
        100: "F8",
        101: "F9",
        103: "F11",
        109: "F10",
        111: "F12",
        115: "Home",
        116: "Page Up",
        117: "Forward Delete",
        118: "F4",
        119: "End",
        120: "F2",
        121: "Page Down",
        122: "F1",
        123: "Left",
        124: "Right",
        125: "Down",
        126: "Up"
    ]
}

struct KeyCap: View {
    let label: String

    init(_ label: String) {
        self.label = label
    }

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 9)
            .frame(height: 26)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            }
    }
}

struct SettingToggleRow: View {
    let title: String
    let detail: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            SettingFieldLabel(title: title, detail: detail)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

struct SettingStepperRow: View {
    let title: String
    let detail: String
    let value: Int
    let range: ClosedRange<Int>
    let isDisabled: Bool
    @Binding var binding: Int

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            SettingFieldLabel(title: title, detail: detail)
            Spacer()
            Text("\(value)")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(isDisabled ? .secondary : .primary)
                .frame(width: 34, alignment: .trailing)
            Stepper("", value: $binding, in: range)
                .labelsHidden()
                .disabled(isDisabled)
        }
        .opacity(isDisabled ? 0.52 : 1)
    }
}

struct SettingSliderRow: View {
    let title: String
    let detail: String
    let valueText: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SettingFieldLabel(title: title, detail: detail)
                Spacer()
                Text(valueText)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}

struct LayoutPreview: View {
    let settings: LauncherSettings

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.18))
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(14), spacing: 8), count: min(settings.clampedColumns, 8)),
                    spacing: 8
                ) {
                    ForEach(0..<min(settings.clampedRows * min(settings.clampedColumns, 8), 32), id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(index % 5 == 0 ? Color.accentColor.opacity(0.84) : Color.primary.opacity(0.22))
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .frame(width: 156, height: 88)

            VStack(alignment: .leading, spacing: 5) {
                Text("\(settings.clampedColumns) x \(settings.clampedRows)")
                    .font(.system(size: 18, weight: .semibold))
                Text(settings.navigationMode == .horizontalPages ? "Snapped pages" : "Continuous vertical scroll")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Icon \(Int(settings.clampedIconSize)) pt")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

struct BackgroundPreview: View {
    let settings: LauncherSettings

    var body: some View {
        ZStack {
            if let image = backgroundImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: min(settings.clampedBackgroundBlurRadius / 4, 10))
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.10, blue: 0.11),
                        Color(red: 0.23, green: 0.23, blue: 0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            Color.black.opacity(0.18)

            HStack(spacing: 18) {
                ForEach(0..<5, id: \.self) { index in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(index == 2 ? Color.accentColor : Color.white.opacity(0.78))
                            .frame(width: 34, height: 34)
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color.white.opacity(0.62))
                            .frame(width: 34, height: 4)
                    }
                }
            }
        }
        .frame(height: 112)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
    }

    private var backgroundImage: NSImage? {
        guard let path = settings.backgroundImagePath else {
            return nil
        }
        return NSImage(contentsOfFile: path)
    }
}

struct FolderOverlay: View {
    let folder: FolderRecord
    let apps: [InstalledApplication]
    let settings: LauncherSettings
    let rename: (String) -> Void
    let launch: (InstalledApplication) -> Void
    let close: () -> Void

    @State private var draftName: String

    init(
        folder: FolderRecord,
        apps: [InstalledApplication],
        settings: LauncherSettings,
        rename: @escaping (String) -> Void,
        launch: @escaping (InstalledApplication) -> Void,
        close: @escaping () -> Void
    ) {
        self.folder = folder
        self.apps = apps
        self.settings = settings
        self.rename = rename
        self.launch = launch
        self.close = close
        _draftName = State(initialValue: folder.name)
    }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.fixed(settings.tileWidth), spacing: settings.horizontalSpacing, alignment: .top),
            count: min(max(apps.count, 2), 4)
        )
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.24)
                .ignoresSafeArea()
                .onTapGesture(perform: close)

            VStack(spacing: 20) {
                TextField("Folder name", text: $draftName, onCommit: {
                    rename(draftName)
                })
                .textFieldStyle(.plain)
                .font(.system(size: 24, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .frame(width: 320)
                .padding(.top, 24)

                LazyVGrid(columns: columns, spacing: settings.verticalSpacing) {
                    ForEach(apps) { app in
                        AppTile(app: app, settings: settings) {
                            launch(app)
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.36), radius: 28, x: 0, y: 16)
        }
    }
}

struct SettingValueLabel: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.white.opacity(0.68))
        }
    }
}
