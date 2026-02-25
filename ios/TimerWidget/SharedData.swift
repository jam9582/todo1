import Foundation
import SwiftUI
import WidgetKit

// MARK: - App Group
let kAppGroup = "group.com.example.todo1"
var sharedDefaults: UserDefaults? { UserDefaults(suiteName: kAppGroup) }

// MARK: - Data Models

struct CategoryData: Codable, Identifiable {
    let id: Int
    let name: String
    let emoji: String
    let colorIndex: Int
    let todayMinutes: Int
}

struct TimerWidgetData: Codable {
    let categoryId: Int
    let categoryName: String
    let categoryEmoji: String
    let colorIndex: Int
    let originalStartTime: String
    var isPaused: Bool
    var timerDisplayDate: String?  // running 상태: Text(.timer) 기준 날짜
    var accumulatedMs: Int         // paused 상태: 총 경과 ms
}

// MARK: - Widget Timeline Entry

struct TimerEntry: TimelineEntry {
    let date: Date
    let categories: [CategoryData]
    let timer: TimerWidgetData?
    let smallPage: Int
    let mediumPage: Int

    static var placeholder: TimerEntry {
        TimerEntry(date: Date(), categories: [], timer: nil, smallPage: 0, mediumPage: 0)
    }

    static func load(date: Date = Date()) -> TimerEntry {
        let d = sharedDefaults

        var categories: [CategoryData] = []
        if let json = d?.string(forKey: "widget_categories"),
           let data = json.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([CategoryData].self, from: data) {
            categories = decoded
        }

        var timer: TimerWidgetData? = nil
        if let json = d?.string(forKey: "widget_timer"),
           let data = json.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(TimerWidgetData.self, from: data) {
            timer = decoded
        }

        let smallPage = d?.integer(forKey: "widget_small_page") ?? 0
        let mediumPage = d?.integer(forKey: "widget_medium_page") ?? 0
        let catCount = categories.count

        return TimerEntry(
            date: date,
            categories: categories,
            timer: timer,
            smallPage: catCount > 0 ? min(smallPage, catCount - 1) : 0,
            mediumPage: catCount > 1 ? min(mediumPage, (catCount - 1) / 2) : 0
        )
    }
}

// MARK: - Colors

extension Color {
    static let widgetBg = Color(hex: "#FFFBF5")
    static let widgetNeutral = Color(hex: "#D8D4CF")
    static let categoryColors: [Color] = [
        Color(hex: "#E8A87C"),  // 웜 오렌지
        Color(hex: "#85C1E9"),  // 소프트 블루
        Color(hex: "#82E0AA"),  // 소프트 그린
        Color(hex: "#C39BD3"),  // 소프트 퍼플
    ]

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: 1)
    }
}

func colorForIndex(_ index: Int) -> Color {
    guard index >= 0 && index < Color.categoryColors.count else { return .widgetNeutral }
    return Color.categoryColors[index]
}

// MARK: - Helpers

func formatMinutes(_ minutes: Int) -> String {
    if minutes == 0 { return "0m" }
    let h = minutes / 60
    let m = minutes % 60
    if h > 0 && m > 0 { return "\(h)h \(m)m" }
    if h > 0 { return "\(h)h" }
    return "\(m)m"
}

func formatMs(_ ms: Int) -> String {
    let totalSec = ms / 1000
    let h = totalSec / 3600
    let m = (totalSec % 3600) / 60
    let s = totalSec % 60
    if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
    return String(format: "%d:%02d", m, s)
}

/// Flutter의 DateTime.toIso8601String() 결과를 파싱 (로컬 타임존 또는 UTC Z)
func parseFlutterDate(_ isoString: String) -> Date? {
    // ISO8601 with Z (UTC)
    let utcFormatter = ISO8601DateFormatter()
    utcFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = utcFormatter.date(from: isoString) { return d }

    utcFormatter.formatOptions = [.withInternetDateTime]
    if let d = utcFormatter.date(from: isoString) { return d }

    // Local time without timezone (Dart default)
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    for fmt in ["yyyy-MM-dd'T'HH:mm:ss.SSSSSS", "yyyy-MM-dd'T'HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss"] {
        df.dateFormat = fmt
        if let d = df.date(from: isoString) { return d }
    }
    return nil
}

/// running 타이머의 경과 시간 기준 날짜 (timerDisplayDate → Date)
func timerReferenceDate(from timerData: TimerWidgetData) -> Date? {
    guard let displayDateStr = timerData.timerDisplayDate else { return nil }
    return parseFlutterDate(displayDateStr)
}

// MARK: - Widget Timeline Provider

struct TimerWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimerEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (TimerEntry) -> Void) {
        completion(.load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerEntry>) -> Void) {
        let entry = TimerEntry.load()
        // 1시간 후 자동 새로고침 (App Intent가 버튼 누를 때마다 즉시 reload함)
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}
