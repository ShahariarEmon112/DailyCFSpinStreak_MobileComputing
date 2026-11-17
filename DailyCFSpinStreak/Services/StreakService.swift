//
//  StreakService.swift
//  DailyCFSpinStreak
//
//  Pure streak math — no network, no Firebase, easy to test and explain.
//
//  A "day key" is a date written as "yyyy-MM-dd" in the USER'S LOCAL time zone.
//  Example: an Accepted submission at 2026-11-13 01:30 Dhaka time (UTC+6) is
//  2026-11-12 19:30 UTC, but for the user it was solved on "2026-11-13".
//  Using the local date makes the streak match the user's own calendar.
//

import Foundation

enum StreakService {
    /// One shared formatter (creating DateFormatters is slow).
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")   // fixed format, ignores user settings
        formatter.timeZone = TimeZone.autoupdatingCurrent       // the user's local time zone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static var calendar: Calendar { Calendar.current }

    /// Date → "2026-11-13" (local time zone).
    static func dayKey(for date: Date) -> String {
        dayFormatter.string(from: date)
    }

    /// "2026-11-13" → Date (midnight, local time zone).
    static func date(fromDayKey key: String) -> Date? {
        dayFormatter.date(from: key)
    }

    /// Number of consecutive verified days ending today.
    /// If today is not solved YET, the streak is still alive if yesterday was solved
    /// (the user still has until midnight to keep it going).
    static func currentStreak(verifiedDays: [String], today: Date = Date()) -> Int {
        let days = Set(verifiedDays)
        var day = today

        if !days.contains(dayKey(for: day)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }

        // Walk backwards one day at a time while each day is in the set.
        var streak = 0
        while days.contains(dayKey(for: day)) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previousDay
        }
        return streak
    }

    /// Longest run of consecutive verified days ever.
    static func longestStreak(verifiedDays: [String]) -> Int {
        // "yyyy-MM-dd" strings sort in date order, so sorting the strings is enough.
        let dates = Set(verifiedDays).sorted().compactMap { date(fromDayKey: $0) }

        var longest = 0
        var currentRun = 0
        var lastDate: Date?

        for date in dates {
            if let lastDate,
               let nextDay = calendar.date(byAdding: .day, value: 1, to: lastDate),
               calendar.isDate(nextDay, inSameDayAs: date) {
                currentRun += 1          // continues the run
            } else {
                currentRun = 1           // gap → a new run starts
            }
            longest = max(longest, currentRun)
            lastDate = date
        }
        return longest
    }
}
