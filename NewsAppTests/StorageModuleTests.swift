import Foundation
import Testing
import SwiftData
@testable import StorageModule

@Suite("StorageModule")
struct StorageModuleTests {

    @Test("Save and fetch article")
    func saveAndFetchArticle() async throws {
        let container = try PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)

        let article = SavedArticle(
            id: "abc-123",
            title: "Test Article",
            url: "https://example.com",
            imageURL: nil,
            sourceName: "Test Source",
            savedAt: Date()
        )
        context.insert(article)
        try context.save()

        let descriptor = FetchDescriptor<SavedArticle>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results.first?.id == "abc-123")
    }

    @Test("Delete article removes it from store")
    func deleteArticle() async throws {
        let container = try PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)

        let article = SavedArticle(
            id: "del-456",
            title: "Delete Me",
            url: "https://example.com/delete",
            imageURL: nil,
            sourceName: "Source",
            savedAt: Date()
        )
        context.insert(article)
        try context.save()

        context.delete(article)
        try context.save()

        let descriptor = FetchDescriptor<SavedArticle>()
        let results = try context.fetch(descriptor)
        #expect(results.isEmpty)
    }
}
