# NewsApp Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a production-quality iOS news reader app with modular SPM architecture, SwiftLint enforcement, GitHub Actions CI, SonarCloud analysis, certificate pinning, feature flags via a companion app, and a full test suite (unit, snapshot, UI).

**Architecture:** Layered SPM local packages — Core layer (NetworkModule, StorageModule, FeatureFlagModule) consumed by Features layer (SourceModule, ArticleModule, SavedModule, WebModule), assembled by the NewsApp host. Dependency direction is always downward; feature modules never import each other.

**Tech Stack:** SwiftUI + MVVM + `@Observable`, iOS 17+, SwiftData, Swift Testing, swift-snapshot-testing, Mockoon CLI, SwiftLint, GitHub Actions, SonarCloud, NewsAPI.org

---

## File Map

```
NewsApp/                                    ← Xcode project root
├── NewsApp/                                ← Host app target
│   ├── NewsAppApp.swift                    ← MODIFY: inject dependencies
│   ├── RootTabView.swift                   ← CREATE: tab assembly + feature flag gate
│   └── Resources/
│       └── Secrets.xcconfig               ← CREATE (gitignored): NEWSAPI_KEY=xxx
├── NewsCompanion/                          ← CREATE: companion app target in Xcode
│   └── CompanionApp.swift                 ← CREATE: toggle UI for feature flags
├── Packages/
│   ├── Core/
│   │   ├── NetworkModule/
│   │   │   ├── Package.swift              ← CREATE
│   │   │   └── Sources/NetworkModule/
│   │   │       ├── NewsAPIClient.swift    ← CREATE: async/await client + protocol
│   │   │       ├── PinningDelegate.swift  ← CREATE: URLSessionDelegate + SHA-256 check
│   │   │       ├── PinningConfig.swift    ← CREATE: pinned hash array
│   │   │       └── Endpoints.swift        ← CREATE: URL builder
│   │   ├── StorageModule/
│   │   │   ├── Package.swift              ← CREATE
│   │   │   └── Sources/StorageModule/
│   │   │       ├── PersistenceController.swift ← CREATE: ModelContainer factory
│   │   │       └── SavedArticle.swift     ← CREATE: @Model
│   │   └── FeatureFlagModule/
│   │       ├── Package.swift              ← CREATE
│   │       └── Sources/FeatureFlagModule/
│   │           └── FeatureFlags.swift     ← CREATE: App Group UserDefaults wrapper
│   └── Features/
│       ├── SourceModule/
│       │   ├── Package.swift              ← CREATE
│       │   └── Sources/SourceModule/
│       │       ├── Views/SourceListView.swift      ← CREATE
│       │       ├── ViewModels/SourceViewModel.swift ← CREATE
│       │       ├── Services/SourceService.swift    ← CREATE: protocol + live impl
│       │       └── Models/Source.swift             ← CREATE: Codable struct
│       ├── ArticleModule/
│       │   ├── Package.swift              ← CREATE
│       │   └── Sources/ArticleModule/
│       │       ├── Views/ArticleListView.swift      ← CREATE
│       │       ├── Views/ArticleRowView.swift       ← CREATE
│       │       ├── ViewModels/ArticleViewModel.swift ← CREATE
│       │       ├── Services/ArticleService.swift    ← CREATE: protocol + live impl
│       │       └── Models/Article.swift             ← CREATE: Codable struct
│       ├── SavedModule/
│       │   ├── Package.swift              ← CREATE
│       │   └── Sources/SavedModule/
│       │       ├── Views/SavedListView.swift        ← CREATE
│       │       └── ViewModels/SavedViewModel.swift  ← CREATE
│       └── WebModule/
│           ├── Package.swift              ← CREATE
│           └── Sources/WebModule/
│               └── Views/WebViewContainer.swift     ← CREATE: WKWebView + bookmark btn
├── MockData/
│   ├── mockoon-config.json               ← CREATE: Mockoon server config
│   ├── sources.json                      ← CREATE: mock /sources response
│   ├── articles.json                     ← CREATE: mock /top-headlines response
│   ├── empty-articles.json               ← CREATE: empty articles response
│   └── error.json                        ← CREATE: error response
├── scripts/
│   └── install-hooks.sh                  ← CREATE: copies pre-commit hook
├── .github/
│   └── workflows/
│       └── ci.yml                        ← CREATE: lint → test → sonar
├── .swiftlint.yml                        ← CREATE
├── .gitignore                            ← MODIFY: add Secrets.xcconfig, .superpowers/
├── sonar-project.properties             ← CREATE
├── NewsAppTests/
│   ├── NetworkModuleTests.swift          ← CREATE
│   ├── StorageModuleTests.swift          ← CREATE
│   ├── FeatureFlagModuleTests.swift      ← CREATE
│   ├── SourceViewModelTests.swift        ← CREATE
│   └── ArticleViewModelTests.swift       ← CREATE
├── NewsAppSnapshotTests/
│   └── ViewSnapshotTests.swift           ← CREATE
└── NewsAppUITests/
    └── NewsAppUITests.swift              ← MODIFY: full UI test suite
```

---

## Phase 1 — Project Foundation

### Task 1: SPM Local Package Scaffold

**Files:**
- Create: `Packages/Core/NetworkModule/Package.swift`
- Create: `Packages/Core/StorageModule/Package.swift`
- Create: `Packages/Core/FeatureFlagModule/Package.swift`
- Create: `Packages/Features/SourceModule/Package.swift`
- Create: `Packages/Features/ArticleModule/Package.swift`
- Create: `Packages/Features/SavedModule/Package.swift`
- Create: `Packages/Features/WebModule/Package.swift`

- [ ] **Step 1: Create the Packages directory structure**

```bash
mkdir -p Packages/Core/NetworkModule/Sources/NetworkModule
mkdir -p Packages/Core/StorageModule/Sources/StorageModule
mkdir -p Packages/Core/FeatureFlagModule/Sources/FeatureFlagModule
mkdir -p Packages/Features/SourceModule/Sources/SourceModule/{Views,ViewModels,Services,Models}
mkdir -p Packages/Features/ArticleModule/Sources/ArticleModule/{Views,ViewModels,Services,Models}
mkdir -p Packages/Features/SavedModule/Sources/SavedModule/{Views,ViewModels}
mkdir -p Packages/Features/WebModule/Sources/WebModule/Views
```

- [ ] **Step 2: Create NetworkModule Package.swift**

```swift
// Packages/Core/NetworkModule/Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NetworkModule",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "NetworkModule", targets: ["NetworkModule"])
    ],
    targets: [
        .target(
            name: "NetworkModule",
            path: "Sources/NetworkModule"
        )
    ]
)
```

- [ ] **Step 3: Create StorageModule Package.swift**

```swift
// Packages/Core/StorageModule/Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StorageModule",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "StorageModule", targets: ["StorageModule"])
    ],
    targets: [
        .target(
            name: "StorageModule",
            path: "Sources/StorageModule"
        )
    ]
)
```

- [ ] **Step 4: Create FeatureFlagModule Package.swift**

```swift
// Packages/Core/FeatureFlagModule/Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureFlagModule",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "FeatureFlagModule", targets: ["FeatureFlagModule"])
    ],
    targets: [
        .target(
            name: "FeatureFlagModule",
            path: "Sources/FeatureFlagModule"
        )
    ]
)
```

- [ ] **Step 5: Create SourceModule Package.swift**

