import Foundation

public protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

public enum NewsAPIError: Error, Equatable {
    case httpError(statusCode: Int)
    case decodingError
    case invalidURL
}

struct SourcesResponse: Decodable {
    let sources: [SourceDTO]
}

struct ArticlesResponse: Decodable {
    let articles: [ArticleDTO]
}

public struct SourceDTO: Decodable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let url: String
    public let category: String
    public let language: String
    public let country: String
}

public struct ArticleDTO: Decodable, Sendable {
    public struct SourceRef: Decodable, Sendable {
        public let id: String?
        public let name: String
    }
    public let source: SourceRef
    public let title: String
    public let url: String
    public let urlToImage: String?
    public let publishedAt: String
    public let description: String?
}

public protocol NewsAPIClientProtocol: Sendable {
    func fetchSources() async throws -> [SourceDTO]
    func fetchArticles(sourceIds: [String]) async throws -> [ArticleDTO]
}

public struct NewsAPIClient: NewsAPIClientProtocol {
    private let session: any URLSessionProtocol
    private let apiKey: String
    private let baseURL: URL
    private let decoder: JSONDecoder

    public init(
        session: any URLSessionProtocol = URLSession.shared,
        apiKey: String = Bundle.main.infoDictionary?["NEWSAPI_KEY"] as? String ?? "",
        baseURL: URL = URL(string: "https://newsapi.org")!
    ) {
        self.session = session
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    public func fetchSources() async throws -> [SourceDTO] {
        let url = NewsAPIEndpoint.sources.url(baseURL: baseURL, apiKey: apiKey)
        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return try decode(SourcesResponse.self, from: data).sources
    }

    public func fetchArticles(sourceIds: [String]) async throws -> [ArticleDTO] {
        let url = NewsAPIEndpoint.topHeadlines(sourceIds: sourceIds).url(baseURL: baseURL, apiKey: apiKey)
        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return try decode(ArticlesResponse.self, from: data).articles
    }

    private func validate(response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw NewsAPIError.httpError(statusCode: http.statusCode)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw NewsAPIError.decodingError
        }
    }

    public static func makeLive() -> NewsAPIClient {
        let args = ProcessInfo.processInfo.arguments
        let disablePinning = args.contains("-disablePinning")

        let session: URLSession
        if disablePinning {
            session = URLSession.shared
        } else {
            let delegate = PinningDelegate()
            let config = URLSessionConfiguration.default
            session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        }

        let baseURL: URL
        if let idx = args.firstIndex(of: "-baseURL"),
           args.indices.contains(idx + 1),
           let overrideURL = URL(string: args[idx + 1]) {
            baseURL = overrideURL
        } else {
            baseURL = URL(string: "https://newsapi.org")!
        }

        let apiKey = Bundle.main.infoDictionary?["NEWSAPI_KEY"] as? String ?? ""
        return NewsAPIClient(session: session, apiKey: apiKey, baseURL: baseURL)
    }
}
