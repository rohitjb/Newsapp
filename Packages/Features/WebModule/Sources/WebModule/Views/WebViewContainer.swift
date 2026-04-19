import SwiftUI
import SwiftData
import WebKit
import StorageModule

public struct WebViewContainer: View {
    let url: URL
    let articleId: String
    let articleTitle: String
    let articleImageURL: String?
    let sourceName: String

    @State private var isLoading = true
    @State private var progress: Double = 0
    @State private var isBookmarked: Bool = false

    private let modelContext: ModelContext

    public init(
        url: URL,
        articleId: String,
        articleTitle: String,
        articleImageURL: String?,
        sourceName: String,
        modelContext: ModelContext
    ) {
        self.url = url
        self.articleId = articleId
        self.articleTitle = articleTitle
        self.articleImageURL = articleImageURL
        self.sourceName = sourceName
        self.modelContext = modelContext
    }

    public var body: some View {
        ZStack(alignment: .top) {
            WebViewRepresentable(url: url, isLoading: $isLoading, progress: $progress)
                .ignoresSafeArea()
            if isLoading {
                ProgressView(value: progress)
                    .tint(.blue)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    toggleBookmark()
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                }
            }
        }
        .onAppear { checkBookmarkStatus() }
    }

    private func checkBookmarkStatus() {
        let descriptor = FetchDescriptor<SavedArticle>(
            predicate: #Predicate { $0.id == articleId }
        )
        isBookmarked = (try? modelContext.fetch(descriptor).isEmpty == false) ?? false
    }

    private func toggleBookmark() {
        if isBookmarked {
            let descriptor = FetchDescriptor<SavedArticle>(
                predicate: #Predicate { $0.id == articleId }
            )
            if let saved = try? modelContext.fetch(descriptor).first {
                modelContext.delete(saved)
                try? modelContext.save()
            }
        } else {
            let saved = SavedArticle(
                id: articleId,
                title: articleTitle,
                url: url.absoluteString,
                imageURL: articleImageURL,
                sourceName: sourceName,
                savedAt: Date()
            )
            modelContext.insert(saved)
            try? modelContext.save()
        }
        isBookmarked.toggle()
    }
}

// MARK: - UIViewRepresentable bridge

struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var progress: Double

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        let coordinator = context.coordinator
        coordinator.observation = webView.observe(\.estimatedProgress, options: .new) { webView, _ in
            coordinator.progress = webView.estimatedProgress
        }
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading, progress: $progress)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        @Binding var progress: Double
        var observation: NSKeyValueObservation?

        init(isLoading: Binding<Bool>, progress: Binding<Double>) {
            _isLoading = isLoading
            _progress = progress
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            isLoading = true
        }
    }
}
