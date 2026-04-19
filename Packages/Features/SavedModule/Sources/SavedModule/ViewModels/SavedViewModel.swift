import Foundation
import Observation
import SwiftData
import StorageModule

@Observable
public final class SavedViewModel {
    public private(set) var articles: [SavedArticle] = []
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadArticles()
    }

    public func loadArticles() {
        let descriptor = FetchDescriptor<SavedArticle>(sortBy: [SortDescriptor(\.savedAt, order: .reverse)])
        articles = (try? modelContext.fetch(descriptor)) ?? []
    }

    public func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(articles[index])
        }
        try? modelContext.save()
        loadArticles()
    }
}
