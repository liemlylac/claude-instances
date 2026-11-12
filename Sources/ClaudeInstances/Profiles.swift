import AppKit
import Combine

// MARK: - Paths

enum Paths {
    /// Profile mặc định: mở Claude bình thường (không thêm --user-data-dir).
    static let defaultProfile = "~/.claude"
    static let personalProfile = "~/.claude-instances/personal"
    /// Thư mục dữ liệu của instance gốc — không được dùng làm --user-data-dir, sẽ đụng lock.
    static let originalData = "~/Library/Application Support/Claude"
    static let claudeApp = "/Applications/Claude.app"
}

func expandPath(_ path: String) -> String {
    let p = (path.trimmingCharacters(in: .whitespacesAndNewlines) as NSString).expandingTildeInPath
    guard !p.isEmpty else { return "" }
    return URL(fileURLWithPath: p).standardizedFileURL.path
}

func abbreviatePath(_ path: String) -> String {
    (path as NSString).abbreviatingWithTildeInPath
}

// MARK: - Model

struct Profile: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var path: String

    var isDefault: Bool { expandPath(path) == expandPath(Paths.defaultProfile) }

    /// Thư mục dữ liệu Claude Desktop thực tế của profile (Default dùng thư mục gốc).
    var dataDir: String { isDefault ? expandPath(Paths.originalData) : expandPath(path) }
}

struct StatusMessage: Equatable {
    var key: L
    var args: [String] = []
    var isError = false
}

// MARK: - Store

@MainActor
final class ProfileStore: ObservableObject {
    static let shared = ProfileStore()

    @Published private(set) var profiles: [Profile] = []
    @Published private(set) var running: [UUID: NSRunningApplication] = [:]
    @Published private(set) var launching: Set<UUID> = []
    @Published var status: StatusMessage?
    /// Tài khoản đang đăng nhập của từng profile (nil = chưa đăng nhập / không đọc được).
    @Published private(set) var accounts: [UUID: AccountInfo] = [:]
    private var accountTimer: Timer?

    private let storageKey = "profiles.v1"
    private var observers: [NSObjectProtocol] = []
    private var timer: Timer?

