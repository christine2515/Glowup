import Foundation
import AuthenticationServices
import SwiftData
import Observation
import UIKit

enum StravaError: LocalizedError {
    case notConfigured, notConnected, noCode, apiError

    var errorDescription: String? {
        switch self {
        case .notConfigured: "Strava isn't set up on the backend. Add STRAVA_CLIENT_ID/SECRET to backend .env."
        case .notConnected: "Connect your Strava account first."
        case .noCode: "Strava authorization was cancelled."
        case .apiError: "Couldn't load activities from Strava."
        }
    }
}

/// A run (or other activity) from the Strava API.
struct StravaActivity: Codable {
    let id: Int64
    let name: String
    let distance: Double      // meters
    let movingTime: Int       // seconds
    let startDate: Date
    let type: String?
    let sportType: String?

    enum CodingKeys: String, CodingKey {
        case id, name, distance, type
        case movingTime = "moving_time"
        case startDate = "start_date"
        case sportType = "sport_type"
    }

    var distanceKm: Double { distance / 1000 }
    var movingMin: Double { Double(movingTime) / 60 }
    var isRun: Bool { (sportType ?? type ?? "").lowercased().contains("run") }
}

/// Handles Strava OAuth and importing runs. The client secret never touches the
/// app — token exchange/refresh go through the backend; activity reads hit the
/// Strava API directly with the bearer token.
@Observable
final class StravaService: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = StravaService()

    /// Must match your Strava app's "Authorization Callback Domain".
    private let callbackScheme = "reelfit"
    private let callbackDomain = "reelfit.app"
    private let tokenKey = "strava.tokens"

    private let client = BackendClient()
    private var authSession: ASWebAuthenticationSession?

    var lastSyncMessage: String?

    var isConnected: Bool {
        KeychainStore.load(StravaTokens.self, key: tokenKey) != nil
    }

    // MARK: - Connect

    @MainActor
    func connect() async throws {
        let config = try await client.stravaConfig()
        guard config.configured, !config.clientId.isEmpty else { throw StravaError.notConfigured }

        var comps = URLComponents(string: "https://www.strava.com/oauth/authorize")!
        comps.queryItems = [
            .init(name: "client_id", value: config.clientId),
            .init(name: "redirect_uri", value: "\(callbackScheme)://\(callbackDomain)"),
            .init(name: "response_type", value: "code"),
            .init(name: "approval_prompt", value: "auto"),
            .init(name: "scope", value: "activity:read_all"),
        ]

        let code = try await authorize(url: comps.url!)
        let tokens = try await client.stravaExchange(code: code)
        KeychainStore.save(tokens, key: tokenKey)
    }

    func disconnect() {
        KeychainStore.delete(key: tokenKey)
        lastSyncMessage = nil
    }

    @MainActor
    private func authorize(url: URL) async throws -> String {
        try await withCheckedThrowingContinuation { cont in
            let session = ASWebAuthenticationSession(
                url: url, callbackURLScheme: callbackScheme
            ) { callbackURL, error in
                if let error {
                    // User cancellation comes back as an error too.
                    cont.resume(throwing: error)
                    return
                }
                guard let callbackURL,
                      let items = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems,
                      let code = items.first(where: { $0.name == "code" })?.value
                else { cont.resume(throwing: StravaError.noCode); return }
                cont.resume(returning: code)
            }
            session.presentationContextProvider = self
            self.authSession = session
            session.start()
        }
    }

    // MARK: - Sync

    @MainActor
    @discardableResult
    func syncRuns(into context: ModelContext) async throws -> Int {
        let token = try await validAccessToken()
        let activities = try await fetchActivities(token: token)

        let existing = try context.fetch(FetchDescriptor<RunEntry>())
        let existingIDs = Set(existing.compactMap(\.externalID))

        var added = 0
        for act in activities where act.isRun {
            let idStr = String(act.id)
            guard !existingIDs.contains(idStr) else { continue }
            let run = RunEntry(date: act.startDate, plannedDistanceKm: act.distanceKm)
            run.actualDistanceKm = act.distanceKm
            run.actualDurationMin = act.movingMin
            run.completed = true
            run.name = act.name
            run.source = .strava
            run.externalID = idStr
            context.insert(run)
            added += 1
        }
        lastSyncMessage = "Imported \(added) new run\(added == 1 ? "" : "s")."
        return added
    }

    private func validAccessToken() async throws -> String {
        guard var tokens = KeychainStore.load(StravaTokens.self, key: tokenKey) else {
            throw StravaError.notConnected
        }
        // Refresh a minute before expiry.
        if Date().timeIntervalSince1970 >= Double(tokens.expiresAt) - 60 {
            tokens = try await client.stravaRefresh(refreshToken: tokens.refreshToken)
            KeychainStore.save(tokens, key: tokenKey)
        }
        return tokens.accessToken
    }

    private func fetchActivities(token: String) async throws -> [StravaActivity] {
        var comps = URLComponents(string: "https://www.strava.com/api/v3/athlete/activities")!
        comps.queryItems = [.init(name: "per_page", value: "50")]
        var req = URLRequest(url: comps.url!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw StravaError.apiError
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([StravaActivity].self, from: data)
    }

    // MARK: - ASWebAuthenticationPresentationContextProviding

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow)
            ?? scenes.first?.windows.first
        return window ?? ASPresentationAnchor()
    }
}
