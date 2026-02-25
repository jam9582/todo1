import AppIntents
import WidgetKit
import Foundation

// MARK: - Pause Intent

@available(iOS 17.0, *)
struct PauseTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause Timer"
    static var description = IntentDescription("Pauses the running timer")

    func perform() async throws -> some IntentResult {
        guard let json = sharedDefaults?.string(forKey: "widget_timer"),
              let data = json.data(using: .utf8),
              var timerDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return .result() }

        // 현재까지 경과 ms 계산
        var totalMs = timerDict["accumulatedMs"] as? Int ?? 0
        if let displayDateStr = timerDict["timerDisplayDate"] as? String,
           let displayDate = parseFlutterDate(displayDateStr) {
            totalMs = max(0, Int(-displayDate.timeIntervalSinceNow * 1000))
        }

        timerDict["isPaused"] = true
        timerDict["accumulatedMs"] = totalMs
        timerDict.removeValue(forKey: "timerDisplayDate")

        if let newData = try? JSONSerialization.data(withJSONObject: timerDict),
           let newJson = String(data: newData, encoding: .utf8) {
            sharedDefaults?.set(newJson, forKey: "widget_timer")
        }

        sharedDefaults?.set("pause", forKey: "widget_interaction_action")
        sharedDefaults?.set(true, forKey: "widget_interaction")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Resume Intent

@available(iOS 17.0, *)
struct ResumeTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Resume Timer"
    static var description = IntentDescription("Resumes the paused timer")

    func perform() async throws -> some IntentResult {
        guard let json = sharedDefaults?.string(forKey: "widget_timer"),
              let data = json.data(using: .utf8),
              var timerDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return .result() }

        let accumulatedMs = timerDict["accumulatedMs"] as? Int ?? 0
        let displayDate = Date().addingTimeInterval(-Double(accumulatedMs) / 1000.0)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        timerDict["isPaused"] = false
        timerDict["timerDisplayDate"] = formatter.string(from: displayDate)

        if let newData = try? JSONSerialization.data(withJSONObject: timerDict),
           let newJson = String(data: newData, encoding: .utf8) {
            sharedDefaults?.set(newJson, forKey: "widget_timer")
        }

        sharedDefaults?.set("resume", forKey: "widget_interaction_action")
        sharedDefaults?.set(true, forKey: "widget_interaction")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Complete Intent

@available(iOS 17.0, *)
struct CompleteTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Timer"
    static var description = IntentDescription("Completes the timer and saves the record")

    func perform() async throws -> some IntentResult {
        if let json = sharedDefaults?.string(forKey: "widget_timer"),
           let data = json.data(using: .utf8),
           let timerDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

            var totalMs = timerDict["accumulatedMs"] as? Int ?? 0
            if let displayDateStr = timerDict["timerDisplayDate"] as? String,
               let displayDate = parseFlutterDate(displayDateStr) {
                totalMs = max(0, Int(-displayDate.timeIntervalSinceNow * 1000))
            }
            let minutes = totalMs / 60000
            let categoryId = timerDict["categoryId"] as? Int ?? -1

            if minutes > 0 {
                let completion: [String: Any] = ["categoryId": categoryId, "minutes": minutes]
                if let compData = try? JSONSerialization.data(withJSONObject: completion),
                   let compJson = String(data: compData, encoding: .utf8) {
                    sharedDefaults?.set(compJson, forKey: "widget_pending_completion")
                }
            }
        }

        sharedDefaults?.removeObject(forKey: "widget_timer")
        sharedDefaults?.set("complete", forKey: "widget_interaction_action")
        sharedDefaults?.set(true, forKey: "widget_interaction")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Cancel Intent

@available(iOS 17.0, *)
struct CancelTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Cancel Timer"
    static var description = IntentDescription("Cancels the timer without saving")

    func perform() async throws -> some IntentResult {
        sharedDefaults?.removeObject(forKey: "widget_timer")
        sharedDefaults?.set("cancel", forKey: "widget_interaction_action")
        sharedDefaults?.set(true, forKey: "widget_interaction")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Page Navigation Intents (Small)

@available(iOS 17.0, *)
struct PrevPageSmallIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous (Small)"

    func perform() async throws -> some IntentResult {
        let count = categoryCount()
        guard count > 1 else { return .result() }
        let current = sharedDefaults?.integer(forKey: "widget_small_page") ?? 0
        sharedDefaults?.set((current - 1 + count) % count, forKey: "widget_small_page")
        WidgetCenter.shared.reloadTimelines(ofKind: "TimerWidgetSmall")
        return .result()
    }
}

@available(iOS 17.0, *)
struct NextPageSmallIntent: AppIntent {
    static var title: LocalizedStringResource = "Next (Small)"

    func perform() async throws -> some IntentResult {
        let count = categoryCount()
        guard count > 1 else { return .result() }
        let current = sharedDefaults?.integer(forKey: "widget_small_page") ?? 0
        sharedDefaults?.set((current + 1) % count, forKey: "widget_small_page")
        WidgetCenter.shared.reloadTimelines(ofKind: "TimerWidgetSmall")
        return .result()
    }
}

// MARK: - Page Navigation Intents (Medium)

@available(iOS 17.0, *)
struct PrevPageMediumIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous (Medium)"

    func perform() async throws -> some IntentResult {
        let pages = mediumPageCount()
        guard pages > 1 else { return .result() }
        let current = sharedDefaults?.integer(forKey: "widget_medium_page") ?? 0
        sharedDefaults?.set((current - 1 + pages) % pages, forKey: "widget_medium_page")
        WidgetCenter.shared.reloadTimelines(ofKind: "TimerWidgetMedium")
        return .result()
    }
}

@available(iOS 17.0, *)
struct NextPageMediumIntent: AppIntent {
    static var title: LocalizedStringResource = "Next (Medium)"

    func perform() async throws -> some IntentResult {
        let pages = mediumPageCount()
        guard pages > 1 else { return .result() }
        let current = sharedDefaults?.integer(forKey: "widget_medium_page") ?? 0
        sharedDefaults?.set((current + 1) % pages, forKey: "widget_medium_page")
        WidgetCenter.shared.reloadTimelines(ofKind: "TimerWidgetMedium")
        return .result()
    }
}

// MARK: - Private Helpers

private func categoryCount() -> Int {
    guard let json = sharedDefaults?.string(forKey: "widget_categories"),
          let data = json.data(using: .utf8),
          let arr = try? JSONDecoder().decode([CategoryData].self, from: data)
    else { return 0 }
    return min(arr.count, 4)
}

private func mediumPageCount() -> Int {
    let count = categoryCount()
    // 2개씩 표시 (비중첩): [0,1], [2,3] → 최대 2페이지
    return max(1, (count + 1) / 2)
}
