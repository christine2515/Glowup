import Foundation

// DTOs mirror backend/app/schemas.py (keys already camelCase from the API).

struct ExtractedExercise: Codable {
    var name: String
    var instructions: String
    var sets: Int?
    var reps: Int?
    var durationSec: Int?
    var restSec: Int?
    var equipment: String?
}

struct ExtractedWorkout: Codable {
    var title: String
    var category: String
    var summary: String
    var exercises: [ExtractedExercise]
    var sourceURL: String
    var thumbnailURL: String?
    var caption: String?
    var needsManualCaption: Bool
}

struct StravaConfig: Codable {
    var clientId: String
    var configured: Bool
}

struct StravaTokens: Codable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Int
}

enum BackendError: LocalizedError {
    case notConfigured
    case badResponse(Int)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Set your backend URL in the Health tab → Settings first."
        case .badResponse(let code):
            return "Server returned status \(code)."
        case .transport(let msg):
            return msg
        }
    }
}

/// Thin async client for the Glowup backend.
struct BackendClient {
    let config: AppConfig

    init(config: AppConfig = .shared) { self.config = config }

    func extractReel(url: String, caption: String? = nil) async throws -> ExtractedWorkout {
        struct Body: Codable { let url: String; let caption: String? }
        return try await post("/reels/extract", body: Body(url: url, caption: caption))
    }

    // MARK: - Strava token operations (client secret stays on the backend)

    func stravaConfig() async throws -> StravaConfig {
        try await get("/strava/config")
    }

    func stravaExchange(code: String) async throws -> StravaTokens {
        struct Body: Codable { let code: String }
        return try await post("/strava/exchange", body: Body(code: code))
    }

    func stravaRefresh(refreshToken: String) async throws -> StravaTokens {
        struct Body: Codable { let refreshToken: String }
        return try await post("/strava/refresh", body: Body(refreshToken: refreshToken))
    }

    // MARK: - Plumbing

    private func makeRequest(_ path: String) throws -> URLRequest {
        guard config.isBackendConfigured,
              let url = URL(string: config.backendURL.trimmingCharacters(in: .whitespaces) + path)
        else { throw BackendError.notConfigured }
        var req = URLRequest(url: url)
        req.timeoutInterval = 60
        if !config.apiToken.isEmpty {
            req.setValue(config.apiToken, forHTTPHeaderField: "X-Glowup-Token")
        }
        return req
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let req = try makeRequest(path)
        return try await send(req)
    }

    private func post<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        var req = try makeRequest(path)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        return try await send(req)
    }

    private func send<T: Decodable>(_ req: URLRequest) async throws -> T {
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else {
                throw BackendError.badResponse(-1)
            }
            guard (200..<300).contains(http.statusCode) else {
                throw BackendError.badResponse(http.statusCode)
            }
            return try JSONDecoder().decode(T.self, from: data)
        } catch let e as BackendError {
            throw e
        } catch {
            throw BackendError.transport(error.localizedDescription)
        }
    }
}
