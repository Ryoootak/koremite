import Foundation

protocol AIClient {
    func generateMinutes(request: GenerateMinutesRequest) async throws -> MinutesResult
}

enum AIClientError: LocalizedError {
    case emptyInput
    case tooLong(limit: Int)
    case invalidResponse
    case serverMessage(String)
    case network

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "文字起こしテキストを貼り付けてください。"
        case .tooLong(let limit):
            return "入力が長すぎます。\(limit)文字以内に調整してください。"
        case .invalidResponse:
            return "まとめの形式を読み取れませんでした。もう一度お試しください。"
        case .serverMessage(let message):
            return message
        case .network:
            return "通信に失敗しました。接続を確認してもう一度お試しください。"
        }
    }
}
