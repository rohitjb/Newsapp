import Testing
import Foundation
@testable import ArticleModule

final class MockArticleService: ArticleServiceProtocol {
    var stubbedArticles: [Article] = []
    var stubbedError: Error?

    func fetchArticles(sourceIds: [String]) async throws -> [Article] {
        if let error = stubbedError { throw error }
        return stubbedArticles
    }
}

@Suite("ArticleViewModel")
struct ArticleViewModelTests {

    @Test("loadArticles sets loaded state with articles")
    func loadArticlesSetsLoadedState() async {
        let service = MockArticleService()
        let stub = Article(
            id: "1", title: "Test", url: "https://example.com",
            imageURL: nil, sourceName: "BBC", publishedAt: "2026-04-12T10:00:00Z", description: nil
        )
        service.stubbedArticles = [stub]
        let viewModel = ArticleViewModel(service: service)
        await viewModel.loadArticles(sourceIds: ["bbc-news"])
        if case .loaded(let articles) = viewModel.state {
            #expect(articles.count == 1)
        } else {
            Issue.record("Expected .loaded state")
        }
    }

    @Test("loadArticles sets error state on failure")
    func loadArticlesSetsErrorState() async {
        let service = MockArticleService()
        service.stubbedError = NSError(domain: "test", code: 0)
        let viewModel = ArticleViewModel(service: service)
        await viewModel.loadArticles(sourceIds: ["bbc-news"])
        if case .error = viewModel.state {
            // pass
        } else {
            Issue.record("Expected .error state")
        }
    }
}
