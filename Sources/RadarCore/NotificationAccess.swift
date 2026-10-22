/// What the system currently allows this app to do with notifications.
/// It mirrors the fields of `UNNotificationSettings` that matter, so the decision can be tested.
public struct NotificationAccess: Equatable, Sendable {
    public enum Authorization: Sendable {
        case notDetermined
        case denied
        case authorized
        case provisional
        case ephemeral
    }

    public enum Setting: Sendable {
        case notSupported
        case disabled
        case enabled
    }

    public let authorization: Authorization
    public let alerts: Setting

    public init(authorization: Authorization, alerts: Setting) {
        self.authorization = authorization
        self.alerts = alerts
    }

    /// True when resets would go unnoticed and the panel should say so: notifications were denied,
    /// or they are allowed but alerts are switched off. Until the user has been asked there is
    /// nothing to warn about.
    public var isOff: Bool {
        switch authorization {
        case .denied: return true
        case .notDetermined: return false
        case .authorized, .provisional, .ephemeral: return alerts == .disabled
        }
    }
}
