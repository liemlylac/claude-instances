import Foundation

struct AccountInfo: Equatable {
    var name: String?
    var email: String?

    var label: String? { name ?? email }
}

/// Đọc tài khoản đang đăng nhập của một thư mục dữ liệu Claude Desktop.
///
/// Claude không lưu tên/email dạng plain JSON. Nguồn dùng được:
/// - `config.json`: `lastKnownAccountUuid` + `oauth:tokenCache*` (chỉ có khi đang đăng nhập).
/// - IndexedDB của claude.ai: cache thông tin account dạng V8-serialized,
///   có các khoá `uuid`, `email_address`, `full_name`, `display_name`.
/// Đây là định dạng nội bộ, có thể đổi khi Claude cập nhật → mọi lỗi đều trả về nil.
enum AccountReader {
    static func read(dataDir: String) -> AccountInfo? {
        let root = URL(fileURLWithPath: dataDir)
        guard let cfgData = try? Data(contentsOf: root.appendingPathComponent("config.json")),
              let cfg = try? JSONSerialization.jsonObject(with: cfgData) as? [String: Any],
              cfg.keys.contains(where: { $0.hasPrefix("oauth:tokenCache") })
        else { return nil }   // chưa đăng nhập

        let accountUUID = cfg["lastKnownAccountUuid"] as? String
        let idb = root.appendingPathComponent("IndexedDB")
        guard let files = FileManager.default.enumerator(
            at: idb, includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey, .fileSizeKey]
        ) else { return nil }

        var best: (info: AccountInfo, date: Date)?
        for case let url as URL in files where url.path.contains("claude.ai") {
            guard let v = try? url.resourceValues(forKeys: [.isRegularFileKey, .contentModificationDateKey, .fileSizeKey]),
                  v.isRegularFile == true, (v.fileSize ?? 0) < 64 << 20,
                  let data = try? Data(contentsOf: url, options: .mappedIfSafe),
                  let info = scan(data, accountUUID: accountUUID)
            else { continue }
            let date = v.contentModificationDate ?? .distantPast
            if best == nil || date > best!.date { best = (info, date) }
        }
        return best?.info
    }

    private static let emailKey = Data("email_address".utf8)
    private static let uuidRegex = try! NSRegularExpression(
        pattern: "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}")

    private static func scan(_ data: Data, accountUUID: String?) -> AccountInfo? {
        var searchStart = data.startIndex
        while let r = data.range(of: emailKey, in: searchStart..<data.endIndex) {
            searchStart = r.upperBound
            // uuid của account nằm ngay trước khoá email_address
            if let accountUUID {
                let lo = data.index(r.lowerBound, offsetBy: -80, limitedBy: data.startIndex) ?? data.startIndex
                let window = String(decoding: data[lo..<r.lowerBound], as: UTF8.self)
                let ns = window as NSString
                let last = uuidRegex.matches(in: window, range: NSRange(location: 0, length: ns.length)).last
                guard let last, ns.substring(with: last.range) == accountUUID else { continue }
            }
            guard let email = v8String(in: data, at: r.upperBound), email.contains("@") else { continue }
            let hi = data.index(r.upperBound, offsetBy: 400, limitedBy: data.endIndex) ?? data.endIndex
            let display = value(for: "display_name", in: data, range: r.upperBound..<hi)
            let full = value(for: "full_name", in: data, range: r.upperBound..<hi)
            let name = [display, full].compactMap { $0 }.first { !$0.isEmpty }
            return AccountInfo(name: name, email: email)
        }
        return nil
    }

    private static func value(for key: String, in data: Data, range: Range<Data.Index>) -> String? {
        guard let r = data.range(of: Data(key.utf8), in: range) else { return nil }
        return v8String(in: data, at: r.upperBound)
    }

    /// Đọc một chuỗi V8-serialized: tag ('"' latin1, 'c' UTF-16LE, 'S' UTF-8) + độ dài varint + bytes.
    private static func v8String(in data: Data, at start: Data.Index) -> String? {
        var i = start
        while i < data.endIndex && data[i] == 0 { i += 1 }   // padding trước chuỗi 2-byte
        guard i < data.endIndex else { return nil }
        let tag = data[i]; i += 1

        var len = 0, shift = 0
        while i < data.endIndex {
            let b = data[i]; i += 1
            len |= Int(b & 0x7F) << shift
            if b & 0x80 == 0 { break }
            shift += 7
            if shift > 28 { return nil }
        }
        guard len > 0, len < 512, let end = data.index(i, offsetBy: len, limitedBy: data.endIndex) else { return nil }
        let bytes = data[i..<end]
        switch tag {
        case UInt8(ascii: "\""): return String(bytes: bytes, encoding: .isoLatin1)
        case UInt8(ascii: "c"):  return String(bytes: bytes, encoding: .utf16LittleEndian)
        case UInt8(ascii: "S"):  return String(bytes: bytes, encoding: .utf8)
        default: return nil
        }
    }
}
