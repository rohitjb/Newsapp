import SwiftUI

public struct SourceListView: View {
    @State private var viewModel = SourceViewModel()
    let onSourceSelected: (Source) -> Void

    public init(onSourceSelected: @escaping (Source) -> Void) {
        self.onSourceSelected = onSourceSelected
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Loading sources...")
            case .loaded(let sources):
                List(sources) { source in
                    Button {
                        onSourceSelected(source)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(source.name)
                                .font(.headline)
                            Text(source.category.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
            case .error(let message):
                ContentUnavailableView(
                    "Failed to load",
                    systemImage: "wifi.slash",
                    description: Text(message)
                )
            }
        }
        .navigationTitle("Sources")
        .task { await viewModel.loadSources() }
        .refreshable { await viewModel.loadSources() }
    }
}