```swift
// Packages/Features/SourceModule/Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SourceModule",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SourceModule", targets: ["SourceModule"])
    ],
    dependencies: [
        .package(path: "../../Core/NetworkModule")
    ],
    targets: [
        .target(
            name: "SourceModule",
            dependencies: ["NetworkModule"],
            path: "Sources/SourceModule"
        )
    ]
)
```

- [ ] **Step 6: Create ArticleModule Package.swift**

```swift
// Packages/Features/ArticleModule/Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ArticleModule",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ArticleModule", targets: ["ArticleModule"])
    ],
    dependencies: [
        .package(path: "../../Core/NetworkModule"),
        .package(path: "../../Core/StorageModule")
    ],
    targets: [
        .target(
            name: "ArticleModule",
            dependencies: ["NetworkModule", "StorageModule"],
            path: "Sources/ArticleModule"
        )
    ]
)
```

- [ ] **Step 7: Create SavedModule Package.swift**

```swift
// Packages/Features/SavedModule/Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SavedModule",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SavedModule", targets: ["SavedModule"])
    ],
    dependencies: [
        .package(path: "../../Core/StorageModule")
    ],
    targets: [
        .target(
            name: "SavedModule",
            dependencies: ["StorageModule"],
            path: "Sources/SavedModule"
        )
    ]
)
```

- [ ] **Step 8: Create WebModule Package.swift**

```swift
// Packages/Features/WebModule/Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WebModule",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "WebModule", targets: ["WebModule"])
    ],
    dependencies: [
        .package(path: "../../Core/StorageModule")
    ],
    targets: [
        .target(
            name: "WebModule",
            dependencies: ["StorageModule"],
            path: "Sources/WebModule"
        )
    ]
)
```

- [ ] **Step 9: Add all packages to Xcode project**

In Xcode: File → Add Package Dependencies → Add Local → select each Package directory. Add all 7 packages. Verify they appear in the project navigator under "Packages".

- [ ] **Step 10: Commit**

```bash
git add Packages/
git commit -m "feat: scaffold SPM local package structure for all modules"
```

---

### Task 2: SwiftLint Setup

**Files:**
- Create: `.swiftlint.yml`
- Modify: `NewsApp.xcodeproj` (add build phase — done via Xcode UI)

- [ ] **Step 1: Add SwiftLint as a package dependency in the host app**

In Xcode → project → Package Dependencies → add:
`https://github.com/realm/SwiftLint` version `0.57.0`

- [ ] **Step 2: Create .swiftlint.yml**

```yaml
# .swiftlint.yml
included:
  - NewsApp
  - NewsCompanion
  - Packages

excluded:
  - .build
  - DerivedData
  - NewsApp.xcodeproj

disabled_rules:
  - trailing_whitespace

opt_in_rules:
  - empty_count
  - explicit_init
  - closure_spacing
  - overridden_super_call
  - redundant_nil_coalescing
  - unused_import

line_length:
  warning: 120
  error: 150

type_body_length:
  warning: 300
  error: 400

file_length:
  warning: 400
  error: 600

function_body_length:
  warning: 40
  error: 60

cyclomatic_complexity:
  warning: 10
  error: 15
```

- [ ] **Step 3: Add SwiftLint Xcode build phase**

In Xcode → NewsApp target → Build Phases → + New Run Script Phase. Drag it above "Compile Sources". Paste:

```bash
if which swiftlint > /dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed"
fi
```

Uncheck "Based on dependency analysis".

- [ ] **Step 4: Verify lint runs on build**

Build the project (Cmd+B). Expect: zero warnings or errors from SwiftLint on the default template files.

- [ ] **Step 5: Commit**

```bash
git add .swiftlint.yml
git commit -m "feat: add SwiftLint configuration and Xcode build phase"
```

---

### Task 3: Git Pre-commit Hook

**Files:**
- Create: `scripts/install-hooks.sh`
- Create: `scripts/pre-commit` (the hook script)

- [ ] **Step 1: Create the pre-commit hook script**

```bash
#!/bin/sh
# scripts/pre-commit
# Runs SwiftLint on staged Swift files before every commit.

STAGED_SWIFT=$(git diff --cached --name-only --diff-filter=ACM | grep '\.swift$')

if [ -z "$STAGED_SWIFT" ]; then
  exit 0
fi

if ! which swiftlint > /dev/null; then
  echo "⚠️  SwiftLint not found. Install it or run: brew install swiftlint"
  exit 1
fi

echo "Running SwiftLint on staged Swift files..."
swiftlint lint --strict $STAGED_SWIFT

if [ $? -ne 0 ]; then
  echo "❌ SwiftLint violations found. Fix them before committing."
  exit 1
fi

echo "✅ SwiftLint passed."
exit 0
```

- [ ] **Step 2: Create the install-hooks.sh script**

```bash
#!/bin/sh
# scripts/install-hooks.sh
# Run this once after cloning: sh scripts/install-hooks.sh

HOOKS_DIR=".git/hooks"
SCRIPT_DIR="scripts"

cp "$SCRIPT_DIR/pre-commit" "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-commit"

echo "✅ Git hooks installed. Pre-commit SwiftLint check is now active."
```

- [ ] **Step 3: Make both scripts executable and install the hook**

```bash
chmod +x scripts/pre-commit scripts/install-hooks.sh
sh scripts/install-hooks.sh
```

Expected output: `✅ Git hooks installed. Pre-commit SwiftLint check is now active.`

- [ ] **Step 4: Test the hook blocks a bad commit**

Temporarily add `let x = 1` (unused variable) to `ContentView.swift`, stage it, and try to commit. Expect the commit to be blocked with a SwiftLint error. Revert the test change.

- [ ] **Step 5: Commit**

```bash
git add scripts/
git commit -m "feat: add SwiftLint pre-commit git hook"
```

---

### Task 4: Secrets & .gitignore Setup

**Files:**
- Create: `Secrets.xcconfig`
- Modify: `.gitignore`

- [ ] **Step 1: Create Secrets.xcconfig (gitignored)**

```
// Secrets.xcconfig
// This file is NOT committed to git. Each developer creates it locally.
// In CI, the GitHub Actions workflow writes this file from a repository secret.
NEWSAPI_KEY = your_key_here
```

- [ ] **Step 2: Reference Secrets.xcconfig in the Xcode project**

In Xcode → project → Info tab → Configurations: for both Debug and Release, set the configuration file for the NewsApp target to `Secrets.xcconfig`.

- [ ] **Step 3: Add NEWSAPI_KEY to Info.plist**

In `NewsApp/Info.plist`, add:
```xml
<key>NEWSAPI_KEY</key>
<string>$(NEWSAPI_KEY)</string>
```

- [ ] **Step 4: Update .gitignore**

```gitignore
# Xcode
.DS_Store
DerivedData/
*.xcuserstate
xcuserdata/

# SPM
.build/
.swiftpm/

# Secrets — never commit
Secrets.xcconfig

# Visual companion
.superpowers/

# Mockoon
MockData/*.db
```

- [ ] **Step 5: Commit**

```bash
git add .gitignore
git commit -m "feat: add secrets xcconfig pattern and update gitignore"
```

---

## Phase 2 — Core Modules

### Task 5: FeatureFlagModule