    private init() {
        load()
        let nc = NSWorkspace.shared.notificationCenter
        observers.append(nc.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            MainActor.assumeIsolated { self?.handleTermination(of: app) }
        })
        observers.append(nc.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshRunning() }
        })
        // Phòng trường hợp bỏ lỡ notification (vd. instance mở từ Terminal) — quét lại định kỳ.
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshRunning() }
        }
        refreshRunning()

        accountTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshAccounts() }
        }
        refreshAccounts()
    }

    // MARK: Accounts

    /// Đọc tài khoản đăng nhập của mọi profile ở background (quét IndexedDB có thể mất chút thời gian).
    func refreshAccounts() {
        let dirs = profiles.map { ($0.id, $0.dataDir) }
        Task.detached(priority: .utility) {
            var result: [UUID: AccountInfo] = [:]
            for (id, dir) in dirs {
                if let info = AccountReader.read(dataDir: dir) { result[id] = info }
            }
            let found = result
            await MainActor.run {
                if self.accounts != found { self.accounts = found }
            }
        }
    }

    /// "Default (John)" — tên hiển thị kèm tài khoản đang đăng nhập.
    func displayName(_ p: Profile) -> String {
        guard let label = accounts[p.id]?.label else { return p.name }
        return "\(p.name) (\(label))"
    }

    // MARK: Detect running instances

    /// Quét các process Claude đang chạy, đọc cờ --user-data-dir để biết profile nào đang chạy.
    func refreshRunning() {
        let appURL = URL(fileURLWithPath: expandPath(AppSettings.shared.claudeAppPath))
        guard let bundleID = Bundle(url: appURL)?.bundleIdentifier else { return }

        var detected: [UUID: NSRunningApplication] = [:]
        for app in NSRunningApplication.runningApplications(withBundleIdentifier: bundleID) where !app.isTerminated {
            guard let args = processArguments(pid: app.processIdentifier) else { continue }
            let dir = userDataDir(in: args)
            let match = profiles.first { p in
                if let dir { return !p.isDefault && expandPath(p.path) == expandPath(dir) }
                return p.isDefault
            }
            if let match { detected[match.id] = app }
        }

        let old = running.mapValues(\.processIdentifier)
        let new = detected.mapValues(\.processIdentifier)
        if old != new {
            running = detected
            refreshAccounts()   // vừa mở/đóng instance → có thể vừa đăng nhập/đăng xuất
        }
    }

    private func userDataDir(in args: [String]) -> String? {
        for (i, a) in args.enumerated() {
            if a.hasPrefix("--user-data-dir=") { return String(a.dropFirst("--user-data-dir=".count)) }
            if a == "--user-data-dir", i + 1 < args.count { return args[i + 1] }
        }
        return nil
    }

    /// Đọc argv của một process qua sysctl(KERN_PROCARGS2).
    private func processArguments(pid: pid_t) -> [String]? {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = 0
        guard sysctl(&mib, 3, nil, &size, nil, 0) == 0, size > 4 else { return nil }
        var buf = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, 3, &buf, &size, nil, 0) == 0 else { return nil }

        let argc = buf.withUnsafeBytes { Int($0.load(as: Int32.self)) }
        var i = 4
        while i < size && buf[i] != 0 { i += 1 }   // bỏ qua đường dẫn executable
        while i < size && buf[i] == 0 { i += 1 }   // bỏ qua padding
        var args: [String] = []
        while args.count < argc && i < size {
            let start = i
            while i < size && buf[i] != 0 { i += 1 }
            args.append(String(decoding: buf[start..<i], as: UTF8.self))
            i += 1
        }
        return args
    }

    // MARK: Persistence

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Profile].self, from: data) {
            profiles = decoded
        } else {
            profiles = [
                Profile(id: UUID(), name: "Default", path: Paths.defaultProfile),
                Profile(id: UUID(), name: "Personal", path: Paths.personalProfile),
            ]
            save()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func profile(_ id: UUID?) -> Profile? {
        profiles.first { $0.id == id }
    }

    // MARK: CRUD

    /// Trả về lỗi (nếu có) cho tên/đường dẫn mới.
    func validate(name: String, path: String, excluding id: UUID? = nil) -> L? {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let full = expandPath(path)
        if name.isEmpty { return .errNameEmpty }
        if full.isEmpty || full == "/" { return .errInvalidPath }
        if full == expandPath(Paths.originalData) { return .errOriginal }
        let others = profiles.filter { $0.id != id }
        if others.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) { return .errNameDuplicate }
        if others.contains(where: { expandPath($0.path) == full }) { return .errPathDuplicate }
        return nil
    }

    @discardableResult
    func add(name: String, path: String) -> Profile {
        let p = Profile(id: UUID(),
                        name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                        path: abbreviatePath(expandPath(path)))
        profiles.append(p)
        save()
        refreshRunning()
        refreshAccounts()
        return p
    }

    func update(_ profile: Profile) {
        guard let i = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        var p = profile
        p.name = p.name.trimmingCharacters(in: .whitespacesAndNewlines)
        p.path = abbreviatePath(expandPath(p.path))
        profiles[i] = p
        save()
        refreshRunning()
        refreshAccounts()
    }

    /// Chỉ xoá khỏi danh sách — thư mục trên đĩa được giữ nguyên.
    func delete(_ id: UUID) {
        profiles.removeAll { $0.id == id }
        running[id] = nil
        save()
    }

    // MARK: Running

    func isRunning(_ p: Profile) -> Bool {
        running[p.id].map { !$0.isTerminated } ?? false
    }

    func isLaunching(_ p: Profile) -> Bool { launching.contains(p.id) }

    private func handleTermination(of app: NSRunningApplication) {
        guard let (id, _) = running.first(where: { $0.value.processIdentifier == app.processIdentifier }) else { return }
        running[id] = nil
        if let p = profile(id) { status = StatusMessage(key: .statusExited, args: [p.name]) }
    }

    func launch(_ p: Profile) {
        refreshRunning()
        if let app = running[p.id], !app.isTerminated {
            app.activate()
            return
        }

        let appPath = expandPath(AppSettings.shared.claudeAppPath)
        let appURL = URL(fileURLWithPath: appPath)
        guard FileManager.default.fileExists(atPath: appPath) else {
            status = StatusMessage(key: .errAppNotFound, args: [appPath], isError: true)
            return
        }

        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        config.activates = true

        if !p.isDefault {
            let profileDir = expandPath(p.path)
            if let err = validate(name: p.name, path: p.path, excluding: p.id) {
                status = StatusMessage(key: err, isError: true)
                return
            }
            do {
                try FileManager.default.createDirectory(atPath: profileDir, withIntermediateDirectories: true)
            } catch {
                status = StatusMessage(key: .errCreateDir, args: [error.localizedDescription], isError: true)
                return
            }
            config.arguments = ["--user-data-dir=\(profileDir)"]
        }

        launching.insert(p.id)
        status = StatusMessage(key: .statusLaunching, args: [p.name])

        NSWorkspace.shared.openApplication(at: appURL, configuration: config) { app, error in
            DispatchQueue.main.async {
                self.launching.remove(p.id)
                if let error {
                    self.status = StatusMessage(key: .errLaunch, args: [error.localizedDescription], isError: true)
                } else {
                    self.running[p.id] = app
                    self.status = StatusMessage(key: .statusLaunched, args: [p.name])
                }
            }
        }
    }

    func quit(_ p: Profile) {
        running[p.id]?.terminate()
    }

    func reveal(_ p: Profile) {
        let dir = expandPath(p.path)
        if FileManager.default.fileExists(atPath: dir) {
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: dir)])
        } else {
            status = StatusMessage(key: .errFolderMissing)
        }
    }
}
