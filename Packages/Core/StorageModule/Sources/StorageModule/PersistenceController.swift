import Foundation
import SwiftData

public struct PersistenceController {

    public static func makeContainer() throws -> ModelContainer {
        let schema = Schema([SavedArticle.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [config])
    }

    public static func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([SavedArticle.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
