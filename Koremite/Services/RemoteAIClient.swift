import Foundation

struct RemoteAIClient: AIClient {
    let baseURL: URL
    var session: URLSession = .shared

    func generateMinutes(request: GenerateMinutesRequest) async throws -> MinutesResult {
        var urlRequest = URLRequest(url: baseURL.appending(path: "/v1/minutes"))
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 45
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIClientError.network
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                let message = (try? JSONDecoder().decode(APIErrorResponse.self, from: data).message)
                throw AIClientError.serverMessage(message ?? "議事録を生成できませんでした。時間をおいてもう一度お試しください。")
            }

            do {
                return try JSONDecoder().decode(MinutesResult.self, from: data)
            } catch {
                throw AIClientError.invalidResponse
            }
        } catch let error as AIClientError {
            throw error
        } catch {
            throw AIClientError.network
        }
    }
}

private struct APIErrorResponse: Decodable {
    let message: String
}
