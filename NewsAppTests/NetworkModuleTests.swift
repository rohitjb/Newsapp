import Testing
import Foundation
@testable import NetworkModule

final class MockURLSession: URLSessionProtocol {
    var stubbedData: Data = Data()
    var stubbedResponse: URLResponse = HTTPURLResponse(
        url: URL(string: "https://newsapi.org")!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
    )!
    var stubbedError: Error?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = stubbedError { throw error }
        return (stubbedData, stubbedResponse)
    }
}

@Suite("NewsAPIClient")
struct NewsAPIClientTests {

    @Test("fetchSources decodes valid JSON")
    func fetchSourcesDecodesValidJSON() async throws {
        let session = MockURLSession()
        let sourcesJSON = """
        {
            "status": "ok",
            "sources": [
                {
                    "id": "bbc-news", "name": "BBC News", "description": "BBC News",
                    "url": "https://bbc.com", "category": "general", "language": "en", "country": "gb"
                }
            ]
        }
        """
        session.stubbedData = Data(sourcesJSON.utf8)

        let client = NewsAPIClient(session: session, apiKey: "test-key", baseURL: URL(string: "https://newsapi.org")!)
        let sources = try await client.fetchSources()
        #expect(sources.count == 1)
        #expect(sources.first?.id == "bbc-news")
    }

    @Test("fetchArticles decodes valid JSON")
    func fetchArticlesDecodesValidJSON() async throws {
        let session = MockURLSession()
        let articlesJSON = """
        {
            "status": "ok",
            "totalResults": 1,
            "articles": [
                {
                    "source": {"id": "bbc-news", "name": "BBC News"},
                    "title": "Test Headline",
                    "url": "https://bbc.com/article",
                    "urlToImage": null,
                    "publishedAt": "2026-04-12T10:00:00Z",
                    "description": "A test article"
                }
            ]
        }
        """
        session.stubbedData = Data(articlesJSON.utf8)

        let client = NewsAPIClient(session: session, apiKey: "test-key", baseURL: URL(string: "https://newsapi.org")!)
        let articles = try await client.fetchArticles(sourceIds: ["bbc-news"])
        #expect(articles.count == 1)
        #expect(articles.first?.title == "Test Headline")
    }

    @Test("fetchSources throws on HTTP error")
    func fetchSourcesThrowsOnHTTPError() async throws {
        let session = MockURLSession()
        session.stubbedResponse = HTTPURLResponse(
            url: URL(string: "https://newsapi.org")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!
        session.stubbedData = Data()

        let client = NewsAPIClient(session: session, apiKey: "bad-key", baseURL: URL(string: "https://newsapi.org")!)
        await #expect(throws: NewsAPIError.self) {
            _ = try await client.fetchSources()
        }
    }
}
