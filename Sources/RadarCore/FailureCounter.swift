/// Counts consecutive failed polls, to decide when the menu bar icon should show the offline state.
public struct FailureCounter: Sendable {
    private let threshold: Int
    public private(set) var count = 0

    /// One failed poll is a blip; `threshold` in a row means we really can't reach the source.
    public init(threshold: Int = 2) {
        self.threshold = threshold
    }

    public var isOffline: Bool { count >= threshold }

    public mutating func recordSuccess() {
        count = 0
    }

    public mutating func recordFailure() {
        count += 1
    }
}
