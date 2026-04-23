//
//  NewsAppApp.swift
//  NewsApp
//
//  Created by Rohit on 12/4/2026.
//

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
