import XCTest
@testable import Koremite

final class MockAIClientTests: XCTestCase {
    func testMockClientReturnsSchemaCompatibleResult() async throws {
        let request = GenerateMinutesRequest(
            transcript: "今日は住宅購入の相談をしました。",
            category: .housing,
            speakers: ["自分", "担当者"],
            focusPoints: [.money, .schedule],
            clientRequestId: "test-request",
            sourceHash: "test-hash"
        )

        let result = try await MockAIClient().generateMinutes(request: request)

        XCTAssertFalse(result.title.isEmpty)
        XCTAssertEqual(result.category, .housing)
        XCTAssertEqual(result.costInfo.inputLength, request.transcript.count)
        XCTAssertEqual(result.sourceHash, request.sourceHash)
        XCTAssertFalse(result.shareSummary.text.isEmpty)
        XCTAssertFalse(result.fullLog.isEmpty)
    }
}
