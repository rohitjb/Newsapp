import SwiftUI
import SwiftData
import StorageModule

public struct SavedListView: View {
    @State private var viewModel: SavedViewModel
    let onArticleTapped: (SavedArticle) -> Void

    public init(modelContext: ModelContext, onArticleTapped: @escaping (SavedArticle) -> Void) {
        self._viewModel = State(initialValue: SavedViewModel(modelContext: modelContext))
        self.onArticleTapped = onArticleTapped
    }

    public var body: some View {
        Group {
            if viewModel.articles.isEmpty {
                ContentUnavailableView(
                    "No Saved Articles",
                    systemImage: "bookmark.slash",
                    description: Text("Bookmark articles while reading to save them here.")
                )
            } else {
                List {
                    ForEach(viewModel.articles) { article in
                        Button {
                            onArticleTapped(article)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(article.title)
                                    .font(.headline)
                                    .lineLimit(2)
                                Text(article.sourceName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                    .onDelete(perform: viewModel.delete)
                }
            }
        }
        .navigationTitle("Saved")
    }
}
