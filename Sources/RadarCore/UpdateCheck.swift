import Foundation

/// A `MAJOR.MINOR.PATCH` version, optionally written with a leading `v` as in release tags.
/// Anything else, including prerelease suffixes like `-rc1` and the `dev` of an unbundled build,
/// doesn't parse: releases are always tagged `vX.Y.Z`, so a version that doesn't fit never offers an update.
public struct SemanticVersion: Comparable, Sendable, CustomStringConvertible {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public init?(_ string: String) {
        let trimmed = string.hasPrefix("v") ? string.dropFirst() : Substring(string)
        let parts = trimmed.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return nil }
        let numbers = parts.compactMap { part in
            part.allSatisfy { $0.isASCII && $0.isNumber } ? Int(part) : nil
        }
        guard numbers.count == 3 else { return nil }
        (major, minor, patch) = (numbers[0], numbers[1], numbers[2])
    }

    public var description: String { "\(major).\(minor).\(patch)" }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}

/// The fields of GitHub's `releases/latest` answer that the update check needs.
public struct LatestRelease: Decodable, Sendable {
    public let tagName: String
    public let htmlUrl: URL
}

/// A newer release than the running app, for the panel to offer.
public struct AvailableUpdate: Equatable, Sendable {
    public let version: SemanticVersion
    public let url: URL
}

public enum UpdateCheck {
    /// The update to offer, or nil when the latest release isn't newer or either version doesn't parse.
    public static func available(latest: LatestRelease, currentVersion: String) -> AvailableUpdate? {
        guard let current = SemanticVersion(currentVersion), let newest = SemanticVersion(latest.tagName),
            newest > current
        else { return nil }
        return AvailableUpdate(version: newest, url: latest.htmlUrl)
    }
}

/// Fetches the latest published release from GitHub.
public struct ReleaseClient: Sendable {
    private let url = URL(string: "https://api.github.com/repos/mpellicc/codex-reset-radar/releases/latest")!

    public init() {}

    public func fetchLatest() async throws -> LatestRelease {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("CodexResetRadar/\(Bundle.main.shortVersion)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try Self.decode(data)
    }

    static func decode(_ data: Data) throws -> LatestRelease {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(LatestRelease.self, from: data)
    }
}
