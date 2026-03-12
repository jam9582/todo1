import ActivityKit
import Foundation

/// Live Activity에서 사용하는 타이머 속성 정의.
/// Runner(앱)와 TimerWidget(Extension) 양쪽 타겟에 포함되어야 함.
struct TimerActivityAttributes: ActivityAttributes {
    let categoryId: Int
    let categoryName: String
    let categoryEmoji: String

    struct ContentState: Codable, Hashable {
        let isPaused: Bool
        let accumulatedMs: Int
        let timerStartDate: Date?
    }
}
