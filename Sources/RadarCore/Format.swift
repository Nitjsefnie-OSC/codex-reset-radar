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

    /// How long is left, split the way the countdown shows it.
    private enum Remaining {
        case due
        case minutes(Int)
        case hoursAndMinutes(Int, Int)
        case hours(Int)
        case days(Int)

        init(to date: Date, from now: Date) {
            let seconds = date.timeIntervalSince(now)
            guard seconds > 0 else {
                self = .due
                return
            }
            let minutes = Int(seconds / 60)
            let hours = minutes / 60
            if minutes < 60 {
                self = .minutes(max(minutes, 1))
            } else if hours < 2 {
                self = .hoursAndMinutes(hours, minutes % 60)
            } else if hours < 48 {
                self = .hours(hours)
            } else {
                self = .days(hours / 24)
            }
        }
    }

    /// Compact countdown for the menu bar: 45m, 1h 59m, 9h, 3d, or "due".
    public static func countdown(to date: Date, from now: Date) -> String {
        switch Remaining(to: date, from: now) {
        case .due: return "due"
        case .minutes(let m): return "\(m)m"
        case .hoursAndMinutes(let h, let m): return "\(h)h \(m)m"
        case .hours(let h): return "\(h)h"
        case .days(let d): return "\(d)d"
        }
    }

    /// The same countdown spelled out for VoiceOver: 45 minutes, 1 hour 59 minutes, 9 hours, 3 days, or "due".
    public static func spokenCountdown(to date: Date, from now: Date) -> String {
        func unit(_ count: Int, _ name: String) -> String { "\(count) \(name)\(count == 1 ? "" : "s")" }
        switch Remaining(to: date, from: now) {
        case .due: return "due"
        case .minutes(let m): return unit(m, "minute")
        case .hoursAndMinutes(let h, 0): return unit(h, "hour")
        case .hoursAndMinutes(let h, let m): return "\(unit(h, "hour")) \(unit(m, "minute"))"
        case .hours(let h): return unit(h, "hour")
        case .days(let d): return unit(d, "day")
        }
    }
}
