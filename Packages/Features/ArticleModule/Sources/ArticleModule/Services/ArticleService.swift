import Foundation
import NetworkModule

public protocol ArticleServiceProtocol: Sendable {
    func fetchArticles(sourceIds: [String]) async throws -> [Article]
}

public struct ArticleService: ArticleServiceProtocol {
    private let client: any NewsAPIClientProtocol

    public init(client: any NewsAPIClientProtocol = NewsAPIClient.makeLive()) {
        self.client = client
    }

    public func fetchArticles(sourceIds: [String]) async throws -> [Article] {
        let dtos = try await client.fetchArticles(sourceIds: sourceIds)
        return dtos.map { dto in
            Article(
                id: dto.url,
                title: dto.title,
                url: dto.url,
                imageURL: dto.urlToImage,
                sourceName: dto.source.name,
                publishedAt: dto.publishedAt,
                description: dto.description
            )
        }
    }
}
