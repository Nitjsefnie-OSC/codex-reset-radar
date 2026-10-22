import XCTest

@testable import RadarCore

final class NotificationAccessTests: XCTestCase {
    private func isOff(_ authorization: NotificationAccess.Authorization, alerts: NotificationAccess.Setting) -> Bool {
        NotificationAccess(authorization: authorization, alerts: alerts).isOff
    }

    func testDeniedIsOffWhateverTheAlertSetting() {
        XCTAssertTrue(isOff(.denied, alerts: .disabled))
        XCTAssertTrue(isOff(.denied, alerts: .enabled))
        XCTAssertTrue(isOff(.denied, alerts: .notSupported))
    }

    func testAllowedWithAlertsEnabledIsNotOff() {
        XCTAssertFalse(isOff(.authorized, alerts: .enabled))
        XCTAssertFalse(isOff(.provisional, alerts: .enabled))
        XCTAssertFalse(isOff(.ephemeral, alerts: .enabled))
    }

    func testAllowedWithAlertsDisabledIsOff() {
        XCTAssertTrue(isOff(.authorized, alerts: .disabled))
        XCTAssertTrue(isOff(.provisional, alerts: .disabled))
        XCTAssertTrue(isOff(.ephemeral, alerts: .disabled))
    }

    func testAlertsNotSupportedIsNotTreatedAsOff() {
        XCTAssertFalse(isOff(.authorized, alerts: .notSupported))
    }

    func testNotYetAskedIsNotOff() {
        XCTAssertFalse(isOff(.notDetermined, alerts: .disabled))
        XCTAssertFalse(isOff(.notDetermined, alerts: .notSupported))
    }

    func testWarningClearsWhenNotificationsAreAllowedAgain() {
        XCTAssertTrue(isOff(.denied, alerts: .disabled))
        XCTAssertFalse(isOff(.authorized, alerts: .enabled))
    }
}
