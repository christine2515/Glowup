import Foundation

/// Constants and the shared inbox used by BOTH the app and the Share Extension.
/// Keep this file dependency-free (Foundation only) so it compiles in the
/// extension target.
enum AppGroup {
    /// Must match the App Group capability in both targets' entitlements.
    static let identifier = "group.com.glowup.shared"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }
}

/// A single reel handed off from the Share Extension to the app.
struct SharedReel: Codable, Identifiable {
    let id: UUID
    let url: String
    let sharedText: String?   // any caption/text that came with the share
    let date: Date

    init(url: String, sharedText: String? = nil) {
        self.id = UUID()
        self.url = url
        self.sharedText = sharedText
        self.date = Date()
    }
}

/// A tiny UserDefaults-backed queue in the App Group. The Share Extension
/// appends; the app drains it on launch / foreground.
enum ShareInbox {
    private static let key = "pendingReels"

    static func enqueue(_ reel: SharedReel) {
        guard let defaults = AppGroup.defaults else { return }
        var items = load(from: defaults)
        items.append(reel)
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: key)
        }
    }

    /// Returns and clears all pending reels.
    static func drain() -> [SharedReel] {
        guard let defaults = AppGroup.defaults else { return [] }
        let items = load(from: defaults)
        defaults.removeObject(forKey: key)
        return items
    }

    private static func load(from defaults: UserDefaults) -> [SharedReel] {
        guard let data = defaults.data(forKey: key),
              let items = try? JSONDecoder().decode([SharedReel].self, from: data)
        else { return [] }
        return items
    }
}
