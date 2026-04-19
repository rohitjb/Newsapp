import Foundation
import Observation

public enum ArticleState {
    case idle
    case loading
    case loaded([Article])
    case error(String)
}

@Observable
public final class ArticleViewModel {
    public private(set) var state: ArticleState = .idle
    private let service: any ArticleServiceProtocol

    public init(service: any ArticleServiceProtocol = ArticleService()) {
        self.service = service
    }

    @MainActor
    public func loadArticles(sourceIds: [String]) async {
        guard !sourceIds.isEmpty else {
            state = .loaded([])
            return
        }
        state = .loading
        do {
            let articles = try await service.fetchArticles(sourceIds: sourceIds)
            state = .loaded(articles)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
