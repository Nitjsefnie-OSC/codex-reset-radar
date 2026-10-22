import XCTest

@testable import RadarCore

final class RetryAfterTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testSecondsAreAddedToNow() {
        XCTAssertEqual(RetryAfter.date(from: "120", now: now), now.addingTimeInterval(120))
        XCTAssertEqual(RetryAfter.date(from: " 0 ", now: now), now)
    }

    func testHTTPDate() {
        let expected = Date(timeIntervalSince1970: 784_111_777)
        XCTAssertEqual(RetryAfter.date(from: "Sun, 06 Nov 1994 08:49:37 GMT", now: now), expected)
        XCTAssertEqual(RetryAfter.date(from: "Sunday, 06-Nov-94 08:49:37 GMT", now: now), expected)
        XCTAssertEqual(RetryAfter.date(from: "Sun Nov  6 08:49:37 1994", now: now), expected)
    }

    func testMissingOrUnreadableIsNil() {
        XCTAssertNil(RetryAfter.date(from: nil, now: now))
        XCTAssertNil(RetryAfter.date(from: "", now: now))
        XCTAssertNil(RetryAfter.date(from: "soon", now: now))
        XCTAssertNil(RetryAfter.date(from: "-5", now: now))
        XCTAssertNil(RetryAfter.date(from: "1.5", now: now))
    }
}

final class PollFailureTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private var nextPoll: Date { now.addingTimeInterval(10 * 60) }
    private let locale = Locale(identifier: "en_GB")
    private let utc = TimeZone(identifier: "UTC")!

    private func failure(_ error: Error) -> PollFailure {
        PollFailure(error, now: now, nextRegularPoll: nextPoll, locale: locale, timeZone: utc)
    }

    func testOffline() {
        for code in [URLError.Code.notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .dnsLookupFailed] {
            let result = failure(URLError(code))
            XCTAssertEqual(result.message, "You're offline")
            XCTAssertNil(result.retryNotBefore)
        }
    }

    func testTimeout() {
        XCTAssertEqual(failure(URLError(.timedOut)).message, "Request timed out")
    }

    func testServerErrors() {
        XCTAssertEqual(
            failure(StatusError.http(500, retryAfter: nil)).message, "codex-resets.com is having trouble")
        XCTAssertEqual(
            failure(StatusError.http(502, retryAfter: nil)).message, "codex-resets.com is having trouble")
        XCTAssertNil(failure(StatusError.http(500, retryAfter: nil)).retryNotBefore)
    }

    func testRateLimitedWithRetryAfterSkipsPollsUntilThen() {
        // 1_800_000_000 is 2027-01-15 08:00:00 UTC.
        let retryAt = now.addingTimeInterval(65 * 60)
        let result = failure(StatusError.http(429, retryAfter: retryAt))
        XCTAssertEqual(result.retryNotBefore, retryAt)
        XCTAssertEqual(result.message, "Rate limited, retrying at 9:05")
    }

    func testRateLimitedWithoutRetryAfterBacksOffToNextRegularPoll() {
        let result = failure(StatusError.http(429, retryAfter: nil))
        XCTAssertEqual(result.retryNotBefore, nextPoll)
        XCTAssertEqual(result.message, "Rate limited, retrying at 8:10")
    }

    func testRateLimitedWithPastRetryAfterBacksOffToNextRegularPoll() {
        let result = failure(StatusError.http(429, retryAfter: now.addingTimeInterval(-30)))
        XCTAssertEqual(result.retryNotBefore, nextPoll)
    }

    func testServiceUnavailableHonoursRetryAfterOnly() {
        let retryAt = now.addingTimeInterval(120)
        let withHeader = failure(StatusError.http(503, retryAfter: retryAt))
        XCTAssertEqual(withHeader.retryNotBefore, retryAt)
        XCTAssertEqual(withHeader.message, "codex-resets.com is having trouble")
        XCTAssertNil(failure(StatusError.http(503, retryAfter: nil)).retryNotBefore)
    }

    func testRetryAfterIsCapped() {
        let result = failure(StatusError.http(429, retryAfter: now.addingTimeInterval(30 * 24 * 3600)))
        XCTAssertEqual(result.retryNotBefore, now.addingTimeInterval(PollFailure.maxRetryDelay))
    }

    func testRetryAfterOnOtherStatusesIsIgnored() {
        let result = failure(StatusError.http(404, retryAfter: now.addingTimeInterval(600)))
        XCTAssertNil(result.retryNotBefore)
        XCTAssertEqual(result.message, "codex-resets.com returned HTTP 404")
    }

    func testUnexpectedResponse() {
        let decoding = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "bad"))
        XCTAssertEqual(failure(decoding).message, "Unexpected response from codex-resets.com")
        XCTAssertEqual(failure(URLError(.badServerResponse)).message, "Unexpected response from codex-resets.com")
    }

    func testUnknownErrorsKeepTheirDescription() {
        let error = URLError(.cannotConnectToHost)
        XCTAssertEqual(failure(error).message, error.localizedDescription)
    }
}

final class ReconnectDebounceTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func at(_ seconds: TimeInterval) -> Date { start.addingTimeInterval(seconds) }

    func testFirstUpdateAtLaunchDoesNotRefresh() {
        var debounce = ReconnectDebounce()
        XCTAssertFalse(debounce.shouldRefresh(pathSatisfied: true, now: at(0)))
    }

    func testComingBackRefreshes() {
        var debounce = ReconnectDebounce()
        XCTAssertFalse(debounce.shouldRefresh(pathSatisfied: true, now: at(0)))
        XCTAssertFalse(debounce.shouldRefresh(pathSatisfied: false, now: at(100)))
        XCTAssertTrue(debounce.shouldRefresh(pathSatisfied: true, now: at(200)))
    }

    func testStartingOfflineThenConnectingRefreshes() {
        var debounce = ReconnectDebounce()
        XCTAssertFalse(debounce.shouldRefresh(pathSatisfied: false, now: at(0)))
        XCTAssertTrue(debounce.shouldRefresh(pathSatisfied: true, now: at(5)))
    }

    func testRepeatedSatisfiedUpdatesDoNotRefresh() {
        var debounce = ReconnectDebounce()
        _ = debounce.shouldRefresh(pathSatisfied: false, now: at(0))
        XCTAssertTrue(debounce.shouldRefresh(pathSatisfied: true, now: at(1)))
        XCTAssertFalse(debounce.shouldRefresh(pathSatisfied: true, now: at(100)))
    }

    func testFlappingWithinTheGapRefreshesOnce() {
        var debounce = ReconnectDebounce(minimumGap: 30)
        _ = debounce.shouldRefresh(pathSatisfied: false, now: at(0))
        XCTAssertTrue(debounce.shouldRefresh(pathSatisfied: true, now: at(1)))
        XCTAssertFalse(debounce.shouldRefresh(pathSatisfied: false, now: at(5)))
        XCTAssertFalse(debounce.shouldRefresh(pathSatisfied: true, now: at(10)))
        XCTAssertFalse(debounce.shouldRefresh(pathSatisfied: false, now: at(15)))
        XCTAssertTrue(debounce.shouldRefresh(pathSatisfied: true, now: at(31)))
    }
}
