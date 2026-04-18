import Foundation

public struct FeatureFlags {
    private let defaults: UserDefaults

    public static let appGroupID = "group.com.newsapp.flags"

    public init() {
        self.defaults = UserDefaults(suiteName: FeatureFlags.appGroupID) ?? .standard
    }

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public var saveEnabled: Bool {
        get { defaults.bool(forKey: "saveEnabled") }
        set { defaults.set(newValue, forKey: "saveEnabled") }
    }
}
