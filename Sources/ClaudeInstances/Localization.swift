import Foundation

enum Language: String, CaseIterable, Identifiable {
    case en, ja, ko, th, zh, vi
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .en: "English"
        case .ja: "日本語"
        case .ko: "한국어"
        case .th: "ไทย"
        case .zh: "中文"
        case .vi: "Tiếng Việt"
        }
    }

    static var systemPreferred: Language {
        for id in Locale.preferredLanguages {
            let code = String(id.prefix(2))
            if let lang = Language(rawValue: code) { return lang }
        }
        return .en
    }
}

enum L: String {
    case profiles, newProfile, editProfile, name, path, choose, cancel, save, delete, play
    case bringToFront, quitInstance, showInFinder, edit, running, defaultBadge
    case settings, language, general, hideDock, hideMenuBar, launchAtLogin, startHidden, claudeApp, reset
    case deleteTitle, deleteMessage, deleteTypeName, continueAction, deleteFinalTitle, deleteFinalMessage
    case emptyList, pathHint, defaultNote, chooseApp, chooseFolder
    case statusLaunching, statusLaunched, statusExited
    case errAppNotFound, errInvalidPath, errOriginal, errCreateDir, errLaunch, errFolderMissing
    case errNameEmpty, errNameDuplicate, errPathDuplicate
    case warnBothHidden, loginError, loginNeedsBundle
    case showWindow, quitApp, hideApp, about
    case editMenu, undo, redo, cut, copy, paste, selectAll, windowMenu, minimize, close
}

/// Dịch theo ngôn ngữ đang chọn trong Settings. `%@` được thay bằng args.
@MainActor
func tr(_ key: L, _ args: String...) -> String {
    tr(key, args: args)
}

@MainActor
func tr(_ key: L, args: [String]) -> String {
    let lang = AppSettings.shared.language
    let format = strings[lang]?[key] ?? strings[.en]?[key] ?? key.rawValue
    guard !args.isEmpty else { return format }
    return String(format: format, arguments: args.map { $0 as CVarArg })
}

