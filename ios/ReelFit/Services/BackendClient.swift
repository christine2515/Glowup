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

struct MacroBudget: Codable {
    var kcal: Double
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
}

struct MealSuggestion: Codable, Identifiable {
    var id: String { name }
    var name: String
    var description: String
    var kcal: Double
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var ingredients: [String]
}

struct FoodResult: Codable, Identifiable {
    var id: String { name + serving }
    var name: String
    var serving: String
    var kcal: Double
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
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

/// Thin async client for the ReelFit backend.
struct BackendClient {
    let config: AppConfig

    init(config: AppConfig = .shared) { self.config = config }

    func extractReel(url: String, caption: String? = nil) async throws -> ExtractedWorkout {
        struct Body: Codable { let url: String; let caption: String? }
        return try await post("/reels/extract", body: Body(url: url, caption: caption))
    }

    func recommendMeals(
        remaining: MacroBudget, mealType: String, preferences: String
    ) async throws -> [MealSuggestion] {
        struct Body: Codable {
            let remaining: MacroBudget
            let mealType: String
            let preferences: String
        }
        struct Response: Codable { let suggestions: [MealSuggestion] }
        let r: Response = try await post(
            "/nutrition/recommend",
            body: Body(remaining: remaining, mealType: mealType, preferences: preferences)
        )
        return r.suggestions
    }

    func searchFood(_ query: String) async throws -> [FoodResult] {
        struct Response: Codable { let items: [FoodResult] }
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let r: Response = try await get("/nutrition/search?q=\(q)")
        return r.items
    }

    // MARK: - Plumbing

    private func makeRequest(_ path: String) throws -> URLRequest {
        guard config.isBackendConfigured,
              let url = URL(string: config.backendURL.trimmingCharacters(in: .whitespaces) + path)
        else { throw BackendError.notConfigured }
        var req = URLRequest(url: url)
        req.timeoutInterval = 60
        if !config.apiToken.isEmpty {
            req.setValue(config.apiToken, forHTTPHeaderField: "X-ReelFit-Token")
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
