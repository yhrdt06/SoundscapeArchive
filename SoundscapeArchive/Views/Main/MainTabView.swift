import SwiftUI

/// Main tab navigation view
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Recording
            RecordingView()
                .tabItem {
                    Label("録音", systemImage: "mic.fill")
                }
                .tag(0)

            // Tab 2: Library
            LibraryView()
                .tabItem {
                    Label("ライブラリ", systemImage: "rectangle.stack.fill")
                }
                .tag(1)

            // Tab 3: Insights
            InsightsView()
                .tabItem {
                    Label("分析", systemImage: "chart.xyaxis.line")
                }
                .tag(2)

            // Tab 4: Settings
            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
    }
}

// MARK: - Placeholder Views (to be implemented in later phases)

struct InsightsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("分析画面")
                    .font(.title)
                Text("Phase 4で実装予定")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("分析")
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.modelContext) private var modelContext
    @State private var syncManager = SyncManager.shared
    @State private var isSyncing = false
    @State private var showingSyncError = false
    @State private var syncError: Error?

    var body: some View {
        NavigationStack {
            List {
                // Account section
                Section("アカウント") {
                    if let email = authManager.userEmail {
                        HStack {
                            Text("メールアドレス")
                            Spacer()
                            Text(email)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let name = authManager.displayName {
                        HStack {
                            Text("表示名")
                            Spacer()
                            Text(name)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Sync section
                Section("同期") {
                    // Sync status
                    HStack {
                        Text("同期状態")
                        Spacer()
                        if isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if syncManager.pendingCount > 0 {
                            Text("\(syncManager.pendingCount)件の未同期")
                                .foregroundStyle(.orange)
                        } else {
                            Text("同期済み")
                                .foregroundStyle(.green)
                        }
                    }

                    // Last sync date
                    if let lastSync = syncManager.lastSyncDate {
                        HStack {
                            Text("最終同期")
                            Spacer()
                            Text(formatDate(lastSync))
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Sync button
                    Button {
                        performSync()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("今すぐ同期")
                        }
                    }
                    .disabled(isSyncing)
                }

                // App info
                Section("アプリ情報") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }

                // Sign out
                Section {
                    Button(role: .destructive) {
                        try? authManager.signOut()
                    } label: {
                        HStack {
                            Spacer()
                            Text("ログアウト")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("設定")
            .onAppear {
                syncManager.updatePendingCount(context: modelContext)
            }
            .alert("同期エラー", isPresented: $showingSyncError) {
                Button("OK") {}
            } message: {
                if let error = syncError {
                    Text(error.localizedDescription)
                }
            }
        }
    }

    private func performSync() {
        isSyncing = true

        Task {
            do {
                try await syncManager.sync(context: modelContext)
            } catch {
                syncError = error
                showingSyncError = true
            }
            isSyncing = false
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager())
}