**Files:**
- Create: `Packages/Core/FeatureFlagModule/Sources/FeatureFlagModule/FeatureFlags.swift`
- Test: `NewsAppTests/FeatureFlagModuleTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
// NewsAppTests/FeatureFlagModuleTests.swift
import Testing
import Foundation
@testable import FeatureFlagModule

@Suite("FeatureFlags")
struct FeatureFlagTests {

    @Test("saveEnabled defaults to false")
    func saveEnabledDefaultsFalse() {
        let suiteName = "test.featureflags.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let flags = FeatureFlags(defaults: defaults)
        #expect(flags.saveEnabled == false)
    }

    @Test("saveEnabled persists written value")
    func saveEnabledPersists() {
        let suiteName = "test.featureflags.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        var flags = FeatureFlags(defaults: defaults)
        flags.saveEnabled = true
        let flags2 = FeatureFlags(defaults: defaults)
        #expect(flags2.saveEnabled == true)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:NewsAppTests/FeatureFlagTests 2>&1 | tail -20
```

Expected: build error — `FeatureFlags` not defined.

- [ ] **Step 3: Implement FeatureFlags**

```swift
// Packages/Core/FeatureFlagModule/Sources/FeatureFlagModule/FeatureFlags.swift
import Foundation

public struct FeatureFlags {
    private let defaults: UserDefaults

    public static let appGroupID = "group.com.newsapp.flags"

    /// Production initialiser — uses the shared App Group container.
    public init() {
        self.defaults = UserDefaults(suiteName: FeatureFlags.appGroupID) ?? .standard
    }

    /// Testable initialiser — inject any UserDefaults instance.
    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public var saveEnabled: Bool {
        get { defaults.bool(forKey: "saveEnabled") }
        set { defaults.set(newValue, forKey: "saveEnabled") }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
xcodebuild test -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:NewsAppTests/FeatureFlagTests 2>&1 | tail -20
```

Expected: `Test Suite 'FeatureFlagTests' passed`

- [ ] **Step 5: Commit**

```bash
git add Packages/Core/FeatureFlagModule/ NewsAppTests/FeatureFlagModuleTests.swift
git commit -m "feat: implement FeatureFlagModule with App Group UserDefaults"
```

---

### Task 6: StorageModule

**Files:**
- Create: `Packages/Core/StorageModule/Sources/StorageModule/SavedArticle.swift`
- Create: `Packages/Core/StorageModule/Sources/StorageModule/PersistenceController.swift`
- Test: `NewsAppTests/StorageModuleTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
// NewsAppTests/StorageModuleTests.swift
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:NewsAppTests/StorageModuleTests 2>&1 | tail -20
```

Expected: build error — `SavedArticle` and `PersistenceController` not defined.

- [ ] **Step 3: Implement SavedArticle model**

```swift
// Packages/Core/StorageModule/Sources/StorageModule/SavedArticle.swift
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
```

- [ ] **Step 4: Implement PersistenceController**

```swift
// Packages/Core/StorageModule/Sources/StorageModule/PersistenceController.swift
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
```

- [ ] **Step 5: Run test to verify it passes**

```bash
xcodebuild test -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:NewsAppTests/StorageModuleTests 2>&1 | tail -20
```

Expected: `Test Suite 'StorageModuleTests' passed`

- [ ] **Step 6: Commit**

```bash
git add Packages/Core/StorageModule/ NewsAppTests/StorageModuleTests.swift
git commit -m "feat: implement StorageModule with SwiftData SavedArticle model"
```

---

### Task 7: NetworkModule — API Client

**Files:**
- Create: `Packages/Core/NetworkModule/Sources/NetworkModule/Endpoints.swift`
- Create: `Packages/Core/NetworkModule/Sources/NetworkModule/NewsAPIClient.swift`
- Test: `NewsAppTests/NetworkModuleTests.swift`

- [ ] **Step 1: Write the failing tests**

```swift
// NewsAppTests/NetworkModuleTests.swift
import Testing
import Foundation
@testable import NetworkModule

// MARK: - Mock URLSession

final class MockURLSession: URLSessionProtocol {
    var stubbedData: Data = Data()
    var stubbedResponse: URLResponse = HTTPURLResponse(
        url: URL(string: "https://newsapi.org")!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
    )!
    var stubbedError: Error?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = stubbedError { throw error }
        return (stubbedData, stubbedResponse)
    }
}

// MARK: - Tests

@Suite("NewsAPIClient")
struct NewsAPIClientTests {

    @Test("fetchSources decodes valid JSON")
    func fetchSourcesDecodesValidJSON() async throws {
        let session = MockURLSession()
        session.stubbedData = """
        {
            "status": "ok",
            "sources": [
                {"id": "bbc-news", "name": "BBC News", "description": "BBC News", "url": "https://bbc.com", "category": "general", "language": "en", "country": "gb"}
            ]
        }
        """.data(using: .utf8)!

        let client = NewsAPIClient(session: session, apiKey: "test-key", baseURL: URL(string: "https://newsapi.org")!)
        let sources = try await client.fetchSources()
        #expect(sources.count == 1)
        #expect(sources.first?.id == "bbc-news")
    }

    @Test("fetchArticles decodes valid JSON")
    func fetchArticlesDecodesValidJSON() async throws {
        let session = MockURLSession()
        session.stubbedData = """
        {
            "status": "ok",
            "totalResults": 1,
            "articles": [
                {
                    "source": {"id": "bbc-news", "name": "BBC News"},
                    "title": "Test Headline",
                    "url": "https://bbc.com/article",
                    "urlToImage": null,
                    "publishedAt": "2026-04-12T10:00:00Z",
                    "description": "A test article"
                }
            ]
        }
        """.data(using: .utf8)!

        let client = NewsAPIClient(session: session, apiKey: "test-key", baseURL: URL(string: "https://newsapi.org")!)
        let articles = try await client.fetchArticles(sourceIds: ["bbc-news"])
        #expect(articles.count == 1)
        #expect(articles.first?.title == "Test Headline")
    }

    @Test("fetchSources throws on HTTP error")
    func fetchSourcesThrowsOnHTTPError() async throws {
        let session = MockURLSession()
        session.stubbedResponse = HTTPURLResponse(
            url: URL(string: "https://newsapi.org")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!
        session.stubbedData = Data()

        let client = NewsAPIClient(session: session, apiKey: "bad-key", baseURL: URL(string: "https://newsapi.org")!)
        await #expect(throws: NewsAPIError.self) {
            _ = try await client.fetchSources()
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:NewsAppTests/NewsAPIClientTests 2>&1 | tail -20
```

Expected: build error — `NewsAPIClient`, `URLSessionProtocol`, `NewsAPIError` not defined.

- [ ] **Step 3: Implement Endpoints.swift**

```swift
// Packages/Core/NetworkModule/Sources/NetworkModule/Endpoints.swift
import Foundation

public enum NewsAPIEndpoint {
    case sources
    case topHeadlines(sourceIds: [String])

    func url(baseURL: URL, apiKey: String) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        switch self {
        case .sources:
            components.path = "/v2/sources"
            components.queryItems = [URLQueryItem(name: "apiKey", value: apiKey)]
        case .topHeadlines(let ids):
            components.path = "/v2/top-headlines"
            components.queryItems = [
                URLQueryItem(name: "sources", value: ids.joined(separator: ",")),
                URLQueryItem(name: "apiKey", value: apiKey)
            ]
        }
        return components.url!
    }
}
```

- [ ] **Step 4: Implement NewsAPIClient.swift**

