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
