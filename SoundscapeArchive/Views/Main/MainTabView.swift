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

struct RecordingView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("録音画面")
                    .font(.title)
                Text("Phase 2で実装予定")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("録音")
        }
    }
}

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("ライブラリ画面")
                    .font(.title)
                Text("Phase 3で実装予定")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("ライブラリ")
        }
    }
}

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
                    HStack {
                        Text("同期状態")
                        Spacer()
                        Text("Phase 5で実装予定")
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
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager())
}
