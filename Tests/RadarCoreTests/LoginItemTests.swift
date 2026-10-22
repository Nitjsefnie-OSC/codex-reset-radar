import XCTest

@testable import RadarCore

final class LoginItemTests: XCTestCase {
    func testEnabledIsOnWithoutHint() {
        let state = LoginItemToggleState(status: .enabled)
        XCTAssertTrue(state.isOn)
        XCTAssertNil(state.approvalHint)
    }

    func testNotRegisteredAndNotFoundAreOffWithoutHint() {
        for status in [LoginItemStatus.notRegistered, .notFound] {
            let state = LoginItemToggleState(status: status)
            XCTAssertFalse(state.isOn)
            XCTAssertNil(state.approvalHint)
        }
    }

    func testRequiresApprovalStaysOnAndAsksForApproval() {
        let state = LoginItemToggleState(status: .requiresApproval)
        XCTAssertTrue(state.isOn)
        XCTAssertEqual(state.approvalHint?.contains("Login Items"), true)
    }
}
