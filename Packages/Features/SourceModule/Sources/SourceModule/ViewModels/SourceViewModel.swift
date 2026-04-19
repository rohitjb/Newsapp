import Foundation
import Observation

public enum SourceState {
    case idle
    case loading
    case loaded([Source])
    case error(String)
}

@Observable
public final class SourceViewModel {
    public private(set) var state: SourceState = .idle
    private let service: any SourceServiceProtocol

    public init(service: any SourceServiceProtocol = SourceService()) {
        self.service = service
    }

    @MainActor
    public func loadSources() async {
        state = .loading
        do {
            let sources = try await service.fetchSources()
            state = .loaded(sources)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
