import Foundation

public struct PinningConfig {
    public static let pinnedHashes: Set<String> = [
        "mYL3uKZJYESzdUU9uD/Maao0nzbD18vS1WpsDRh7GDU=",
        "BACKUP_HASH_REPLACE_BEFORE_ROTATION" // Replace with next cert's hash before rotating primary
    ]

    public static let pinnedHost = "newsapi.org"
}
