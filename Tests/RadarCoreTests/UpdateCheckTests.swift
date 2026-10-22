import XCTest

@testable import RadarCore

final class UpdateCheckTests: XCTestCase {
    private func version(_ string: String) throws -> SemanticVersion {
        try XCTUnwrap(SemanticVersion(string))
    }

    private func release(_ tag: String) -> LatestRelease {
        LatestRelease(
            tagName: tag, htmlUrl: URL(string: "https://github.com/mpellicc/codex-reset-radar/releases/tag/\(tag)")!)
    }

    func testParsesPlainAndPrefixedVersions() throws {
        XCTAssertEqual(try version("1.2.3").description, "1.2.3")
        XCTAssertEqual(try version("v0.10.0").description, "0.10.0")
    }

    func testRejectsAnythingButMajorMinorPatch() {
        for string in ["dev", "", "1.2", "1.2.3.4", "1.2.3-rc1", "v1.2.x", "1..3", "+1.2.3", "1.-2.3", "V1.2.3"] {
            XCTAssertNil(SemanticVersion(string), string)
        }
    }

    func testComparesNumerically() throws {
        XCTAssertLessThan(try version("0.1.0"), try version("0.1.1"))
        XCTAssertLessThan(try version("0.1.9"), try version("0.2.0"))
        XCTAssertLessThan(try version("0.9.0"), try version("0.10.0"))
        XCTAssertLessThan(try version("0.99.99"), try version("1.0.0"))
        XCTAssertEqual(try version("v1.0.0"), try version("1.0.0"))
    }

    func testOffersANewerRelease() throws {
        let update = try XCTUnwrap(UpdateCheck.available(latest: release("v0.2.0"), currentVersion: "0.1.0"))
        XCTAssertEqual(update.version.description, "0.2.0")
        XCTAssertEqual(update.url.absoluteString, "https://github.com/mpellicc/codex-reset-radar/releases/tag/v0.2.0")
    }

    func testOffersNothingForTheSameOrAnOlderRelease() {
        XCTAssertNil(UpdateCheck.available(latest: release("v0.2.0"), currentVersion: "0.2.0"))
        XCTAssertNil(UpdateCheck.available(latest: release("v0.1.9"), currentVersion: "0.2.0"))
    }

    func testOffersNothingWhenAVersionDoesNotParse() {
        XCTAssertNil(UpdateCheck.available(latest: release("v9.0.0"), currentVersion: "dev"))
        XCTAssertNil(UpdateCheck.available(latest: release("nightly"), currentVersion: "0.1.0"))
    }

    func testDecodesLatestRelease() throws {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "latest-release", withExtension: "json", subdirectory: "Fixtures"))
        let latest = try ReleaseClient.decode(Data(contentsOf: url))
        XCTAssertEqual(latest.tagName, "v0.2.0")
        XCTAssertEqual(
            latest.htmlUrl.absoluteString, "https://github.com/mpellicc/codex-reset-radar/releases/tag/v0.2.0")
    }
}