```swift
// Packages/Core/NetworkModule/Sources/NetworkModule/NewsAPIClient.swift
import Foundation

// MARK: - Protocol for URLSession (enables testing without real network)

public protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

// MARK: - Errors

public enum NewsAPIError: Error, Equatable {
    case httpError(statusCode: Int)
    case decodingError
    case invalidURL
}

// MARK: - Response models (internal to NetworkModule)

struct SourcesResponse: Decodable {
    let sources: [SourceDTO]
}

struct ArticlesResponse: Decodable {
    let articles: [ArticleDTO]
}

public struct SourceDTO: Decodable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let url: String
    public let category: String
    public let language: String
    public let country: String
}

public struct ArticleDTO: Decodable, Sendable {
    public struct SourceRef: Decodable, Sendable {
        public let id: String?
        public let name: String
    }
    public let source: SourceRef
    public let title: String
    public let url: String
    public let urlToImage: String?
    public let publishedAt: String
    public let description: String?
}

// MARK: - Client protocol

public protocol NewsAPIClientProtocol: Sendable {
    func fetchSources() async throws -> [SourceDTO]
    func fetchArticles(sourceIds: [String]) async throws -> [ArticleDTO]
}

// MARK: - Live implementation

public struct NewsAPIClient: NewsAPIClientProtocol {
    private let session: any URLSessionProtocol
    private let apiKey: String
    private let baseURL: URL
    private let decoder: JSONDecoder

    public init(
        session: any URLSessionProtocol = URLSession.shared,
        apiKey: String = Bundle.main.infoDictionary?["NEWSAPI_KEY"] as? String ?? "",
        baseURL: URL = URL(string: "https://newsapi.org")!
    ) {
        self.session = session
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    public func fetchSources() async throws -> [SourceDTO] {
        let url = NewsAPIEndpoint.sources.url(baseURL: baseURL, apiKey: apiKey)
        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return try decode(SourcesResponse.self, from: data).sources
    }

    public func fetchArticles(sourceIds: [String]) async throws -> [ArticleDTO] {
        let url = NewsAPIEndpoint.topHeadlines(sourceIds: sourceIds).url(baseURL: baseURL, apiKey: apiKey)
        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return try decode(ArticlesResponse.self, from: data).articles
    }

    private func validate(response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw NewsAPIError.httpError(statusCode: http.statusCode)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw NewsAPIError.decodingError
        }
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
xcodebuild test -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:NewsAppTests/NewsAPIClientTests 2>&1 | tail -20
```

Expected: `Test Suite 'NewsAPIClientTests' passed`

- [ ] **Step 6: Commit**

```bash
git add Packages/Core/NetworkModule/ NewsAppTests/NetworkModuleTests.swift
git commit -m "feat: implement NewsAPIClient with URLSessionProtocol injection"
```

---

### Task 8: NetworkModule — Certificate Pinning

**Files:**
- Create: `Packages/Core/NetworkModule/Sources/NetworkModule/PinningConfig.swift`
- Create: `Packages/Core/NetworkModule/Sources/NetworkModule/PinningDelegate.swift`

- [ ] **Step 1: Extract the NewsAPI.org public key hash**

Run this in Terminal to get the SHA-256 public key hash for newsapi.org:

```bash
openssl s_client -connect newsapi.org:443 2>/dev/null | \
  openssl x509 -pubkey -noout | \
  openssl pkey -pubin -outform DER | \
  openssl dgst -sha256 -binary | \
  base64
```

Copy the output — it is your primary pin hash.

- [ ] **Step 2: Implement PinningConfig.swift**

```swift
// Packages/Core/NetworkModule/Sources/NetworkModule/PinningConfig.swift
import Foundation

public struct PinningConfig {
    /// SHA-256 base64-encoded hashes of the NewsAPI.org server public keys.
    /// Include the current key + one backup key for zero-downtime rotation.
    /// Regenerate via: openssl s_client -connect newsapi.org:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform DER | openssl dgst -sha256 -binary | base64
    public static let pinnedHashes: Set<String> = [
        "REPLACE_WITH_PRIMARY_HASH",   // Current newsapi.org public key hash
        "REPLACE_WITH_BACKUP_HASH"     // Backup — update before rotating primary
    ]

    public static let pinnedHost = "newsapi.org"
}
```

- [ ] **Step 3: Implement PinningDelegate.swift**

```swift
// Packages/Core/NetworkModule/Sources/NetworkModule/PinningDelegate.swift
import Foundation
import CryptoKit

public final class PinningDelegate: NSObject, URLSessionDelegate, Sendable {

    private let pinnedHashes: Set<String>
    private let pinnedHost: String

    public init(
        pinnedHashes: Set<String> = PinningConfig.pinnedHashes,
        pinnedHost: String = PinningConfig.pinnedHost
    ) {
        self.pinnedHashes = pinnedHashes
        self.pinnedHost = pinnedHost
    }

    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            challenge.protectionSpace.host == pinnedHost,
            let serverTrust = challenge.protectionSpace.serverTrust,
            let certificate = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
            let leafCert = certificate.first,
            let publicKey = SecCertificateCopyKey(leafCert),
            let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data?
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let hash = SHA256.hash(data: publicKeyData)
        let hashBase64 = Data(hash).base64EncodedString()

        if pinnedHashes.contains(hashBase64) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
```

- [ ] **Step 4: Update NewsAPIClient to use PinningDelegate in production**

Add a static factory method to `NewsAPIClient.swift`:

```swift
// Add inside NewsAPIClient struct:
public static func makeLive() -> NewsAPIClient {
    // Check if UI tests requested pinning to be disabled
    let disablePinning = ProcessInfo.processInfo.arguments.contains("-disablePinning")
    let session: URLSession
    if disablePinning {
        session = URLSession.shared
    } else {
        let delegate = PinningDelegate()
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
    }
    return NewsAPIClient(session: session)
}
```

- [ ] **Step 5: Commit**

```bash
git add Packages/Core/NetworkModule/Sources/NetworkModule/PinningConfig.swift
git add Packages/Core/NetworkModule/Sources/NetworkModule/PinningDelegate.swift
git commit -m "feat: add public key certificate pinning to NetworkModule"
```

---

## Phase 3 — Feature Modules

### Task 9: WebModule

**Files:**
- Create: `Packages/Features/WebModule/Sources/WebModule/Views/WebViewContainer.swift`

- [ ] **Step 1: Implement WebViewContainer**

