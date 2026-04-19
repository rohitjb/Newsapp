import Testing
import Foundation
@testable import SourceModule
import NetworkModule

final class MockSourceService: SourceServiceProtocol {
    var stubbedSources: [Source] = []
    var stubbedError: Error?

    func fetchSources() async throws -> [Source] {
        if let error = stubbedError { throw error }
        return stubbedSources
    }
}

@Suite("SourceViewModel")
struct SourceViewModelTests {

    @Test("loadSources sets state to loaded on success")
    func loadSourcesSetsLoadedState() async {
        let service = MockSourceService()
        let stub = Source(id: "bbc-news", name: "BBC News", category: "general", country: "gb", language: "en")
        service.stubbedSources = [stub]
        let viewModel = SourceViewModel(service: service)
        await viewModel.loadSources()
        if case .loaded(let sources) = viewModel.state {
            #expect(sources.count == 1)
            #expect(sources.first?.id == "bbc-news")
        } else {
            Issue.record("Expected .loaded state, got \(viewModel.state)")
        }
    }

    @Test("loadSources sets state to error on failure")
    func loadSourcesSetsErrorState() async {
        let service = MockSourceService()
        service.stubbedError = NSError(domain: "test", code: 0)
        let viewModel = SourceViewModel(service: service)
        await viewModel.loadSources()
        if case .error = viewModel.state {
            // pass
        } else {
            Issue.record("Expected .error state, got \(viewModel.state)")
        }
    }
}
