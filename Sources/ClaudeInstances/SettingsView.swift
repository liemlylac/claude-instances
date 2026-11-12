import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var loginError: String?

    var body: some View {
        Form {
            Section(tr(.general)) {
                Picker(tr(.language), selection: $settings.language) {
                    ForEach(Language.allCases) { Text($0.displayName).tag($0) }
                }
                Toggle(tr(.hideDock), isOn: $settings.hideDock)
                Toggle(tr(.hideMenuBar), isOn: $settings.hideMenuBar)
                Toggle(tr(.launchAtLogin), isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { loginError = settings.setLaunchAtLogin($0) }
                ))
                Toggle(tr(.startHidden), isOn: $settings.startHidden)

                if let loginError {
                    Text(loginError).font(.caption).foregroundStyle(.red)
                }
                if settings.hideDock && settings.hideMenuBar {
                    Label(tr(.warnBothHidden), systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section(tr(.claudeApp)) {
                HStack {
                    TextField("", text: $settings.claudeAppPath)
                        .labelsHidden()
                        .font(.system(.body, design: .monospaced))
                    Button(tr(.choose)) { chooseApp() }
                    Button(tr(.reset)) { settings.claudeAppPath = Paths.claudeApp }
                        .disabled(settings.claudeAppPath == Paths.claudeApp)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = tr(.chooseApp)
        panel.prompt = tr(.choose)
        if panel.runModal() == .OK, let url = panel.url {
            settings.claudeAppPath = url.path
        }
    }
}
