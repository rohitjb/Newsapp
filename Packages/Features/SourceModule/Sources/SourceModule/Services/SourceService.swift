import Foundation
import NetworkModule

public enum SourceServiceError: Error, LocalizedError {
    case missingAPIKey
    case networkError(String)
    case decodingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "NEWSAPI_KEY is empty. Check Secrets.xcconfig and the Xcode project configuration."
        case .networkError(let detail):
            return "Network error: \(detail)"
        case .decodingFailed(let detail):
            return "Decoding failed: \(detail)"
        }
    }
}

public protocol SourceServiceProtocol: Sendable {
    func fetchSources() async throws -> [Source]
}

public struct SourceService: SourceServiceProtocol {
    private let client: any NewsAPIClientProtocol

    public init(client: any NewsAPIClientProtocol = NewsAPIClient.makeLive()) {
        self.client = client
    }

    public func fetchSources() async throws -> [Source] {
        do {
            let dtos = try await client.fetchSources()
            return dtos.map {
                Source(id: $0.id, name: $0.name, category: $0.category, country: $0.country, language: $0.language)
            }
        } catch NewsAPIError.missingAPIKey {
            throw SourceServiceError.missingAPIKey
        } catch NewsAPIError.httpError(let statusCode) {
            throw SourceServiceError.networkError("HTTP \(statusCode) — check your API key and plan limits")
        } catch NewsAPIError.decodingError(let detail) {
            throw SourceServiceError.decodingFailed("Response shape mismatch: \(detail)")
        } catch {
            throw SourceServiceError.networkError(error.localizedDescription)
        }
    }
}
