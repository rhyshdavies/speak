import Foundation

/// HTTP client for communicating with the Speak backend
final class APIClient {
    static let shared = APIClient()

    private let baseURL: URL
    private let session: URLSession

    private init() {
        guard let url = URL(string: AppConfig.backendBaseURL) else {
            fatalError("Invalid backend URL: \(AppConfig.backendBaseURL)")
        }
        self.baseURL = url

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConfig.apiTimeout
        config.timeoutIntervalForResource = AppConfig.apiTimeout * 2
        self.session = URLSession(configuration: config)
    }

    /// Send a conversation turn to the backend
    /// - Parameters:
    ///   - audioData: Recorded audio data
    ///   - requestData: Conversation context and messages
    /// - Returns: Full turn response with transcript, tutor response, and audio
    func postConversationTurn(
        audioData: Data,
        requestData: ConversationTurnRequest
    ) async throws -> TurnResponse {
        let url = baseURL.appendingPathComponent("api/conversation/turn")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        // Build multipart body
        var body = Data()

        // Add audio file
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.m4a\"\r\n")
        body.append("Content-Type: audio/m4a\r\n\r\n")
        body.append(audioData)
        body.append("\r\n")

        // Add JSON data
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let jsonData = try? encoder.encode(requestData) else {
            throw ConversationEngineError.encodingError
        }

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"data\"\r\n")
        body.append("Content-Type: application/json\r\n\r\n")
        body.append(jsonData)
        body.append("\r\n")

        body.append("--\(boundary)--\r\n")

        request.httpBody = body

        // Make request
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ConversationEngineError.invalidResponse
        }

        // Handle errors
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw ConversationEngineError.apiError(
                    "\(errorResponse.error): \(errorResponse.details ?? "")"
                )
            }
            throw ConversationEngineError.apiError("Status \(httpResponse.statusCode)")
        }

        // Decode response
        let decoder = JSONDecoder()
        return try decoder.decode(TurnResponse.self, from: data)
    }

    /// Health check
    func healthCheck() async -> Bool {
        let url = baseURL.appendingPathComponent("health")
        do {
            let (_, response) = try await session.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}

// MARK: - Data Extension for Multipart

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
