import Foundation
import ServiceManagement

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let d = UserDefaults.standard

    @Published var language: Language { didSet { d.set(language.rawValue, forKey: "language") } }
    @Published var hideDock: Bool { didSet { d.set(hideDock, forKey: "hideDock") } }
    @Published var hideMenuBar: Bool { didSet { d.set(hideMenuBar, forKey: "hideMenuBar") } }
    @Published var startHidden: Bool { didSet { d.set(startHidden, forKey: "startHidden") } }
    @Published var claudeAppPath: String { didSet { d.set(claudeAppPath, forKey: "claudeAppPath") } }

    private init() {
        language = d.string(forKey: "language").flatMap(Language.init(rawValue:)) ?? .systemPreferred
        hideDock = d.bool(forKey: "hideDock")
        hideMenuBar = d.bool(forKey: "hideMenuBar")
        startHidden = d.bool(forKey: "startHidden")
        claudeAppPath = d.string(forKey: "claudeAppPath") ?? Paths.claudeApp
    }

    // MARK: Launch at login (SMAppService — chỉ hoạt động khi chạy từ .app bundle)

    var launchAtLogin: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Trả về thông báo lỗi nếu thất bại.
    func setLaunchAtLogin(_ on: Bool) -> String? {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return tr(.loginNeedsBundle) }
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            objectWillChange.send()
            return nil
        } catch {
            return tr(.loginError, error.localizedDescription)
        }
    }
}