```swift
// Packages/Features/WebModule/Sources/WebModule/Views/WebViewContainer.swift
import SwiftUI
import WebKit
import StorageModule

public struct WebViewContainer: View {
    let url: URL
    let articleId: String
    let articleTitle: String
    let articleImageURL: String?
    let sourceName: String

    @State private var isLoading = true
    @State private var progress: Double = 0
    @State private var isBookmarked: Bool = false

    private let modelContext: ModelContext

    public init(
        url: URL,
        articleId: String,
        articleTitle: String,
        articleImageURL: String?,
        sourceName: String,
        modelContext: ModelContext
    ) {
        self.url = url
        self.articleId = articleId
        self.articleTitle = articleTitle
        self.articleImageURL = articleImageURL
        self.sourceName = sourceName
        self.modelContext = modelContext
    }

    public var body: some View {
        ZStack(alignment: .top) {
            WebViewRepresentable(url: url, isLoading: $isLoading, progress: $progress)
                .ignoresSafeArea()
            if isLoading {
                ProgressView(value: progress)
                    .tint(.blue)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    toggleBookmark()
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                }
            }
        }
        .onAppear { checkBookmarkStatus() }
    }

    private func checkBookmarkStatus() {
        let descriptor = FetchDescriptor<SavedArticle>(
            predicate: #Predicate { $0.id == articleId }
        )
        isBookmarked = (try? modelContext.fetch(descriptor).isEmpty == false) ?? false
    }

    private func toggleBookmark() {
        if isBookmarked {
            let descriptor = FetchDescriptor<SavedArticle>(
                predicate: #Predicate { $0.id == articleId }
            )
            if let saved = try? modelContext.fetch(descriptor).first {
                modelContext.delete(saved)
                try? modelContext.save()
            }
        } else {
            let saved = SavedArticle(
                id: articleId,
                title: articleTitle,
                url: url.absoluteString,
                imageURL: articleImageURL,
                sourceName: sourceName,
                savedAt: Date()
            )
            modelContext.insert(saved)
            try? modelContext.save()
        }
        isBookmarked.toggle()
    }
}

// MARK: - UIViewRepresentable bridge

struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var progress: Double

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.addObserver(context.coordinator, forKeyPath: "estimatedProgress", options: .new, context: nil)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading, progress: $progress)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        @Binding var progress: Double

        init(isLoading: Binding<Bool>, progress: Binding<Double>) {
            _isLoading = isLoading
            _progress = progress
        }

        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
            if keyPath == "estimatedProgress", let webView = object as? WKWebView {
                progress = webView.estimatedProgress
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            isLoading = true
        }
    }
}
```

- [ ] **Step 2: Build to verify no errors**

```bash
xcodebuild build -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(error:|Build succeeded)"
```

Expected: `Build succeeded`

- [ ] **Step 3: Commit**

```bash
git add Packages/Features/WebModule/
git commit -m "feat: implement WebModule with WKWebView and bookmark toggle"
```

---

### Task 10: SourceModule

**Files:**
- Create: `Packages/Features/SourceModule/Sources/SourceModule/Models/Source.swift`
- Create: `Packages/Features/SourceModule/Sources/SourceModule/Services/SourceService.swift`
- Create: `Packages/Features/SourceModule/Sources/SourceModule/ViewModels/SourceViewModel.swift`
- Create: `Packages/Features/SourceModule/Sources/SourceModule/Views/SourceListView.swift`
- Test: `NewsAppTests/SourceViewModelTests.swift`

- [ ] **Step 1: Write the failing ViewModel tests**

```swift
// NewsAppTests/SourceViewModelTests.swift
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
        service.stubbedSources = [Source(id: "bbc-news", name: "BBC News", category: "general", country: "gb", language: "en")]
        let vm = SourceViewModel(service: service)
        await vm.loadSources()
        if case .loaded(let sources) = vm.state {
            #expect(sources.count == 1)
            #expect(sources.first?.id == "bbc-news")
        } else {
            Issue.record("Expected .loaded state, got \(vm.state)")
        }
    }

    @Test("loadSources sets state to error on failure")
    func loadSourcesSetsErrorState() async {
        let service = MockSourceService()
        service.stubbedError = NSError(domain: "test", code: 0)
        let vm = SourceViewModel(service: service)
        await vm.loadSources()
        if case .error = vm.state {
            // pass
        } else {
            Issue.record("Expected .error state, got \(vm.state)")
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:NewsAppTests/SourceViewModelTests 2>&1 | tail -20
```

Expected: build error — `Source`, `SourceServiceProtocol`, `SourceViewModel` not defined.

- [ ] **Step 3: Implement Source model**

```swift
// Packages/Features/SourceModule/Sources/SourceModule/Models/Source.swift
import Foundation

public struct Source: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let category: String
    public let country: String
    public let language: String

    public init(id: String, name: String, category: String, country: String, language: String) {
        self.id = id
        self.name = name
        self.category = category
        self.country = country
        self.language = language
    }
}
```

- [ ] **Step 4: Implement SourceService**

```swift
// Packages/Features/SourceModule/Sources/SourceModule/Services/SourceService.swift
import Foundation
import NetworkModule

public protocol SourceServiceProtocol: Sendable {
    func fetchSources() async throws -> [Source]
}

public struct SourceService: SourceServiceProtocol {
    private let client: any NewsAPIClientProtocol

    public init(client: any NewsAPIClientProtocol = NewsAPIClient.makeLive()) {
        self.client = client
    }

    public func fetchSources() async throws -> [Source] {
        let dtos = try await client.fetchSources()
        return dtos.map {
            Source(id: $0.id, name: $0.name, category: $0.category, country: $0.country, language: $0.language)
        }
    }
}
```

- [ ] **Step 5: Implement SourceViewModel**

```swift
// Packages/Features/SourceModule/Sources/SourceModule/ViewModels/SourceViewModel.swift
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
```

- [ ] **Step 6: Implement SourceListView**

```swift
// Packages/Features/SourceModule/Sources/SourceModule/Views/SourceListView.swift
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
```

- [ ] **Step 7: Run tests to verify they pass**

```bash
xcodebuild test -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:NewsAppTests/SourceViewModelTests 2>&1 | tail -20
```

Expected: `Test Suite 'SourceViewModelTests' passed`

- [ ] **Step 8: Commit**

```bash
git add Packages/Features/SourceModule/ NewsAppTests/SourceViewModelTests.swift
git commit -m "feat: implement SourceModule with MVVM and protocol-injected service"
```

---

### Task 11: ArticleModule

**Files:**
- Create: `Packages/Features/ArticleModule/Sources/ArticleModule/Models/Article.swift`
- Create: `Packages/Features/ArticleModule/Sources/ArticleModule/Services/ArticleService.swift`
- Create: `Packages/Features/ArticleModule/Sources/ArticleModule/ViewModels/ArticleViewModel.swift`
- Create: `Packages/Features/ArticleModule/Sources/ArticleModule/Views/ArticleRowView.swift`
- Create: `Packages/Features/ArticleModule/Sources/ArticleModule/Views/ArticleListView.swift`
- Test: `NewsAppTests/ArticleViewModelTests.swift`

- [ ] **Step 1: Write the failing ViewModel tests**

```swift
// NewsAppTests/ArticleViewModelTests.swift
import Testing
import Foundation
@testable import ArticleModule

final class MockArticleService: ArticleServiceProtocol {
    var stubbedArticles: [Article] = []
    var stubbedError: Error?

    func fetchArticles(sourceIds: [String]) async throws -> [Article] {
        if let error = stubbedError { throw error }
        return stubbedArticles
    }
}

@Suite("ArticleViewModel")
struct ArticleViewModelTests {

    @Test("loadArticles sets loaded state with articles")
    func loadArticlesSetsLoadedState() async {
        let service = MockArticleService()
        service.stubbedArticles = [
            Article(id: "1", title: "Test", url: "https://example.com", imageURL: nil, sourceName: "BBC", publishedAt: "2026-04-12T10:00:00Z", description: nil)
        ]
        let vm = ArticleViewModel(service: service)
        await vm.loadArticles(sourceIds: ["bbc-news"])
        if case .loaded(let articles) = vm.state {
            #expect(articles.count == 1)
        } else {
            Issue.record("Expected .loaded state")
        }
    }

    @Test("loadArticles sets error state on failure")
    func loadArticlesSetsErrorState() async {
        let service = MockArticleService()
        service.stubbedError = NSError(domain: "test", code: 0)
        let vm = ArticleViewModel(service: service)
        await vm.loadArticles(sourceIds: ["bbc-news"])
        if case .error = vm.state {
            // pass
        } else {
            Issue.record("Expected .error state")
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:NewsAppTests/ArticleViewModelTests 2>&1 | tail -20
```

