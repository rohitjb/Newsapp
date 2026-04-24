import XCTest
import SnapshotTesting
import SwiftUI
@testable import SourceModule
@testable import ArticleModule

final class ViewSnapshotTests: XCTestCase {

    func testSourceListView_loaded() {
        // isRecording = true  // Uncomment to regenerate reference images
        let view = NavigationStack {
            SourceListView { _ in }
        }
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        assertSnapshot(of: hostingController, as: .image(on: .iPhone13Pro))
    }

    func testArticleRowView_withImage() {
        let article = Article(
            id: "1",
            title: "Breaking: Swift 6 Released with Full Concurrency",
            url: "https://example.com",
            imageURL: nil,
            sourceName: "Swift Weekly",
            publishedAt: "2026-04-12T10:00:00Z",
            description: "A major update to Swift."
        )
        let view = ArticleRowView(article: article)
            .padding()
            .frame(width: 390)
        assertSnapshot(of: view, as: .image)
    }

    func testArticleRowView_withoutImage() {
        let article = Article(
            id: "2",
            title: "No image article title here",
            url: "https://example.com",
            imageURL: nil,
            sourceName: "Tech News",
            publishedAt: "2026-04-12T09:00:00Z",
            description: nil
        )
        let view = ArticleRowView(article: article)
            .padding()
            .frame(width: 390)
        assertSnapshot(of: view, as: .image)
    }
}
