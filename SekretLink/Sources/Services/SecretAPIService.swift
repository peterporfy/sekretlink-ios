import Foundation

/// Communicates with the sekret.link REST API.
/// API reference: https://sekret.link/api-doc
/// Server source: https://github.com/Ajnasz/sekret.link
final class SecretAPIService {

    enum APIError: LocalizedError {
        case invalidResponse
        case httpError(statusCode: Int, message: String)
        case decodingError(Error)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid server response"
            case .httpError(let code, let message):
                return "Server error \(code): \(message)"
            case .decodingError(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            }
        }
    }

    let baseURL: URL

    init(baseURL: URL = URL(string: "https://sekret.link/api/")!) {
        self.baseURL = baseURL
    }

    // MARK: - Create

    /// POST /api/ — create a new encrypted secret.
    /// - Parameters:
    ///   - encryptedData: AES-encrypted Base64 string
    ///   - expire: duration string: "1h", "24h", "168h", "720h"
    ///   - maxReads: how many times the secret can be read (1 = one-time)
    func createSecret(_ encryptedData: String, expire: String, maxReads: Int) async throws -> Secret {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        var queryItems: [URLQueryItem] = []
        if !expire.isEmpty {
            queryItems.append(URLQueryItem(name: "expire", value: expire))
        }
        if maxReads > 0 {
            queryItems.append(URLQueryItem(name: "maxReads", value: String(maxReads)))
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = Data(encryptedData.utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        return try decode(Secret.self, from: data)
    }

    // MARK: - Read

    /// GET /api/{uuid}/{key} — retrieve encrypted secret data.
    func getSecret(uuid: String, key: String) async throws -> Secret {
        let url = baseURL.appendingPathComponent(uuid).appendingPathComponent(key)
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        return try decode(Secret.self, from: data)
    }

    // MARK: - Delete

    /// DELETE /api/{uuid}/{key}/{deleteKey} — permanently destroy a secret.
    func deleteSecret(uuid: String, key: String, deleteKey: String) async throws {
        let url = baseURL
            .appendingPathComponent(uuid)
            .appendingPathComponent(key)
            .appendingPathComponent(deleteKey)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
    }

    // MARK: - Helpers

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(statusCode: http.statusCode, message: message)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
