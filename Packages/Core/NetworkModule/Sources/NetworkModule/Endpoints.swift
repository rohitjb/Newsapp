import Foundation

public enum NewsAPIEndpoint {
    case sources
    case topHeadlines(sourceIds: [String])

    func url(baseURL: URL, apiKey: String) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        switch self {
        case .sources:
            components.path = "/v2/sources"
            components.queryItems = [URLQueryItem(name: "apiKey", value: apiKey)]
        case .topHeadlines(let ids):
            components.path = "/v2/top-headlines"
            components.queryItems = [
                URLQueryItem(name: "sources", value: ids.joined(separator: ",")),
                URLQueryItem(name: "apiKey", value: apiKey)
            ]
        }
        return components.url!
    }
}
