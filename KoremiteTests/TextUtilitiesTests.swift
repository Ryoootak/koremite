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
}
