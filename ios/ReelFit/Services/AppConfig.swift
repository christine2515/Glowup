import Foundation
import Observation

/// User-configurable settings, persisted in UserDefaults.
@Observable
final class AppConfig {
    static let shared = AppConfig()

    private let defaults = UserDefaults.standard

    /// Base URL of the ReelFit backend, e.g. "http://192.168.1.20:8000".
    var backendURL: String {
        didSet { defaults.set(backendURL, forKey: "backendURL") }
    }

    /// Optional shared secret matching REELFIT_API_TOKEN on the backend.
    var apiToken: String {
        didSet { defaults.set(apiToken, forKey: "apiToken") }
    }

    /// Toggle between metric/imperial display for weight.
    var useMetric: Bool {
        didSet { defaults.set(useMetric, forKey: "useMetric") }
    }

    private init() {
        backendURL = defaults.string(forKey: "backendURL") ?? ""
        apiToken = defaults.string(forKey: "apiToken") ?? ""
        useMetric = defaults.object(forKey: "useMetric") as? Bool ?? true
    }

    var isBackendConfigured: Bool {
        URL(string: backendURL)?.scheme != nil
    }
}
