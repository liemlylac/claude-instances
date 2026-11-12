import SwiftUI
import AppKit

struct EditorTarget: Identifiable {
    let id = UUID()
    var profile: Profile?   // nil = tạo mới
}

struct MainView: View {
    @EnvironmentObject private var store: ProfileStore
    @EnvironmentObject private var settings: AppSettings

    @AppStorage("selectedProfile") private var selectedRaw = ""
    @State private var editor: EditorTarget?
    @State private var deleting: Profile?

    private var selection: Binding<UUID?> {
        Binding(get: { UUID(uuidString: selectedRaw) }, set: { selectedRaw = $0?.uuidString ?? "" })
    }

    private var selected: Profile? { store.profile(selection.wrappedValue) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            list
            Divider()
            footer
        }
        .frame(minWidth: 560, minHeight: 380)
        .onAppear {
            if selected == nil { selection.wrappedValue = store.profiles.first?.id }
        }
        .sheet(item: $editor) { target in
            ProfileEditor(original: target.profile) { saved in
                selection.wrappedValue = saved.id
            }
            .environmentObject(store)
            .environmentObject(settings)
        }
        .sheet(item: $deleting) { profile in
            DeleteConfirmView(profile: profile) {
                store.delete(profile.id)
                if selection.wrappedValue == profile.id { selection.wrappedValue = store.profiles.first?.id }
            }
            .environmentObject(settings)
        }
    }

    // MARK: Parts

    private var header: some View {
        HStack(spacing: 10) {
            AppIconView().frame(width: 32, height: 32)
            Text("Claude Instances").font(.title2.bold())
            Spacer()
            Button { editor = EditorTarget(profile: nil) } label: {
                Label(tr(.newProfile), systemImage: "plus")
            }
            Button { (NSApp.delegate as? AppDelegate)?.showSettings() } label: {
                Image(systemName: "gearshape")
            }
            .help(tr(.settings))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var list: some View {
        if store.profiles.isEmpty {
            Text(tr(.emptyList))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(selection: selection) {
                ForEach(store.profiles) { profile in
                    ProfileRow(profile: profile,
                               onPlay: { play(profile) },
                               onDelete: { deleting = profile })
                        .tag(profile.id)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .contextMenu(forSelectionType: UUID.self) { ids in
                if let p = store.profile(ids.first) { menu(for: p) }
            } primaryAction: { ids in
                if let p = store.profile(ids.first) { play(p) }
            }
        }
    }

    @ViewBuilder
    private func menu(for p: Profile) -> some View {
        Button(store.isRunning(p) ? tr(.bringToFront) : tr(.play)) { play(p) }
        if store.isRunning(p) && !p.isDefault {
            Button(tr(.quitInstance)) { store.quit(p) }
        }
        Button(tr(.showInFinder)) { store.reveal(p) }
        if !p.isDefault {
            Divider()
            Button(tr(.edit)) { editor = EditorTarget(profile: p) }
            Button(tr(.delete), role: .destructive) { deleting = p }
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            if let s = store.status {
                Text(tr(s.key, args: s.args))
                    .font(.callout)
                    .foregroundStyle(s.isError ? Color.red : Color.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }
            Spacer()
            if let p = selected {
                Button(tr(.showInFinder)) { store.reveal(p) }
                Button { play(p) } label: {
                    Label(store.isRunning(p) ? tr(.bringToFront) : tr(.play),
                          systemImage: store.isRunning(p) ? "macwindow" : "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(store.isLaunching(p))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func play(_ p: Profile) {
        selection.wrappedValue = p.id
        store.launch(p)
    }
}

// MARK: - Row

struct ProfileRow: View {
    @EnvironmentObject private var store: ProfileStore
    @EnvironmentObject private var settings: AppSettings
    let profile: Profile
    let onPlay: () -> Void
    let onDelete: () -> Void

    var body: some View {
        let running = store.isRunning(profile)
        HStack(spacing: 10) {
            Circle()
                .fill(running ? Color.green : Color.secondary.opacity(0.35))
                .frame(width: 9, height: 9)
                .help(running ? tr(.running) : "")
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(store.displayName(profile)).font(.body.weight(.medium))
                    if profile.isDefault {
                        Text(tr(.defaultBadge))
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(Capsule().fill(Color.accentColor.opacity(0.18)))
                    }
                }
                Text([store.accounts[profile.id]?.email, profile.path].compactMap { $0 }.joined(separator: "  ·  "))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            if store.isLaunching(profile) {
                ProgressView().controlSize(.small)
            }
            Button(action: onPlay) {
                Label(running ? tr(.bringToFront) : tr(.play),
                      systemImage: running ? "macwindow" : "play.fill")
            }
            .buttonStyle(.bordered)
            .tint(running ? .green : .accentColor)
            .controlSize(.small)
            .disabled(store.isLaunching(profile))

            // Default không xoá được → ẩn nút nhưng giữ chỗ để các cột thẳng hàng
            Button(action: onDelete) {
                Label(tr(.delete), systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .controlSize(.small)
            .opacity(profile.isDefault ? 0 : 1)
            .disabled(profile.isDefault)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Editor

struct ProfileEditor: View {
    @EnvironmentObject private var store: ProfileStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    let original: Profile?
    let onSave: (Profile) -> Void

    @State private var name = ""
    @State private var path = ""

    private var error: L? { store.validate(name: name, path: path, excluding: original?.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(original == nil ? tr(.newProfile) : tr(.editProfile)).font(.title3.bold())

            VStack(alignment: .leading, spacing: 6) {
                Text(tr(.name)).font(.headline)
                TextField("Work", text: $name).textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(tr(.path)).font(.headline)
                HStack {
                    TextField("~/.claude-instances/work", text: $path)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    Button(tr(.choose)) {
                        if let picked = chooseFolder(current: path) { path = picked }
                    }
                }
                Text(tr(.pathHint)).font(.caption).foregroundStyle(.secondary)
            }

            if let error, !(name.isEmpty && path.isEmpty) {
                Text(tr(error)).font(.callout).foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button(tr(.cancel), role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(tr(.save)) { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(error != nil)
            }
        }
        .padding(20)
        .frame(width: 460)
        .onAppear {
            name = original?.name ?? ""
            path = original?.path ?? ""
        }
        .onChange(of: name) { newName in
            // Gợi ý đường dẫn từ tên khi tạo mới và người dùng chưa tự nhập đường dẫn
            guard original == nil else { return }
            let slug = newName.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }.joined(separator: "-")
            if path.isEmpty || path.hasPrefix("~/.claude-instances/") {
                path = slug.isEmpty ? "" : "~/.claude-instances/\(slug)"
            }
        }
    }

    private func save() {
        guard error == nil else { return }
        if var p = original {
            p.name = name
            p.path = path
            store.update(p)
            onSave(p)
        } else {
            onSave(store.add(name: name, path: path))
        }
        dismiss()
    }

    private func chooseFolder(current: String) -> String? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = tr(.choose)
        panel.message = tr(.chooseFolder)
        var url = URL(fileURLWithPath: expandPath(current.isEmpty ? "~/.claude-instances" : current))
        while !FileManager.default.fileExists(atPath: url.path) && url.path != "/" {
            url.deleteLastPathComponent()
        }
        panel.directoryURL = url
        guard panel.runModal() == .OK, let picked = panel.url else { return nil }
        return abbreviatePath(picked.path)
    }
}

// MARK: - Delete confirmation

struct DeleteConfirmView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    let profile: Profile
    let onConfirm: () -> Void

    @State private var typed = ""
    @State private var finalStep = false

    private var matches: Bool { typed.trimmingCharacters(in: .whitespacesAndNewlines) == profile.name }

    var body: some View {
        Group {
            if finalStep { finalConfirm } else { typeName }
        }
        .padding(20)
        .frame(width: 420)
    }

    /// Bước 1: gõ lại đúng tên profile rồi bấm Tiếp tục.
    private var typeName: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 6) {
                    Text(tr(.deleteTitle, profile.name)).font(.headline)
                    Text(tr(.deleteMessage)).font(.callout).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Text(tr(.deleteTypeName, profile.name)).font(.callout)
            TextField(profile.name, text: $typed)
                .textFieldStyle(.roundedBorder)
                .onSubmit { if matches { finalStep = true } }
            HStack {
                Spacer()
                Button(tr(.cancel)) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(tr(.continueAction)) { finalStep = true }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!matches)
            }
        }
    }

    /// Bước 2: xác nhận cuối — Delete đỏ, Cancel xám.
    private var finalConfirm: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "trash.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 6) {
                    Text(tr(.deleteFinalTitle, profile.name)).font(.headline)
                    Text(tr(.deleteFinalMessage)).font(.callout).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Text(tr(.cancel)).frame(minWidth: 70)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .keyboardShortcut(.cancelAction)

                Button(role: .destructive) {
                    onConfirm()
                    dismiss()
                } label: {
                    Label(tr(.delete), systemImage: "trash").frame(minWidth: 70)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
            }
        }
    }
}

// MARK: - Icon

struct AppIconView: View {
    var body: some View {
        if let icon = NSImage(named: "AppIcon") ?? Bundle.main.image(forResource: "AppIcon") {
            Image(nsImage: icon).resizable().interpolation(.high)
        } else {
            Image(nsImage: NSApp.applicationIconImage).resizable()
        }
    }
}
