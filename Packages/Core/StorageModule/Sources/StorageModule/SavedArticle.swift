import Foundation
import SwiftData

@Model
public final class SavedArticle {
    public var id: String
    public var title: String
    public var url: String
    public var imageURL: String?
    public var sourceName: String
    public var savedAt: Date

    public init(
        id: String,
        title: String,
        url: String,
        imageURL: String?,
        sourceName: String,
        savedAt: Date
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.imageURL = imageURL
        self.sourceName = sourceName
        self.savedAt = savedAt
    }
}
