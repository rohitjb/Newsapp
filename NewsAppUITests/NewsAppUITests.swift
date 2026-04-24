import XCTest

final class NewsAppUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-baseURL", "http://localhost:3000",
            "-disablePinning"
        ]
        app.launch()
    }

    func testSourcesTabLoadsAndDisplaysSources() throws {
        let sourcesTab = app.tabBars.buttons["Sources"]
        XCTAssertTrue(sourcesTab.exists)
        sourcesTab.tap()

        let bbcCell = app.staticTexts["BBC News"]
        XCTAssertTrue(bbcCell.waitForExistence(timeout: 5))
    }

    func testTappingSourceAddsItToSelectedSources() throws {
        app.tabBars.buttons["Sources"].tap()
        let bbcCell = app.staticTexts["BBC News"]
        XCTAssertTrue(bbcCell.waitForExistence(timeout: 5))
        bbcCell.tap()

        app.tabBars.buttons["Articles"].tap()
        let articleCell = app.staticTexts["Test UI Headline"]
        XCTAssertTrue(articleCell.waitForExistence(timeout: 5))
    }

    func testArticlesTabLoadsArticles() throws {
        // Add a source first so articles load
        app.tabBars.buttons["Sources"].tap()
        let bbcCell = app.staticTexts["BBC News"]
        if bbcCell.waitForExistence(timeout: 5) {
            bbcCell.tap()
        }

        app.tabBars.buttons["Articles"].tap()
        let articleCell = app.staticTexts["Test UI Headline"]
        XCTAssertTrue(articleCell.waitForExistence(timeout: 5))
    }

    func testTappingArticleOpensWebView() throws {
        // Add a source and navigate to articles
        app.tabBars.buttons["Sources"].tap()
        let bbcCell = app.staticTexts["BBC News"]
        if bbcCell.waitForExistence(timeout: 5) {
            bbcCell.tap()
        }

        app.tabBars.buttons["Articles"].tap()
        let articleCell = app.staticTexts["Test UI Headline"]
        XCTAssertTrue(articleCell.waitForExistence(timeout: 5))
        articleCell.tap()

        let bookmarkButton = app.navigationBars.buttons["bookmark"]
        XCTAssertTrue(bookmarkButton.waitForExistence(timeout: 5))
    }
}
