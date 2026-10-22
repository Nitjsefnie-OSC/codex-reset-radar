import Foundation

public enum Format {
    public static func when(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())
    }

    /// Time of day only, in the user's short style (15:05 or 3:05 PM).
    public static func clock(_ date: Date, locale: Locale = .current, timeZone: TimeZone = .current) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, timeZone: timeZone))
    }

    public static func relative(_ date: Date, to now: Date = Date()) -> String {
        RelativeDateTimeFormatter().localizedString(for: date, relativeTo: now)
    }

    /// Compact countdown for the menu bar: 45m, 9h, 3d, or "due".
    public static func countdown(to date: Date, from now: Date) -> String {
        let seconds = date.timeIntervalSince(now)
        guard seconds > 0 else { return "due" }
        let minutes = Int(seconds / 60)
        if minutes < 60 { return "\(max(minutes, 1))m" }
        let hours = minutes / 60
        if hours < 48 { return "\(hours)h" }
        return "\(hours / 24)d"
    }
}
