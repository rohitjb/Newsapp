import SwiftUI
import StorageModule

public struct ArticleListView: View {
    let sourceIds: [String]
    @State private var viewModel = ArticleViewModel()
    let onArticleTapped: (Article) -> Void

    public init(sourceIds: [String], onArticleTapped: @escaping (Article) -> Void) {
        self.sourceIds = sourceIds
        self.onArticleTapped = onArticleTapped
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Loading articles...")
            case .loaded(let articles) where articles.isEmpty:
                ContentUnavailableView(
                    "No Articles",
                    systemImage: "newspaper",
                    description: Text("Select sources on the Sources tab to see articles here.")
                )
            case .loaded(let articles):
                List(articles) { article in
                    Button {
                        onArticleTapped(article)
                    } label: {
                        ArticleRowView(article: article)
                    }
                    .foregroundStyle(.primary)
                }
            case .error(let message):
                ContentUnavailableView(
                    "Failed to load",
                    systemImage: "wifi.slash",
                    description: Text(message)
                )
            }
        }
        .navigationTitle("Articles")
        .task { await viewModel.loadArticles(sourceIds: sourceIds) }
        .refreshable { await viewModel.loadArticles(sourceIds: sourceIds) }
    }
}
