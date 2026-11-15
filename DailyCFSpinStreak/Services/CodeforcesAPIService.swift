//
//  CodeforcesAPIService.swift
//  DailyCFSpinStreak
//
//  Talks to the official Codeforces API using URLSession + async/await,
//  and parses the JSON with Codable.
//
//  Endpoints used:
//    https://codeforces.com/api/problemset.problems
//    https://codeforces.com/api/user.status?handle=HANDLE
//    https://codeforces.com/api/user.info?handles=HANDLE
//

import Foundation

/// Errors with messages that can be shown directly in an Alert.
nonisolated enum CodeforcesError: LocalizedError {
    case invalidURL
    case noInternet
    case serverError(statusCode: Int)
    case apiFailed(String)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not build the Codeforces request."
        case .noInternet:
            return "Could not reach Codeforces. Check your internet connection and try again."
        case .serverError(let statusCode):
            return "Codeforces is unavailable right now (HTTP \(statusCode)). Please try again later."
        case .apiFailed(let comment):
            if comment.lowercased().contains("not found") {
                return "Codeforces handle not found. Please check the spelling."
            }
            if comment.lowercased().contains("call limit") {
                return "Too many requests to Codeforces. Wait a few seconds and try again."
            }
            return "Codeforces error: \(comment)"
        case .decodingFailed:
            return "Codeforces sent data in an unexpected format."
        }
    }
}

final class CodeforcesAPIService {
    static let shared = CodeforcesAPIService()
    private init() {}

    private let baseURL = "https://codeforces.com/api/"

    /// The full problem set (~10,000 problems) is downloaded once and kept in
    /// memory, so every Spin after the first one is instant.
    private var cachedProblems: [Problem] = []

    // MARK: - Public API

    /// All problems from the Codeforces problemset.
    func fetchProblems() async throws -> [Problem] {
        if !cachedProblems.isEmpty {
            return cachedProblems
        }
        let result: ProblemsetResult = try await request(method: "problemset.problems", query: [:])
        cachedProblems = result.problems
        return cachedProblems
    }

    /// Every submission of a user (newest first). Used to find Accepted solves.
    func fetchSubmissions(handle: String) async throws -> [Submission] {
        try await request(method: "user.status", query: ["handle": handle])
    }

    /// Checks that a handle exists and returns its correctly capitalised form.
    func fetchUser(handle: String) async throws -> CodeforcesUser {
        let users: [CodeforcesUser] = try await request(method: "user.info", query: ["handles": handle])
        guard let user = users.first else {
            throw CodeforcesError.apiFailed("not found")
        }
        return user
    }

    // MARK: - Generic request

    /// Downloads `baseURL + method`, decodes the envelope, and returns "result" as type T.
    private func request<T: Decodable & Sendable>(method: String, query: [String: String]) async throws -> T {
        // 1. Build the URL safely (URLComponents escapes special characters).
        guard var components = URLComponents(string: baseURL + method) else {
            throw CodeforcesError.invalidURL
        }
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else {
            throw CodeforcesError.invalidURL
        }

        // 2. Download. `await` suspends here without freezing the UI.
        let data: Data
        let response: URLResponse
        do {
            let downloaded = try await URLSession.shared.data(from: url)
            data = downloaded.0
            response = downloaded.1
        } catch {
            throw CodeforcesError.noInternet
        }
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        // 3. Decode JSON on a background thread (the problem list is a few MB,
        //    decoding it on the main thread could make the UI stutter).
        let decoded: CodeforcesResponse<T>
        do {
            decoded = try await Task.detached(priority: .userInitiated) {
                try JSONDecoder().decode(CodeforcesResponse<T>.self, from: data)
            }.value
        } catch {
            // Not valid JSON: usually Codeforces is down and sent an HTML page.
            if statusCode != 200 {
                throw CodeforcesError.serverError(statusCode: statusCode)
            }
            throw CodeforcesError.decodingFailed
        }

        // 4. Codeforces says FAILED (e.g. invalid handle) → throw its comment.
        guard decoded.status == "OK", let result = decoded.result else {
            throw CodeforcesError.apiFailed(decoded.comment ?? "Unknown error")
        }
        return result
    }
}
