import Foundation

/// Persistence for the id of the latest reset already seen.
public protocol LandedStore {
    func load() -> String?
    func save(_ id: String)
}

/// Decides when a reset has landed: the latest reset changes to a new id, announced beforehand or not.
/// A pending reset that merely disappears was called off, which never reaches this type.
public struct LandingTracker {
    private let store: LandedStore

    public init(store: LandedStore) {
        self.store = store
    }

    /// Returns the reset that just landed, if any, and remembers it so it is reported only once.
    /// The first id ever seen is history, so it is recorded without being reported.
    public func landedIfNew(_ latest: Reset?) -> Reset? {
        guard let latest else { return nil }
        let previous = store.load()
        guard previous != latest.id else { return nil }

        store.save(latest.id)
        return previous == nil ? nil : latest
    }
}
