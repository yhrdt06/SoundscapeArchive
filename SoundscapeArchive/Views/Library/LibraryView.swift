import SwiftUI
import SwiftData

/// Library main view with recording list
struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: LibraryViewModel?
    @State private var showingDeleteConfirmation = false
    @State private var recordToDelete: SoundscapeRecord?
    @State private var isGridView = false

    var body: some View {
        NavigationStack {
            if let viewModel = viewModel {
                LibraryContentView(
                    viewModel: viewModel,
                    modelContext: modelContext,
                    showingDeleteConfirmation: $showingDeleteConfirmation,
                    recordToDelete: $recordToDelete,
                    isGridView: $isGridView
                )
            } else {
                ProgressView("読み込み中...")
                    .task {
                        await MainActor.run {
                            viewModel = LibraryViewModel()
                        }
                    }
            }
        }
    }
}

/// Inner content view that uses the ViewModel
@MainActor
private struct LibraryContentView: View {
    var viewModel: LibraryViewModel
    let modelContext: ModelContext
    @Binding var showingDeleteConfirmation: Bool
    @Binding var recordToDelete: SoundscapeRecord?
    @Binding var isGridView: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Stats header
            if !viewModel.records.isEmpty {
                statsHeader
            }

            // Content
            if viewModel.isLoading {
                ProgressView("読み込み中...")
                    .frame(maxHeight: .infinity)
            } else if viewModel.records.isEmpty {
                emptyState
            } else if viewModel.filteredRecords.isEmpty {
                noResultsState
            } else {
                recordsList
            }
        }
        .navigationTitle("ライブラリ")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                sortMenu
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isGridView.toggle()
                } label: {
                    Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                }
            }
        }
        .searchable(text: Binding(
            get: { viewModel.searchText },
            set: { viewModel.searchText = $0 }
        ), prompt: "タイトル、場所、タグで検索")
        .refreshable {
            await viewModel.loadRecords(context: modelContext)
        }
        .task {
            await viewModel.loadRecords(context: modelContext)
        }
        .alert("録音を削除", isPresented: $showingDeleteConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                if let record = recordToDelete {
                    Task {
                        try? await viewModel.deleteRecord(record, context: modelContext)
                    }
                }
            }
        } message: {
            Text("この録音を削除しますか？この操作は取り消せません。")
        }
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: 16) {
            StatBadge(
                icon: "waveform",
                value: "\(viewModel.totalRecordings)",
                label: "録音"
            )
            StatBadge(
                icon: "clock",
                value: viewModel.formattedTotalDuration,
                label: "合計"
            )
            if !viewModel.allTags.isEmpty {
                StatBadge(
                    icon: "tag",
                    value: "\(viewModel.allTags.count)",
                    label: "タグ"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            ForEach(LibraryViewModel.SortOrder.allCases, id: \.self) { order in
                Button {
                    viewModel.sortOrder = order
                } label: {
                    HStack {
                        Text(order.rawValue)
                        if viewModel.sortOrder == order {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label("並び替え", systemImage: viewModel.sortOrder.icon)
        }
    }

    // MARK: - Records List

    private var recordsList: some View {
        Group {
            // Tag filter chips
            if !viewModel.allTags.isEmpty {
                tagFilterView
            }

            // List or Grid
            if isGridView {
                gridView
            } else {
                listView
            }
        }
    }

    private var tagFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.allTags, id: \.self) { tag in
                    TagChip(
                        tag: tag,
                        isSelected: viewModel.selectedTags.contains(tag)
                    ) {
                        viewModel.toggleTag(tag)
                    }
                }

                if !viewModel.selectedTags.isEmpty {
                    Button("クリア") {
                        viewModel.selectedTags = []
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var listView: some View {
        List {
            ForEach(viewModel.filteredRecords, id: \.id) { record in
                NavigationLink(destination: RecordDetailView(record: record)) {
                    RecordRowView(record: record)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        recordToDelete = record
                        showingDeleteConfirmation = true
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.filteredRecords, id: \.id) { record in
                    NavigationLink(destination: RecordDetailView(record: record)) {
                        RecordGridItemView(record: record)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            recordToDelete = record
                            showingDeleteConfirmation = true
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Empty States

    private var emptyState: some View {
        ContentUnavailableView(
            "録音がありません",
            systemImage: "waveform",
            description: Text("録音タブで最初の録音を作成しましょう")
        )
    }

    private var noResultsState: some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "該当する録音がありません",
                systemImage: "magnifyingglass",
                description: Text("検索条件を変更してください")
            )
            Button("検索をクリア") {
                viewModel.clearSearch()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Stat Badge

private struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.headline)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tag Chip

private struct TagChip: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: LocalSoundscapeRecord.self, inMemory: true)
}
