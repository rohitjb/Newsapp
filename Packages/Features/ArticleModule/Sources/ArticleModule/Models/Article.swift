import Foundation

public struct Article: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let url: String
    public let imageURL: String?
    public let sourceName: String
    public let publishedAt: String
    public let description: String?

    public init(
        id: String,
        title: String,
        url: String,
        imageURL: String?,
        sourceName: String,
        publishedAt: String,
        description: String?
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.imageURL = imageURL
        self.sourceName = sourceName
        self.publishedAt = publishedAt
        self.description = description
    }
}
