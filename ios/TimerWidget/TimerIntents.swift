import AppIntents
import ActivityKit
import WidgetKit
import Foundation

// MARK: - Pause Intent

@available(iOS 17.0, *)
struct PauseTimerIntent: LiveActivityIntent {
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

        // 직접 제어 시도 + Darwin notification 폴백
        let state = TimerActivityAttributes.ContentState(
            isPaused: true,
            accumulatedMs: totalMs,
            timerStartDate: nil
        )
        for activity in Activity<TimerActivityAttributes>.activities {
            await activity.update(.init(state: state, staleDate: nil))
        }
        notifyAppToSyncLiveActivity()

        return .result()
    }
}

// MARK: - Resume Intent

@available(iOS 17.0, *)
struct ResumeTimerIntent: LiveActivityIntent {
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

        // 직접 제어 시도 + Darwin notification 폴백
        let state = TimerActivityAttributes.ContentState(
            isPaused: false,
            accumulatedMs: accumulatedMs,
            timerStartDate: displayDate
        )
        for activity in Activity<TimerActivityAttributes>.activities {
            await activity.update(.init(state: state, staleDate: nil))
        }
        notifyAppToSyncLiveActivity()

        return .result()
    }
}

// MARK: - Complete Intent

@available(iOS 17.0, *)
struct CompleteTimerIntent: LiveActivityIntent {
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
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd"
                let todayStr = df.string(from: Date())
                let completion: [String: Any] = ["categoryId": categoryId, "minutes": minutes, "date": todayStr]
                if let compData = try? JSONSerialization.data(withJSONObject: completion),
                   let compJson = String(data: compData, encoding: .utf8) {
                    sharedDefaults?.set(compJson, forKey: "widget_pending_completion")
                }
            }
        }

        // 위젯 카테고리 todayMinutes 즉시 반영
        if let json = sharedDefaults?.string(forKey: "widget_timer"),
           let data = json.data(using: .utf8),
           let timerDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let catId = timerDict["categoryId"] as? Int ?? -1
            var totalMs2 = timerDict["accumulatedMs"] as? Int ?? 0
            if let dStr = timerDict["timerDisplayDate"] as? String,
               let dDate = parseFlutterDate(dStr) {
                totalMs2 = max(0, Int(-dDate.timeIntervalSinceNow * 1000))
            }
            let mins = totalMs2 / 60000
            if catId != -1 && mins > 0,
               let catsStr = sharedDefaults?.string(forKey: "widget_categories"),
               let catsData = catsStr.data(using: .utf8),
               var cats = try? JSONSerialization.jsonObject(with: catsData) as? [[String: Any]] {
                for i in cats.indices {
                    if cats[i]["id"] as? Int == catId {
                        let current = cats[i]["todayMinutes"] as? Int ?? 0
                        cats[i]["todayMinutes"] = current + mins
                        break
                    }
                }
                if let updatedData = try? JSONSerialization.data(withJSONObject: cats),
                   let updatedStr = String(data: updatedData, encoding: .utf8) {
                    sharedDefaults?.set(updatedStr, forKey: "widget_categories")
                }
            }
        }

        sharedDefaults?.removeObject(forKey: "widget_timer")
        sharedDefaults?.set("complete", forKey: "widget_interaction_action")
        sharedDefaults?.set(true, forKey: "widget_interaction")
        WidgetCenter.shared.reloadAllTimelines()

        // 직접 종료 시도 + Darwin notification 폴백
        for activity in Activity<TimerActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        notifyAppToSyncLiveActivity()

        return .result()
    }
}

// MARK: - Cancel Intent

@available(iOS 17.0, *)
struct CancelTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Cancel Timer"
    static var description = IntentDescription("Cancels the timer without saving")

    func perform() async throws -> some IntentResult {
        sharedDefaults?.removeObject(forKey: "widget_timer")
        sharedDefaults?.set("cancel", forKey: "widget_interaction_action")
        sharedDefaults?.set(true, forKey: "widget_interaction")
        WidgetCenter.shared.reloadAllTimelines()

        // 직접 종료 시도 + Darwin notification 폴백
        for activity in Activity<TimerActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        notifyAppToSyncLiveActivity()

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

// MARK: - Darwin Notification (Fallback)

/// LiveActivityIntent가 격리 프로세스에서 실행될 경우를 대비한 폴백.
/// 앱 프로세스의 Darwin observer가 수신하여 Live Activity를 제어.
private func notifyAppToSyncLiveActivity() {
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFNotificationName("com.studiovanilla.tinylog.liveActivitySync" as CFString),
        nil, nil, true
    )
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
