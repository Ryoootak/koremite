import XCTest
@testable import Koremite

final class TextUtilitiesTests: XCTestCase {
    func testSourceHashIsStableAfterTrimming() {
        XCTAssertEqual(
            TextUtilities.sourceHash(for: "  同じ本文\n"),
            TextUtilities.sourceHash(for: "同じ本文")
        )
    }

    func testProcessingModeThresholds() {
        XCTAssertEqual(TextUtilities.processingMode(for: 1), .short)
        XCTAssertEqual(TextUtilities.processingMode(for: 2_500), .normal)
        XCTAssertEqual(TextUtilities.processingMode(for: 8_500), .longChunked)
    }

    func testFuzzySearchIgnoresWidthCaseAndWhitespace() {
        XCTAssertTrue(TextUtilities.matchesFuzzy("ABC 住宅 ローン", query: "ａｂｃ住宅"))
        XCTAssertTrue(TextUtilities.matchesFuzzy("見積もりは5月10日までに確認", query: "見5確"))
        XCTAssertFalse(TextUtilities.matchesFuzzy("住宅ローンの相談", query: "商談"))
    }
}