Expected: build error.

- [ ] **Step 3: Implement Article model**

```swift
// Packages/Features/ArticleModule/Sources/ArticleModule/Models/Article.swift
import Foundation

public struct Article: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let url: String
    public let imageURL: String?
    public let sourceName: String
    public let publishedAt: String
    public let description: String?

    public init(id: String, title: String, url: String, imageURL: String?, sourceName: String, publishedAt: String, description: String?) {
        self.id = id
        self.title = title
        self.url = url
        self.imageURL = imageURL
        self.sourceName = sourceName
        self.publishedAt = publishedAt
        self.description = description
    }
}
```

- [ ] **Step 4: Implement ArticleService**

```swift
// Packages/Features/ArticleModule/Sources/ArticleModule/Services/ArticleService.swift
import Foundation
import NetworkModule

public protocol ArticleServiceProtocol: Sendable {
    func fetchArticles(sourceIds: [String]) async throws -> [Article]
}

public struct ArticleService: ArticleServiceProtocol {
    private let client: any NewsAPIClientProtocol

    public init(client: any NewsAPIClientProtocol = NewsAPIClient.makeLive()) {
        self.client = client
    }

    public func fetchArticles(sourceIds: [String]) async throws -> [Article] {
        let dtos = try await client.fetchArticles(sourceIds: sourceIds)
        return dtos.enumerated().map { index, dto in
            Article(
                id: dto.url,
                title: dto.title,
                url: dto.url,
                imageURL: dto.urlToImage,
                sourceName: dto.source.name,
                publishedAt: dto.publishedAt,
                description: dto.description
            )
        }
    }
}
```

- [ ] **Step 5: Implement ArticleViewModel**

```swift
// Packages/Features/ArticleModule/Sources/ArticleModule/ViewModels/ArticleViewModel.swift
import Foundation
import Observation

public enum ArticleState {
    case idle
    case loading
    case loaded([Article])
    case error(String)
}

@Observable
public final class ArticleViewModel {
    public private(set) var state: ArticleState = .idle
    private let service: any ArticleServiceProtocol

    public init(service: any ArticleServiceProtocol = ArticleService()) {
        self.service = service
    }

    @MainActor
    public func loadArticles(sourceIds: [String]) async {
        guard !sourceIds.isEmpty else {
            state = .loaded([])
            return
        }
        state = .loading
        do {
            let articles = try await service.fetchArticles(sourceIds: sourceIds)
            state = .loaded(articles)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
```

- [ ] **Step 6: Implement ArticleRowView**

```swift
// Packages/Features/ArticleModule/Sources/ArticleModule/Views/ArticleRowView.swift
import SwiftUI

public struct ArticleRowView: View {
    let article: Article

    public init(article: Article) {
        self.article = article
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let imageURL = article.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.secondary.opacity(0.2))
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Text(article.title)
                .font(.headline)
                .lineLimit(3)
            HStack {
                Text(article.sourceName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(article.publishedAt.prefix(10))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
```

- [ ] **Step 7: Implement ArticleListView**

```swift
// Packages/Features/ArticleModule/Sources/ArticleModule/Views/ArticleListView.swift
import SwiftUI
import StorageModule

public struct ArticleListView: View {
    let sourceIds: [String]
    @State private var viewModel = ArticleViewModel()
    let onArticleTapped: (Article) -> Void

    public init(sourceIds: [String], onArticleTapped: @escaping (Article) -> Void) {
        self.sourceIds = sourceIds
        self.onArticleTapped = onArticleTapped
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Loading articles...")
            case .loaded(let articles) where articles.isEmpty:
                ContentUnavailableView(
                    "No Articles",
                    systemImage: "newspaper",
                    description: Text("Select sources on the Sources tab to see articles here.")
                )
            case .loaded(let articles):
                List(articles) { article in
                    Button {
                        onArticleTapped(article)
                    } label: {
                        ArticleRowView(article: article)
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
        .navigationTitle("Articles")
        .task { await viewModel.loadArticles(sourceIds: sourceIds) }
        .refreshable { await viewModel.loadArticles(sourceIds: sourceIds) }
    }
}
```

- [ ] **Step 8: Run tests to verify they pass**

```bash
xcodebuild test -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:NewsAppTests/ArticleViewModelTests 2>&1 | tail -20
```

Expected: `Test Suite 'ArticleViewModelTests' passed`

- [ ] **Step 9: Commit**

```bash
git add Packages/Features/ArticleModule/ NewsAppTests/ArticleViewModelTests.swift
git commit -m "feat: implement ArticleModule with MVVM and protocol-injected service"
```

---

### Task 12: SavedModule

**Files:**
- Create: `Packages/Features/SavedModule/Sources/SavedModule/ViewModels/SavedViewModel.swift`
- Create: `Packages/Features/SavedModule/Sources/SavedModule/Views/SavedListView.swift`

- [ ] **Step 1: Implement SavedViewModel**

```swift
// Packages/Features/SavedModule/Sources/SavedModule/ViewModels/SavedViewModel.swift
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
```

- [ ] **Step 2: Implement SavedListView**

```swift
// Packages/Features/SavedModule/Sources/SavedModule/Views/SavedListView.swift
import SwiftUI
import StorageModule

public struct SavedListView: View {
    @State private var viewModel: SavedViewModel
    let onArticleTapped: (SavedArticle) -> Void

    public init(modelContext: ModelContext, onArticleTapped: @escaping (SavedArticle) -> Void) {
        self._viewModel = State(initialValue: SavedViewModel(modelContext: modelContext))
        self.onArticleTapped = onArticleTapped
    }

    public var body: some View {
        Group {
            if viewModel.articles.isEmpty {
                ContentUnavailableView(
                    "No Saved Articles",
                    systemImage: "bookmark.slash",
                    description: Text("Bookmark articles while reading to save them here.")
                )
            } else {
                List {
                    ForEach(viewModel.articles) { article in
                        Button {
                            onArticleTapped(article)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(article.title)
                                    .font(.headline)
                                    .lineLimit(2)
                                Text(article.sourceName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                    .onDelete(perform: viewModel.delete)
                }
            }
        }
        .navigationTitle("Saved")
    }
}
```

- [ ] **Step 3: Build to verify no errors**

```bash
xcodebuild build -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(error:|Build succeeded)"
```

Expected: `Build succeeded`

- [ ] **Step 4: Commit**

```bash
git add Packages/Features/SavedModule/
git commit -m "feat: implement SavedModule with SwiftData-backed list and swipe-to-delete"
```

---

## Phase 4 — Host App Assembly

### Task 13: RootTabView & NewsApp Assembly

**Files:**
- Create: `NewsApp/RootTabView.swift`
- Modify: `NewsApp/NewsAppApp.swift`

- [ ] **Step 1: Create RootTabView.swift**

