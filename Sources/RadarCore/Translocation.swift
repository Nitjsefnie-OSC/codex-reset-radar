import Foundation

public enum Translocation {
    /// True when macOS App Translocation is running the app from a randomized read-only copy,
    /// as it does for a quarantined app launched from Downloads. That copy lives under
    /// `.../AppTranslocation/<UUID>/d/`. `SecTranslocateIsTranslocatedURL` would answer this
    /// directly, but it is private API, so the path is checked instead.
    public static func isTranslocated(bundleURL: URL) -> Bool {
        bundleURL.pathComponents.contains("AppTranslocation")
    }
}