private let strings: [Language: [L: String]] = [
    .en: [
        .profiles: "Profiles", .newProfile: "New Profile", .editProfile: "Edit Profile",
        .name: "Name", .path: "Path", .choose: "Choose…", .cancel: "Cancel", .save: "Save",
        .delete: "Delete", .play: "Play", .bringToFront: "Bring to Front", .quitInstance: "Quit Instance",
        .showInFinder: "Show in Finder", .edit: "Edit…", .running: "Running", .defaultBadge: "Default",
        .settings: "Settings", .language: "Language", .general: "General",
        .hideDock: "Hide from Dock", .hideMenuBar: "Hide from menu bar", .launchAtLogin: "Launch at login",
        .startHidden: "Start hidden", .claudeApp: "Claude app", .reset: "Reset",
        .deleteTitle: "Delete profile “%@”?",
        .deleteMessage: "The profile is removed from the list. Its folder on disk is kept.",
        .deleteTypeName: "Type “%@” to confirm",
        .continueAction: "Continue", .deleteFinalTitle: "Delete “%@”?",
        .deleteFinalMessage: "This removes the profile from the list and cannot be undone.",
        .emptyList: "No profiles yet. Press + to create one.",
        .pathHint: "Each folder is a separate signed-in session. It is created on first launch.",
        .defaultNote: "Opens Claude normally with its original data.",
        .chooseApp: "Choose Claude.app", .chooseFolder: "Choose a profile folder",
        .statusLaunching: "Launching “%@”…", .statusLaunched: "“%@” is running. The first launch needs a sign-in.",
        .statusExited: "“%@” exited.",
        .errAppNotFound: "Claude app not found at %@.", .errInvalidPath: "Invalid profile path.",
        .errOriginal: "That is the original Claude data folder — choose another path.",
        .errCreateDir: "Could not create the profile folder: %@", .errLaunch: "Launch failed: %@",
        .errFolderMissing: "The folder doesn't exist yet — it will be created when you press Play.",
        .errNameEmpty: "Name is required.", .errNameDuplicate: "A profile with this name already exists.",
        .errPathDuplicate: "Another profile already uses this path.",
        .warnBothHidden: "Dock and menu bar icons are both hidden. Open the app again from Finder or Launchpad to show the window.",
        .loginError: "Could not change the login item: %@",
        .loginNeedsBundle: "Launch at login only works when running the built .app.",
        .showWindow: "Open Claude Instances", .quitApp: "Quit Claude Instances", .hideApp: "Hide Claude Instances",
        .about: "About Claude Instances",
        .editMenu: "Edit", .undo: "Undo", .redo: "Redo", .cut: "Cut", .copy: "Copy", .paste: "Paste",
        .selectAll: "Select All", .windowMenu: "Window", .minimize: "Minimize", .close: "Close",
    ],
    .ja: [
        .profiles: "プロファイル", .newProfile: "新規プロファイル", .editProfile: "プロファイルを編集",
        .name: "名前", .path: "パス", .choose: "選択…", .cancel: "キャンセル", .save: "保存",
        .delete: "削除", .play: "起動", .bringToFront: "前面に表示", .quitInstance: "インスタンスを終了",
        .showInFinder: "Finderで表示", .edit: "編集…", .running: "実行中", .defaultBadge: "デフォルト",
        .settings: "設定", .language: "言語", .general: "一般",
        .hideDock: "Dockに表示しない", .hideMenuBar: "メニューバーに表示しない", .launchAtLogin: "ログイン時に起動",
        .startHidden: "非表示で起動", .claudeApp: "Claudeアプリ", .reset: "リセット",
        .deleteTitle: "プロファイル「%@」を削除しますか？",
        .deleteMessage: "リストから削除されます。ディスク上のフォルダは残ります。",
        .deleteTypeName: "確認のため「%@」と入力してください",
        .continueAction: "続ける", .deleteFinalTitle: "「%@」を削除しますか？",
        .deleteFinalMessage: "プロファイルがリストから削除されます。この操作は取り消せません。",
        .emptyList: "プロファイルがありません。+ を押して作成してください。",
        .pathHint: "フォルダごとに別のログインセッションになります。初回起動時に作成されます。",
        .defaultNote: "元のデータでClaudeを通常どおり開きます。",
        .chooseApp: "Claude.appを選択", .chooseFolder: "プロファイルフォルダを選択",
        .statusLaunching: "「%@」を起動中…", .statusLaunched: "「%@」を実行中です。初回はログインが必要です。",
        .statusExited: "「%@」が終了しました。",
        .errAppNotFound: "%@ にClaudeアプリが見つかりません。", .errInvalidPath: "プロファイルのパスが無効です。",
        .errOriginal: "これは元のClaudeのデータフォルダです。別のパスを選んでください。",
        .errCreateDir: "プロファイルフォルダを作成できません: %@", .errLaunch: "起動に失敗しました: %@",
        .errFolderMissing: "フォルダはまだありません。起動時に作成されます。",
        .errNameEmpty: "名前を入力してください。", .errNameDuplicate: "同じ名前のプロファイルが既にあります。",
        .errPathDuplicate: "このパスは別のプロファイルで使用中です。",
        .warnBothHidden: "Dockとメニューバーの両方で非表示です。ウインドウを表示するにはFinderかLaunchpadからもう一度アプリを開いてください。",
        .loginError: "ログイン項目を変更できません: %@",
        .loginNeedsBundle: "ログイン時の起動はビルドした .app から実行した場合のみ有効です。",
        .showWindow: "Claude Instancesを開く", .quitApp: "Claude Instancesを終了", .hideApp: "Claude Instancesを隠す",
        .about: "Claude Instancesについて",
        .editMenu: "編集", .undo: "取り消す", .redo: "やり直す", .cut: "カット", .copy: "コピー", .paste: "ペースト",
        .selectAll: "すべてを選択", .windowMenu: "ウインドウ", .minimize: "しまう", .close: "閉じる",
    ],
    .ko: [
        .profiles: "프로필", .newProfile: "새 프로필", .editProfile: "프로필 편집",
        .name: "이름", .path: "경로", .choose: "선택…", .cancel: "취소", .save: "저장",
        .delete: "삭제", .play: "실행", .bringToFront: "앞으로 가져오기", .quitInstance: "인스턴스 종료",
        .showInFinder: "Finder에서 보기", .edit: "편집…", .running: "실행 중", .defaultBadge: "기본",
        .settings: "설정", .language: "언어", .general: "일반",
        .hideDock: "Dock에서 숨기기", .hideMenuBar: "메뉴 막대에서 숨기기", .launchAtLogin: "로그인 시 실행",
        .startHidden: "숨긴 상태로 시작", .claudeApp: "Claude 앱", .reset: "초기화",
        .deleteTitle: "프로필 “%@”을(를) 삭제할까요?",
        .deleteMessage: "목록에서만 제거됩니다. 디스크의 폴더는 유지됩니다.",
        .deleteTypeName: "확인하려면 “%@”을(를) 입력하세요",
        .continueAction: "계속", .deleteFinalTitle: "“%@”을(를) 삭제할까요?",
        .deleteFinalMessage: "프로필이 목록에서 제거되며 되돌릴 수 없습니다.",
        .emptyList: "프로필이 없습니다. +를 눌러 만드세요.",
        .pathHint: "폴더마다 별도의 로그인 세션입니다. 처음 실행할 때 생성됩니다.",
        .defaultNote: "원래 데이터로 Claude를 평소처럼 엽니다.",
        .chooseApp: "Claude.app 선택", .chooseFolder: "프로필 폴더 선택",
        .statusLaunching: "“%@” 실행 중…", .statusLaunched: "“%@” 실행 중입니다. 처음에는 로그인이 필요합니다.",
        .statusExited: "“%@”이(가) 종료되었습니다.",
        .errAppNotFound: "%@에서 Claude 앱을 찾을 수 없습니다.", .errInvalidPath: "프로필 경로가 올바르지 않습니다.",
        .errOriginal: "원래 Claude 데이터 폴더입니다. 다른 경로를 선택하세요.",
        .errCreateDir: "프로필 폴더를 만들 수 없습니다: %@", .errLaunch: "실행 실패: %@",
        .errFolderMissing: "폴더가 아직 없습니다. 실행할 때 생성됩니다.",
        .errNameEmpty: "이름을 입력하세요.", .errNameDuplicate: "같은 이름의 프로필이 이미 있습니다.",
        .errPathDuplicate: "다른 프로필이 이미 이 경로를 사용 중입니다.",
        .warnBothHidden: "Dock과 메뉴 막대 아이콘이 모두 숨겨져 있습니다. 창을 보려면 Finder나 Launchpad에서 앱을 다시 여세요.",
        .loginError: "로그인 항목을 변경할 수 없습니다: %@",
        .loginNeedsBundle: "로그인 시 실행은 빌드된 .app에서 실행할 때만 동작합니다.",
        .showWindow: "Claude Instances 열기", .quitApp: "Claude Instances 종료", .hideApp: "Claude Instances 숨기기",
        .about: "Claude Instances에 관하여",
        .editMenu: "편집", .undo: "실행 취소", .redo: "실행 복귀", .cut: "오려두기", .copy: "복사하기", .paste: "붙여넣기",
        .selectAll: "전체 선택", .windowMenu: "윈도우", .minimize: "최소화", .close: "닫기",
    ],
    .th: [
        .profiles: "โปรไฟล์", .newProfile: "โปรไฟล์ใหม่", .editProfile: "แก้ไขโปรไฟล์",
        .name: "ชื่อ", .path: "พาธ", .choose: "เลือก…", .cancel: "ยกเลิก", .save: "บันทึก",
        .delete: "ลบ", .play: "เปิด", .bringToFront: "นำมาด้านหน้า", .quitInstance: "ปิดอินสแตนซ์",
        .showInFinder: "แสดงใน Finder", .edit: "แก้ไข…", .running: "กำลังทำงาน", .defaultBadge: "ค่าเริ่มต้น",
        .settings: "การตั้งค่า", .language: "ภาษา", .general: "ทั่วไป",
        .hideDock: "ซ่อนจาก Dock", .hideMenuBar: "ซ่อนจากแถบเมนู", .launchAtLogin: "เปิดเมื่อเข้าสู่ระบบ",
        .startHidden: "เริ่มแบบซ่อน", .claudeApp: "แอป Claude", .reset: "รีเซ็ต",
        .deleteTitle: "ลบโปรไฟล์ “%@” หรือไม่?",
        .deleteMessage: "โปรไฟล์จะถูกนำออกจากรายการ โฟลเดอร์บนดิสก์ยังคงอยู่",
        .deleteTypeName: "พิมพ์ “%@” เพื่อยืนยัน",
        .continueAction: "ดำเนินการต่อ", .deleteFinalTitle: "ลบ “%@” หรือไม่?",
        .deleteFinalMessage: "โปรไฟล์จะถูกนำออกจากรายการ และไม่สามารถย้อนกลับได้",
        .emptyList: "ยังไม่มีโปรไฟล์ กด + เพื่อสร้าง",
        .pathHint: "แต่ละโฟลเดอร์คือเซสชันการลงชื่อเข้าใช้แยกกัน จะถูกสร้างเมื่อเปิดครั้งแรก",
        .defaultNote: "เปิด Claude ตามปกติด้วยข้อมูลเดิม",
        .chooseApp: "เลือก Claude.app", .chooseFolder: "เลือกโฟลเดอร์โปรไฟล์",
        .statusLaunching: "กำลังเปิด “%@”…", .statusLaunched: "“%@” กำลังทำงาน ครั้งแรกต้องลงชื่อเข้าใช้",
        .statusExited: "“%@” ปิดแล้ว",
        .errAppNotFound: "ไม่พบแอป Claude ที่ %@", .errInvalidPath: "พาธโปรไฟล์ไม่ถูกต้อง",
        .errOriginal: "นี่คือโฟลเดอร์ข้อมูลเดิมของ Claude — โปรดเลือกพาธอื่น",
        .errCreateDir: "สร้างโฟลเดอร์โปรไฟล์ไม่ได้: %@", .errLaunch: "เปิดไม่สำเร็จ: %@",
        .errFolderMissing: "ยังไม่มีโฟลเดอร์ — จะถูกสร้างเมื่อกดเปิด",
        .errNameEmpty: "ต้องระบุชื่อ", .errNameDuplicate: "มีโปรไฟล์ชื่อนี้อยู่แล้ว",
        .errPathDuplicate: "พาธนี้ถูกใช้โดยโปรไฟล์อื่นแล้ว",
        .warnBothHidden: "ไอคอนใน Dock และแถบเมนูถูกซ่อนทั้งคู่ เปิดแอปอีกครั้งจาก Finder หรือ Launchpad เพื่อแสดงหน้าต่าง",
        .loginError: "เปลี่ยนรายการเข้าสู่ระบบไม่ได้: %@",
        .loginNeedsBundle: "การเปิดเมื่อเข้าสู่ระบบใช้ได้เฉพาะเมื่อรันจากไฟล์ .app ที่บิลด์แล้ว",
        .showWindow: "เปิด Claude Instances", .quitApp: "ออกจาก Claude Instances", .hideApp: "ซ่อน Claude Instances",
        .about: "เกี่ยวกับ Claude Instances",
        .editMenu: "แก้ไข", .undo: "เลิกทำ", .redo: "ทำซ้ำ", .cut: "ตัด", .copy: "คัดลอก", .paste: "วาง",
        .selectAll: "เลือกทั้งหมด", .windowMenu: "หน้าต่าง", .minimize: "ย่อ", .close: "ปิด",
    ],
    .zh: [
        .profiles: "配置文件", .newProfile: "新建配置文件", .editProfile: "编辑配置文件",
        .name: "名称", .path: "路径", .choose: "选择…", .cancel: "取消", .save: "保存",
        .delete: "删除", .play: "启动", .bringToFront: "前置", .quitInstance: "退出实例",
        .showInFinder: "在访达中显示", .edit: "编辑…", .running: "运行中", .defaultBadge: "默认",
        .settings: "设置", .language: "语言", .general: "通用",
        .hideDock: "从程序坞隐藏", .hideMenuBar: "从菜单栏隐藏", .launchAtLogin: "登录时启动",
        .startHidden: "启动时隐藏", .claudeApp: "Claude 应用", .reset: "重置",
        .deleteTitle: "删除配置文件“%@”？",
        .deleteMessage: "仅从列表中移除，磁盘上的文件夹会保留。",
        .deleteTypeName: "输入“%@”以确认",
        .continueAction: "继续", .deleteFinalTitle: "确定删除“%@”？",
        .deleteFinalMessage: "配置文件将从列表中移除，此操作无法撤销。",
        .emptyList: "还没有配置文件。按 + 新建。",
        .pathHint: "每个文件夹是一个独立的登录会话，首次启动时创建。",
        .defaultNote: "使用原始数据正常打开 Claude。",
        .chooseApp: "选择 Claude.app", .chooseFolder: "选择配置文件夹",
        .statusLaunching: "正在启动“%@”…", .statusLaunched: "“%@”正在运行。首次启动需要登录。",
        .statusExited: "“%@”已退出。",
        .errAppNotFound: "在 %@ 找不到 Claude 应用。", .errInvalidPath: "配置文件路径无效。",
        .errOriginal: "这是 Claude 的原始数据文件夹——请选择其他路径。",
        .errCreateDir: "无法创建配置文件夹：%@", .errLaunch: "启动失败：%@",
        .errFolderMissing: "文件夹尚不存在——启动时会自动创建。",
        .errNameEmpty: "请输入名称。", .errNameDuplicate: "已存在同名配置文件。",
        .errPathDuplicate: "该路径已被其他配置文件使用。",
        .warnBothHidden: "程序坞和菜单栏图标都已隐藏。请从访达或启动台再次打开应用以显示窗口。",
        .loginError: "无法更改登录项：%@",
        .loginNeedsBundle: "登录时启动仅在运行构建好的 .app 时有效。",
        .showWindow: "打开 Claude Instances", .quitApp: "退出 Claude Instances", .hideApp: "隐藏 Claude Instances",
        .about: "关于 Claude Instances",
        .editMenu: "编辑", .undo: "撤销", .redo: "重做", .cut: "剪切", .copy: "拷贝", .paste: "粘贴",
        .selectAll: "全选", .windowMenu: "窗口", .minimize: "最小化", .close: "关闭",
    ],
    .vi: [
        .profiles: "Profile", .newProfile: "Profile mới", .editProfile: "Sửa profile",
        .name: "Tên", .path: "Đường dẫn", .choose: "Chọn…", .cancel: "Huỷ", .save: "Lưu",
        .delete: "Xoá", .play: "Chạy", .bringToFront: "Đưa lên trước", .quitInstance: "Thoát instance",
        .showInFinder: "Mở trong Finder", .edit: "Sửa…", .running: "Đang chạy", .defaultBadge: "Mặc định",
        .settings: "Cài đặt", .language: "Ngôn ngữ", .general: "Chung",
        .hideDock: "Ẩn khỏi Dock", .hideMenuBar: "Ẩn khỏi thanh menu", .launchAtLogin: "Mở khi đăng nhập",
        .startHidden: "Khởi động ở chế độ ẩn", .claudeApp: "Ứng dụng Claude", .reset: "Mặc định",
        .deleteTitle: "Xoá profile “%@”?",
        .deleteMessage: "Profile sẽ bị xoá khỏi danh sách. Thư mục trên đĩa vẫn được giữ nguyên.",
        .deleteTypeName: "Nhập “%@” để xác nhận",
        .continueAction: "Tiếp tục", .deleteFinalTitle: "Xoá “%@”?",
        .deleteFinalMessage: "Profile sẽ bị xoá khỏi danh sách và không thể hoàn tác.",
        .emptyList: "Chưa có profile nào. Bấm + để tạo.",
        .pathHint: "Mỗi thư mục là một phiên đăng nhập riêng. Thư mục được tạo khi chạy lần đầu.",
        .defaultNote: "Mở Claude bình thường với dữ liệu gốc.",
        .chooseApp: "Chọn Claude.app", .chooseFolder: "Chọn thư mục profile",
        .statusLaunching: "Đang khởi động “%@”…", .statusLaunched: "“%@” đang chạy. Lần đầu sẽ cần đăng nhập.",
        .statusExited: "“%@” đã thoát.",
        .errAppNotFound: "Không tìm thấy ứng dụng Claude tại %@.", .errInvalidPath: "Đường dẫn profile không hợp lệ.",
        .errOriginal: "Đây là thư mục dữ liệu gốc của Claude — hãy chọn đường dẫn khác.",
        .errCreateDir: "Không tạo được thư mục profile: %@", .errLaunch: "Lỗi khi chạy: %@",
        .errFolderMissing: "Thư mục chưa tồn tại — sẽ được tạo khi bấm Chạy.",
        .errNameEmpty: "Cần nhập tên.", .errNameDuplicate: "Đã có profile trùng tên.",
        .errPathDuplicate: "Đường dẫn này đã được profile khác dùng.",
        .warnBothHidden: "Icon trên Dock và thanh menu đều bị ẩn. Mở lại app từ Finder hoặc Launchpad để hiện cửa sổ.",
        .loginError: "Không đổi được mục đăng nhập: %@",
        .loginNeedsBundle: "Mở khi đăng nhập chỉ hoạt động khi chạy từ file .app đã build.",
        .showWindow: "Mở Claude Instances", .quitApp: "Thoát Claude Instances", .hideApp: "Ẩn Claude Instances",
        .about: "Giới thiệu Claude Instances",
        .editMenu: "Sửa", .undo: "Hoàn tác", .redo: "Làm lại", .cut: "Cắt", .copy: "Sao chép", .paste: "Dán",
        .selectAll: "Chọn tất cả", .windowMenu: "Cửa sổ", .minimize: "Thu nhỏ", .close: "Đóng",
    ],
]