```swift
// NewsApp/RootTabView.swift
import SwiftUI
import SwiftData
import FeatureFlagModule
import SourceModule
import ArticleModule
import SavedModule
import WebModule
import StorageModule

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var featureFlags = FeatureFlags()
    @State private var selectedSourceIds: [String] = UserDefaults.standard.stringArray(forKey: "selectedSourceIds") ?? []

    var body: some View {
        TabView {
            // Tab 0: Sources
            NavigationStack {
                SourceListView { source in
                    var current = selectedSourceIds
                    if !current.contains(source.id) {
                        current.append(source.id)
                        selectedSourceIds = current
                        UserDefaults.standard.set(current, forKey: "selectedSourceIds")
                    }
                }
            }
            .tabItem {
                Label("Sources", systemImage: "antenna.radiowaves.left.and.right")
            }

            // Tab 1: Articles
            NavigationStack {
                ArticleListView(sourceIds: selectedSourceIds) { article in
                    // Navigation handled via NavigationStack path
                }
            }
            .tabItem {
                Label("Articles", systemImage: "newspaper")
            }

            // Tab 2: Saved (feature-flagged)
            if featureFlags.saveEnabled {
                NavigationStack {
                    SavedListView(modelContext: modelContext) { saved in
                        // Navigation handled via NavigationStack path
                    }
                }
                .tabItem {
                    Label("Saved", systemImage: "bookmark")
                }
            }
        }
    }
}
```

- [ ] **Step 2: Modify NewsAppApp.swift**

```swift
// NewsApp/NewsAppApp.swift
import SwiftUI
import SwiftData
import StorageModule

@main
struct NewsAppApp: App {
    private let container: ModelContainer = {
        guard let container = try? PersistenceController.makeContainer() else {
            fatalError("Failed to create ModelContainer")
        }
        return container
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(container)
    }
}
```

- [ ] **Step 3: Build and run in simulator**

```bash
xcodebuild build -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(error:|Build succeeded)"
```

Expected: `Build succeeded`. Then run in Xcode (Cmd+R) and verify 3 tabs appear (or 2 if `saveEnabled` is false in NewsCompanion).

- [ ] **Step 4: Commit**

```bash
git add NewsApp/RootTabView.swift NewsApp/NewsAppApp.swift
git commit -m "feat: assemble tab bar in RootTabView with feature flag gating"
```

---

### Task 14: NewsCompanion App

**Files:**
- Create: `NewsCompanion/CompanionApp.swift`
- Modify: `NewsApp.xcodeproj` (add new target — done via Xcode UI)

- [ ] **Step 1: Add NewsCompanion target in Xcode**

In Xcode → File → New → Target → iOS → App. Name it `NewsCompanion`. Minimum deployment target: iOS 17. Language: Swift. Interface: SwiftUI. Uncheck "Include Tests".

- [ ] **Step 2: Add FeatureFlagModule dependency to NewsCompanion target**

In Xcode → NewsCompanion target → General → Frameworks, Libraries, and Embedded Content → add `FeatureFlagModule`.

- [ ] **Step 3: Add App Group capability to both targets**

In Xcode → NewsApp target → Signing & Capabilities → + Capability → App Groups. Add `group.com.newsapp.flags`.
Repeat for NewsCompanion target.

- [ ] **Step 4: Implement CompanionApp.swift**

```swift
// NewsCompanion/CompanionApp.swift
import SwiftUI
import FeatureFlagModule

@main
struct CompanionApp: App {
    var body: some Scene {
        WindowGroup {
            FlagsDashboardView()
        }
    }
}

struct FlagsDashboardView: View {
    @State private var flags = FeatureFlags()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Save Tab Enabled", isOn: Binding(
                        get: { flags.saveEnabled },
                        set: { flags.saveEnabled = $0 }
                    ))
                } header: {
                    Text("Feature Flags")
                } footer: {
                    Text("Changes take effect immediately in NewsApp.")
                }
            }
            .navigationTitle("News Companion")
        }
    }
}
```

- [ ] **Step 5: Build both schemes to verify**

```bash
xcodebuild build -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(error:|Build succeeded)"
xcodebuild build -scheme NewsCompanion -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(error:|Build succeeded)"
```

Expected: both `Build succeeded`.

- [ ] **Step 6: Commit**

```bash
git add NewsCompanion/
git commit -m "feat: add NewsCompanion app for feature flag toggling via App Group"
```

---

## Phase 5 — Testing

### Task 15: Snapshot Tests

**Files:**
- Modify: `NewsApp.xcodeproj` (add swift-snapshot-testing via SPM)
- Create: `NewsAppSnapshotTests/ViewSnapshotTests.swift`

- [ ] **Step 1: Add swift-snapshot-testing via SPM**

In Xcode → File → Add Package Dependencies → paste:
`https://github.com/pointfreeco/swift-snapshot-testing`
Version: `1.17.0` (or latest). Add to `NewsAppSnapshotTests` target only.

- [ ] **Step 2: Implement snapshot tests**

```swift
// NewsAppSnapshotTests/ViewSnapshotTests.swift
import XCTest
import SnapshotTesting
import SwiftUI
@testable import SourceModule
@testable import ArticleModule

final class ViewSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Set isRecording = true to regenerate reference images
        // isRecording = true
    }

    func testSourceListView_loaded() {
        let view = NavigationStack {
            SourceListView { _ in }
        }
        // Inject loaded state by using a preview-ready version
        let vc = UIHostingController(rootView: view)
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        assertSnapshot(of: vc, as: .image(on: .iPhone13Pro))
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
```

- [ ] **Step 3: Generate reference snapshots (record mode)**

In `ViewSnapshotTests.swift`, uncomment `isRecording = true`. Then run:

```bash
xcodebuild test -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:NewsAppSnapshotTests 2>&1 | tail -20
```

Expected: tests "fail" in record mode and write PNG files to `__Snapshots__/`.

- [ ] **Step 4: Re-comment isRecording and commit snapshots**

Comment out `isRecording = true` again. Then:

```bash
git add NewsAppSnapshotTests/ 
git commit -m "feat: add snapshot tests with reference images"
```

- [ ] **Step 5: Verify snapshot tests assert correctly**

```bash
xcodebuild test -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:NewsAppSnapshotTests 2>&1 | tail -20
```

Expected: all snapshot tests pass.

---

### Task 16: UI Tests with Mockoon

**Files:**
- Create: `MockData/mockoon-config.json`
- Create: `MockData/sources.json` (inline in mockoon config)
- Modify: `NewsAppUITests/NewsAppUITests.swift`

- [ ] **Step 1: Create Mockoon config**

```json
// MockData/mockoon-config.json
{
  "uuid": "newsapp-mock-server",
  "name": "NewsApp Mock",
  "port": 3000,
  "routes": [
    {
      "uuid": "sources-route",
      "method": "get",
      "endpoint": "v2/sources",
      "responses": [
        {
          "uuid": "sources-ok",
          "statusCode": 200,
          "headers": [{"key": "Content-Type", "value": "application/json"}],
          "body": "{\"status\":\"ok\",\"sources\":[{\"id\":\"bbc-news\",\"name\":\"BBC News\",\"description\":\"Breaking news\",\"url\":\"https://bbc.com\",\"category\":\"general\",\"language\":\"en\",\"country\":\"gb\"},{\"id\":\"techcrunch\",\"name\":\"TechCrunch\",\"description\":\"Tech news\",\"url\":\"https://techcrunch.com\",\"category\":\"technology\",\"language\":\"en\",\"country\":\"us\"}]}"
        }
      ]
    },
    {
      "uuid": "headlines-route",
      "method": "get",
      "endpoint": "v2/top-headlines",
      "responses": [
        {
          "uuid": "headlines-ok",
          "statusCode": 200,
          "headers": [{"key": "Content-Type", "value": "application/json"}],
          "body": "{\"status\":\"ok\",\"totalResults\":1,\"articles\":[{\"source\":{\"id\":\"bbc-news\",\"name\":\"BBC News\"},\"title\":\"Test UI Headline\",\"url\":\"https://bbc.com/article\",\"urlToImage\":null,\"publishedAt\":\"2026-04-12T10:00:00Z\",\"description\":\"A test article for UI tests\"}]}"
        }
      ]
    }
  ]
}
```

