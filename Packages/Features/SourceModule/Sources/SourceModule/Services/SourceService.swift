import Foundation
import NetworkModule

public protocol SourceServiceProtocol: Sendable {
    func fetchSources() async throws -> [Source]
}

public struct SourceService: SourceServiceProtocol {
    private let client: any NewsAPIClientProtocol

    public init(client: any NewsAPIClientProtocol = NewsAPIClient.makeLive()) {
        self.client = client
    }

    public func fetchSources() async throws -> [Source] {
        let dtos = try await client.fetchSources()
        return dtos.map {
            Source(id: $0.id, name: $0.name, category: $0.category, country: $0.country, language: $0.language)
        }
    }
}
