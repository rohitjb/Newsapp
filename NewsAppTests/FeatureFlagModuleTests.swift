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