- [ ] **Step 2: Write UI tests**

```swift
// NewsAppUITests/NewsAppUITests.swift
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

    func testTappingSourceNavigatesToArticles() throws {
        app.tabBars.buttons["Sources"].tap()
        let bbcCell = app.staticTexts["BBC News"]
        XCTAssertTrue(bbcCell.waitForExistence(timeout: 5))
        bbcCell.tap()

        let articleCell = app.staticTexts["Test UI Headline"]
        XCTAssertTrue(articleCell.waitForExistence(timeout: 5))
    }

    func testArticlesTabLoadsArticles() throws {
        app.tabBars.buttons["Articles"].tap()
        let articleCell = app.staticTexts["Test UI Headline"]
        XCTAssertTrue(articleCell.waitForExistence(timeout: 5))
    }

    func testTappingArticleOpensWebView() throws {
        app.tabBars.buttons["Articles"].tap()
        let articleCell = app.staticTexts["Test UI Headline"]
        XCTAssertTrue(articleCell.waitForExistence(timeout: 5))
        articleCell.tap()

        let bookmarkButton = app.navigationBars.buttons["bookmark"]
        XCTAssertTrue(bookmarkButton.waitForExistence(timeout: 5))
    }
}
```

- [ ] **Step 3: Install Mockoon CLI locally to verify**

```bash
npm install -g @mockoon/cli
mockoon-cli start --data MockData/mockoon-config.json --port 3000 &
sleep 2
curl http://localhost:3000/v2/sources | python3 -m json.tool | head -20
```

Expected: valid JSON with BBC News source.

- [ ] **Step 4: Run UI tests (with Mockoon running)**

```bash
xcodebuild test -scheme NewsApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:NewsAppUITests 2>&1 | tail -20
```

Expected: all UI tests pass.

- [ ] **Step 5: Kill Mockoon and commit**

```bash
pkill -f mockoon
git add MockData/ NewsAppUITests/
git commit -m "feat: add UI tests with Mockoon mock server integration"
```

---

## Phase 6 — CI/CD

### Task 17: GitHub Actions Workflow

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Create ci.yml**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint:
    name: SwiftLint
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - name: Install SwiftLint
        run: brew install swiftlint
      - name: Run SwiftLint
        run: swiftlint lint --strict --reporter github-actions-logging

  test:
    name: Test
    needs: lint
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4

      - name: Write Secrets.xcconfig
        run: |
          echo "NEWSAPI_KEY = ${{ secrets.NEWSAPI_KEY }}" > Secrets.xcconfig

      - name: Install Mockoon CLI
        run: npm install -g @mockoon/cli

      - name: Start Mockoon
        run: |
          mockoon-cli start --data MockData/mockoon-config.json --port 3000 &
          sleep 3

      - name: Run tests
        run: |
          xcodebuild test \
            -scheme NewsApp \
            -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
            -enableCodeCoverage YES \
            -resultBundlePath TestResults.xcresult \
            | xcpretty

      - name: Convert coverage to Sonar format
        run: |
          brew install xchtmlreport
          xccov view --report --json TestResults.xcresult > coverage.json
          # Convert to cobertura XML for SonarCloud
          pip3 install xcresulttool
          python3 -c "
          import json, sys
          with open('coverage.json') as f:
              data = json.load(f)
          # Minimal cobertura XML generation
          print('<?xml version=\"1.0\" ?>')
          print('<coverage version=\"1\">')
          for target in data.get('targets', []):
              for file in target.get('files', []):
                  path = file.get('path', '')
                  coverage = file.get('lineCoverage', 0)
                  print(f'  <file path=\"{path}\" line-rate=\"{coverage}\"/>')
          print('</coverage>')
          " > coverage.xml

      - name: Upload coverage artifact
        uses: actions/upload-artifact@v4
        with:
          name: coverage
          path: coverage.xml

  sonar:
    name: SonarCloud
    needs: test
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Download coverage
        uses: actions/download-artifact@v4
        with:
          name: coverage

      - name: SonarCloud Scan
        uses: SonarSource/sonarcloud-github-action@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

- [ ] **Step 2: Create sonar-project.properties**

```properties
# sonar-project.properties
sonar.projectKey=newsapp_newsapp
sonar.organization=your-sonarcloud-org
sonar.projectName=NewsApp
sonar.projectVersion=1.0

sonar.sources=NewsApp,NewsCompanion,Packages
sonar.tests=NewsAppTests,NewsAppSnapshotTests,NewsAppUITests
sonar.exclusions=**/*.xcassets/**,**/DerivedData/**,**/.build/**

sonar.swift.coverage.reportPaths=coverage.xml
sonar.qualitygate.wait=true
```

- [ ] **Step 3: Set GitHub repository secrets**

In GitHub repository → Settings → Secrets and variables → Actions → New repository secret:
- `NEWSAPI_KEY` → your NewsAPI.org API key
- `SONAR_TOKEN` → from SonarCloud account → Security → Generate Token

- [ ] **Step 4: Commit CI config**

```bash
git add .github/ sonar-project.properties
git commit -m "feat: add GitHub Actions CI pipeline with lint, test, and SonarCloud"
```

- [ ] **Step 5: Push and verify pipeline runs**

```bash
git push origin main
```

Open GitHub → Actions tab. Verify the `CI` workflow triggers and all 3 jobs pass.

---

## Verification Checklist

Run these end-to-end checks after implementation is complete:

- [ ] `sh scripts/install-hooks.sh` runs without error
- [ ] Introduce a SwiftLint violation, attempt `git commit` → blocked with lint error
- [ ] Fix violation, re-commit → succeeds
- [ ] Run app in simulator: Sources tab loads list from NewsAPI `/sources`
- [ ] Tap source → navigated to ArticleListView with articles filtered to that source
- [ ] Articles tab shows headlines from all selected sources
- [ ] Tap article → WebView opens with progress bar and bookmark button
- [ ] Tap bookmark → article appears in Saved tab (relaunch app to confirm persistence)
- [ ] Launch NewsCompanion → toggle `saveEnabled` off → relaunch NewsApp → Saved tab gone
- [ ] Toggle `saveEnabled` on → Saved tab reappears
- [ ] `xcodebuild test` with Mockoon running → all unit, snapshot, UI tests pass
- [ ] GitHub Actions: push triggers CI, all 3 jobs (lint → test → sonar) pass
- [ ] SonarCloud dashboard shows project with coverage ≥ 80%
- [ ] Charles Proxy: intercept newsapi.org → verify request is cancelled (pinning works)

---

## Post-Plan Notes

- Replace `REPLACE_WITH_PRIMARY_HASH` and `REPLACE_WITH_BACKUP_HASH` in `PinningConfig.swift` with real SHA-256 hashes after running the `openssl` command in Task 8
- Replace `your-sonarcloud-org` in `sonar-project.properties` with your actual SonarCloud organization slug
- The `ArticleListView` on the Articles tab needs the `selectedSourceIds` passed from the parent — wire this via `@AppStorage` or `@Observable` shared state in `RootTabView`
- Snapshot reference images must be regenerated if the device/simulator or iOS version changes in CI
