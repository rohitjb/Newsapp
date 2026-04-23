import SwiftUI
import SwiftData
import FeatureFlagModule
import SourceModule
import ArticleModule
import SavedModule
import WebModule
import StorageModule

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var featureFlags = FeatureFlags()
    @AppStorage("selectedSourceIds") private var selectedSourceIdsRaw: String = ""

    private var selectedSourceIds: [String] {
        selectedSourceIdsRaw.isEmpty ? [] : selectedSourceIdsRaw.components(separatedBy: ",")
    }

    var body: some View {
        TabView {
            // Tab 0: Sources
            NavigationStack {
                SourceListView { source in
                    var current = selectedSourceIds
                    if !current.contains(source.id) {
                        current.append(source.id)
                        selectedSourceIdsRaw = current.joined(separator: ",")
                    }
                }
            }
            .tabItem {
                Label("Sources", systemImage: "antenna.radiowaves.left.and.right")
            }

            // Tab 1: Articles
            NavigationStack {
                ArticleListView(sourceIds: selectedSourceIds) { _ in
                    // Navigation handled via NavigationStack path
                }
            }
            .tabItem {
                Label("Articles", systemImage: "newspaper")
            }

            // Tab 2: Saved (feature-flagged)
            if featureFlags.saveEnabled {
                NavigationStack {
                    SavedListView(modelContext: modelContext) { _ in
                        // Navigation handled via NavigationStack path
                    }
                }
                .tabItem {
                    Label("Saved", systemImage: "bookmark")
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            featureFlags = FeatureFlags()
        }
    }
}
