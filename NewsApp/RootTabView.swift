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

    @State private var articlesPath = NavigationPath()
    @State private var savedPath = NavigationPath()

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
            NavigationStack(path: $articlesPath) {
                ArticleListView(sourceIds: selectedSourceIds) { article in
                    articlesPath.append(article)
                }
                .navigationDestination(for: Article.self) { article in
                    if let url = URL(string: article.url) {
                        WebViewContainer(
                            url: url,
                            articleId: article.id,
                            articleTitle: article.title,
                            articleImageURL: article.imageURL,
                            sourceName: article.sourceName,
                            modelContext: modelContext
                        )
                    }
                }
            }
            .tabItem {
                Label("Articles", systemImage: "newspaper")
            }

            // Tab 2: Saved (feature-flagged)
            if featureFlags.saveEnabled {
                NavigationStack(path: $savedPath) {
                    SavedListView(modelContext: modelContext) { saved in
                        savedPath.append(saved)
                    }
                    .navigationDestination(for: SavedArticle.self) { saved in
                        if let url = URL(string: saved.url) {
                            WebViewContainer(
                                url: url,
                                articleId: saved.id,
                                articleTitle: saved.title,
                                articleImageURL: saved.imageURL,
                                sourceName: saved.sourceName,
                                modelContext: modelContext
                            )
                        }
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
