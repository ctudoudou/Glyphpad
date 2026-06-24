import Foundation
import GlyphpadCore

enum LauncherItem: Identifiable, Equatable {
    case folder(FolderRecord)
    case app(InstalledApplication)

    var id: String {
        switch self {
        case .folder(let folder):
            "folder-\(folder.id.uuidString)"
        case .app(let app):
            "app-\(app.id)"
        }
    }

    var layoutKind: LauncherLayoutKind {
        switch self {
        case .folder:
            return .folder
        case .app:
            return .app
        }
    }

    var targetIdentifier: String {
        switch self {
        case .folder(let folder):
            return folder.id.uuidString
        case .app(let app):
            return app.id
        }
    }

    var isApp: Bool {
        if case .app = self {
            return true
        }
        return false
    }
}

extension CGRect {
    var area: CGFloat {
        width * height
    }
}
