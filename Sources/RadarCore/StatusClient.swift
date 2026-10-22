import Foundation

public struct StatusData: Decodable {
    public let latestReset: Reset?
    public let scheduledReset: ScheduledReset?
    public let stats: Stats
}

public struct Reset: Decodable {
    public let id: String
    public let resetType: String
    public let announcedAt: Date
}

public struct ScheduledReset: Decodable {
    public let id: String
    public let resetType: String
    public let announcedAt: Date
    public let scheduledFor: Date?
    public let text: String
    public let source: Source

    public var typeLabel: String { resetType == "banked" ? "Banked reset" : "Reset" }
}

public struct Source: Decodable {
    public let url: URL?
}

public struct Stats: Decodable {
    public let avgIntervalDays: Double?
}

private struct StatusResponse: Decodable {
    let data: StatusData
}

enum StatusError: LocalizedError {
    case http(Int)

    var errorDescription: String? {
        switch self {
        case .http(let code): return "codex-resets.com returned HTTP \(code)"
        }
    }
}

/// Fetches /api/v1/status, reusing the last response when the server answers 304.
public final class StatusClient {
    private let url = URL(string: "https://codex-resets.com/api/v1/status")!
    private var etag: String?
    private var cached: StatusData?

    public init() {}

    public func fetch() async throws -> StatusData {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("CodexResetRadar/\(Bundle.main.shortVersion)", forHTTPHeaderField: "User-Agent")
        if let etag, cached != nil {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode == 304, let cached { return cached }
        guard http.statusCode == 200 else { throw StatusError.http(http.statusCode) }

        let status = try Self.decode(data)
        etag = http.value(forHTTPHeaderField: "ETag")
        cached = status
        return status
    }

    static func decode(_ data: Data) throws -> StatusData {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = withFraction.date(from: string) ?? plain.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
        }
        return try decoder.decode(StatusResponse.self, from: data).data
    }
}

extension Bundle {
    var shortVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }
}
