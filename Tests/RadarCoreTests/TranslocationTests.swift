import XCTest

@testable import RadarCore

final class TranslocationTests: XCTestCase {
    private func isTranslocated(_ path: String) -> Bool {
        Translocation.isTranslocated(bundleURL: URL(fileURLWithPath: path, isDirectory: true))
    }

    func testTranslocatedPathIsDetected() {
        XCTAssertTrue(
            isTranslocated(
                "/private/var/folders/xy/abcdef0123/T/AppTranslocation/0F1E2D3C-1111-2222-3333-444455556666/d/Codex Reset Radar.app"
            ))
        XCTAssertTrue(
            isTranslocated("/var/folders/xy/abcdef0123/T/AppTranslocation/0F1E2D3C/d/Codex Reset Radar.app"))
    }

    func testRegularLocationsAreNotTranslocated() {
        XCTAssertFalse(isTranslocated("/Applications/Codex Reset Radar.app"))
        XCTAssertFalse(isTranslocated("/Users/me/Downloads/Codex Reset Radar.app"))
        XCTAssertFalse(isTranslocated("/Users/me/dev/.build/debug/CodexResetRadar"))
    }

    func testOnlyAWholePathComponentCounts() {
        XCTAssertFalse(isTranslocated("/Users/me/NotAppTranslocation/Codex Reset Radar.app"))
        XCTAssertFalse(isTranslocated("/Users/me/AppTranslocationNotes/Codex Reset Radar.app"))
    }
}
