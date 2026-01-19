import Dependencies
import Foundation

public struct UnixTimeClient {
    public var convert: @Sendable (String, UnixTimeMode) async throws -> UnixTimeResult
    public var currentTimestamp: @Sendable () -> TimeInterval
}

public enum UnixTimeMode: String, CaseIterable, Identifiable, Codable {
    case unixToDate = "Unix to Date"
    case dateToUnix = "Date to Unix"

    public var id: Self { self }
}

public struct UnixTimeResult: Equatable, Codable {
    public var localTime: String
    public var localTimeWithTimezone: String
    public var utcISO8601: String
    public var relativeTime: String
    public var unixTimestamp: String
    public var dayOfYear: Int
    public var weekOfYear: Int
    public var isLeapYear: Bool
    public var additionalTimezoneTime: String?

    public init(
        localTime: String,
        localTimeWithTimezone: String,
        utcISO8601: String,
        relativeTime: String,
        unixTimestamp: String,
        dayOfYear: Int,
        weekOfYear: Int,
        isLeapYear: Bool,
        additionalTimezoneTime: String? = nil
    ) {
        self.localTime = localTime
        self.localTimeWithTimezone = localTimeWithTimezone
        self.utcISO8601 = utcISO8601
        self.relativeTime = relativeTime
        self.unixTimestamp = unixTimestamp
        self.dayOfYear = dayOfYear
        self.weekOfYear = weekOfYear
        self.isLeapYear = isLeapYear
        self.additionalTimezoneTime = additionalTimezoneTime
    }
}

extension UnixTimeClient: DependencyKey {
    public static let liveValue = Self(
        convert: { input, mode in
            let date: Date

            switch mode {
            case .unixToDate:
                // Try to parse as Unix timestamp
                guard let timestamp = Double(input.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                    throw UnixTimeError.invalidTimestamp
                }
                // Handle milliseconds (if timestamp > year 3000 in seconds, assume milliseconds)
                if timestamp > 32503680000 {
                    date = Date(timeIntervalSince1970: timestamp / 1000)
                } else {
                    date = Date(timeIntervalSince1970: timestamp)
                }

            case .dateToUnix:
                // Try to parse various date formats
                let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
                if let parsedDate = parseDate(trimmedInput) {
                    date = parsedDate
                } else {
                    throw UnixTimeError.invalidDateFormat
                }
            }

            return createResult(from: date, additionalTimezone: nil)
        },
        currentTimestamp: {
            Date().timeIntervalSince1970
        }
    )
}

private func createResult(from date: Date, additionalTimezone: TimeZone?) -> UnixTimeResult {
    let calendar = Calendar.current

    // Local time formatter
    let localFormatter = DateFormatter()
    localFormatter.dateStyle = .full
    localFormatter.timeStyle = .long
    localFormatter.timeZone = .current

    // Local time with timezone abbreviation
    let localWithTzFormatter = DateFormatter()
    localWithTzFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
    localWithTzFormatter.timeZone = .current

    // UTC ISO 8601
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    isoFormatter.timeZone = TimeZone(identifier: "UTC")

    // Relative time
    let relativeFormatter = RelativeDateTimeFormatter()
    relativeFormatter.unitsStyle = .full

    // Calculate day and week of year
    let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
    let weekOfYear = calendar.component(.weekOfYear, from: date)

    // Check leap year
    let year = calendar.component(.year, from: date)
    let isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)

    // Additional timezone
    var additionalTimezoneTime: String?
    if let tz = additionalTimezone {
        let additionalFormatter = DateFormatter()
        additionalFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        additionalFormatter.timeZone = tz
        additionalTimezoneTime = additionalFormatter.string(from: date)
    }

    return UnixTimeResult(
        localTime: localFormatter.string(from: date),
        localTimeWithTimezone: localWithTzFormatter.string(from: date),
        utcISO8601: isoFormatter.string(from: date),
        relativeTime: relativeFormatter.localizedString(for: date, relativeTo: Date()),
        unixTimestamp: String(Int(date.timeIntervalSince1970)),
        dayOfYear: dayOfYear,
        weekOfYear: weekOfYear,
        isLeapYear: isLeapYear,
        additionalTimezoneTime: additionalTimezoneTime
    )
}

private func parseDate(_ input: String) -> Date? {
    // Try ISO 8601 first
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = isoFormatter.date(from: input) {
        return date
    }

    // Try ISO 8601 without fractional seconds
    isoFormatter.formatOptions = [.withInternetDateTime]
    if let date = isoFormatter.date(from: input) {
        return date
    }

    // Common date formats to try
    let formats = [
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd HH:mm",
        "yyyy-MM-dd",
        "MM/dd/yyyy HH:mm:ss",
        "MM/dd/yyyy HH:mm",
        "MM/dd/yyyy",
        "dd/MM/yyyy HH:mm:ss",
        "dd/MM/yyyy HH:mm",
        "dd/MM/yyyy",
        "yyyy/MM/dd HH:mm:ss",
        "yyyy/MM/dd HH:mm",
        "yyyy/MM/dd",
        "MMM dd, yyyy HH:mm:ss",
        "MMM dd, yyyy HH:mm",
        "MMM dd, yyyy",
        "MMMM dd, yyyy HH:mm:ss",
        "MMMM dd, yyyy HH:mm",
        "MMMM dd, yyyy",
    ]

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")

    for format in formats {
        formatter.dateFormat = format
        if let date = formatter.date(from: input) {
            return date
        }
    }

    return nil
}

extension DependencyValues {
    public var unixTime: UnixTimeClient {
        get { self[UnixTimeClient.self] }
        set { self[UnixTimeClient.self] = newValue }
    }
}

public enum UnixTimeError: LocalizedError {
    case invalidTimestamp
    case invalidDateFormat

    public var errorDescription: String? {
        switch self {
        case .invalidTimestamp:
            return "Invalid Unix timestamp. Please enter a valid number."
        case .invalidDateFormat:
            return "Could not parse the date. Try formats like: 2024-01-15 14:30:00, Jan 15, 2024, or ISO 8601."
        }
    }
}
