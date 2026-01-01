import Foundation

/// Synchronization status for local records
enum SyncStatus: String, Codable, CaseIterable {
    case synced = "synced"
    case pendingUpload = "pending_upload"
    case pendingDownload = "pending_download"
    case conflict = "conflict"
    case error = "error"

    var displayName: String {
        switch self {
        case .synced: return "同期済み"
        case .pendingUpload: return "アップロード待ち"
        case .pendingDownload: return "ダウンロード待ち"
        case .conflict: return "競合あり"
        case .error: return "エラー"
        }
    }

    var iconName: String {
        switch self {
        case .synced: return "checkmark.circle.fill"
        case .pendingUpload: return "arrow.up.circle"
        case .pendingDownload: return "arrow.down.circle"
        case .conflict: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
}

/// Supported audio file formats
enum FileFormat: String, Codable {
    case wav = "wav"
    case mp3 = "mp3"
}
