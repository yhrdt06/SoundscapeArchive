import Foundation
import SwiftData

/// ViewModel for library screen
@MainActor
@Observable
final class LibraryViewModel {
    // MARK: - State

    private(set) var records: [SoundscapeRecord] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    // MARK: - Search & Filter

    var searchText = ""
    var selectedTags: Set<String> = []
    var sortOrder: SortOrder = .dateDescending

    enum SortOrder: String, CaseIterable {
        case dateDescending = "新しい順"
        case dateAscending = "古い順"
        case titleAscending = "タイトル順"
        case durationDescending = "長い順"

        var icon: String {
            switch self {
            case .dateDescending: return "arrow.down"
            case .dateAscending: return "arrow.up"
            case .titleAscending: return "textformat.abc"
            case .durationDescending: return "clock"
            }
        }
    }

    // MARK: - Filtered Records

    var filteredRecords: [SoundscapeRecord] {
        var result = records

        // Text search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { record in
                record.metadata.title.lowercased().contains(query) ||
                (record.metadata.description?.lowercased().contains(query) ?? false) ||
                (record.metadata.locationName?.lowercased().contains(query) ?? false) ||
                record.metadata.tags.contains { $0.lowercased().contains(query) }
            }
        }

        // Tag filter
        if !selectedTags.isEmpty {
            result = result.filter { record in
                !selectedTags.isDisjoint(with: Set(record.metadata.tags))
            }
        }

        // Sort
        switch sortOrder {
        case .dateDescending:
            result.sort { $0.metadata.recordedAt > $1.metadata.recordedAt }
        case .dateAscending:
            result.sort { $0.metadata.recordedAt < $1.metadata.recordedAt }
        case .titleAscending:
            result.sort { $0.metadata.title.localizedCompare($1.metadata.title) == .orderedAscending }
        case .durationDescending:
            result.sort { $0.metadata.duration > $1.metadata.duration }
        }

        return result
    }

    // MARK: - All Tags

    var allTags: [String] {
        let tagSet = Set(records.flatMap { $0.metadata.tags })
        return Array(tagSet).sorted()
    }

    // MARK: - Statistics

    var totalRecordings: Int {
        records.count
    }

    var totalDuration: TimeInterval {
        records.reduce(0) { $0 + $1.metadata.duration }
    }

    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }

    // MARK: - Data Loading

    func loadRecords(context: ModelContext) async {
        #if NO_FIREBASE
        let userId = "preview-user"
        #else
        guard let userId = AuthManager.shared.userId else { return }
        #endif

        isLoading = true
        error = nil

        do {
            let dataStore = LocalDataStore(modelContext: context)
            records = try dataStore.fetchAllRecords(userId: userId)
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func deleteRecord(_ record: SoundscapeRecord, context: ModelContext) async throws {
        let dataStore = LocalDataStore(modelContext: context)

        // Delete audio file
        let audioPath = try dataStore.getAudioPath(recordId: record.id)
        try? FileManager.default.removeItem(atPath: audioPath)

        // Delete from database
        try dataStore.deleteRecord(id: record.id)

        // Remove from local array
        records.removeAll { $0.id == record.id }
    }

    // MARK: - Search

    func clearSearch() {
        searchText = ""
        selectedTags = []
    }

    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
}
