import Foundation

public struct Source: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let category: String
    public let country: String
    public let language: String

    public init(id: String, name: String, category: String, country: String, language: String) {
        self.id = id
        self.name = name
        self.category = category
        self.country = country
        self.language = language
    }
}
