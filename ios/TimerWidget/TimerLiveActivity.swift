import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Activity Attributes

struct TimerActivityAttributes: ActivityAttributes {
    /// 타이머 시작 시 고정되는 정보
    let categoryId: Int
    let categoryName: String
    let categoryEmoji: String

    /// 실시간 변동 상태
    struct ContentState: Codable, Hashable {
        let isPaused: Bool
        let accumulatedMs: Int       // paused 시 보여줄 총 경과 ms
        let timerStartDate: Date?    // running 시 Text(.timer) 기준 날짜
    }
}

// MARK: - Live Activity Configuration (iOS 16.1+)

@available(iOS 16.1, *)
struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock Screen / 배너 UI
            LockScreenView(context: context)
                .activityBackgroundTint(Color.widgetBg)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    if !context.attributes.categoryEmoji.isEmpty {
                        Text(context.attributes.categoryEmoji)
                            .font(.system(size: 28))
                    } else {
                        Image(systemName: "timer")
                            .font(.system(size: 22))
                            .foregroundColor(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        if !context.attributes.categoryName.isEmpty {
                            Text(context.attributes.categoryName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary.opacity(0.8))
                                .lineLimit(1)
                        }
                        timerText(state: context.state)
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isPaused {
                        Text("일시정지")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    } else {
                        Text("측정 중")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if #available(iOS 17.0, *) {
                        HStack(spacing: 12) {
                            if context.state.isPaused {
                                Button(intent: ResumeTimerIntent()) {
                                    liveActionButton("play.fill", "재개")
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button(intent: PauseTimerIntent()) {
                                    liveActionButton("pause.fill", "일시정지")
                                }
                                .buttonStyle(.plain)
                            }
                            Button(intent: CompleteTimerIntent()) {
                                liveActionButton("checkmark", "완료")
                            }
                            .buttonStyle(.plain)
                            Button(intent: CancelTimerIntent()) {
                                liveActionButton("xmark", "취소")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 4)
                    }
                }
            } compactLeading: {
                // Compact Leading: 이모지 또는 타이머 아이콘
                if !context.attributes.categoryEmoji.isEmpty {
                    Text(context.attributes.categoryEmoji)
                        .font(.system(size: 14))
                } else {
                    Image(systemName: "timer")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            } compactTrailing: {
                // Compact Trailing: 경과 시간
                timerText(state: context.state)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary)
            } minimal: {
                // Minimal: 타이머 아이콘만
                Image(systemName: "timer")
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - Lock Screen View

@available(iOS 16.1, *)
private struct LockScreenView: View {
    let context: ActivityViewContext<TimerActivityAttributes>

    private var hasCategory: Bool {
        !context.attributes.categoryEmoji.isEmpty
    }

    var body: some View {
        HStack(spacing: 12) {
            // 좌측: 이모지 + 카테고리명
            VStack(spacing: 4) {
                if hasCategory {
                    Text(context.attributes.categoryEmoji)
                        .font(.system(size: 28))
                    Text(context.attributes.categoryName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.75))
                        .lineLimit(1)
                } else {
                    Image(systemName: "timer")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 70)

            // 중앙: 타이머
            VStack(spacing: 2) {
                timerText(state: context.state)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)

                Text(context.state.isPaused ? "일시정지" : "측정 중")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            // 우측: 액션 버튼
            if #available(iOS 17.0, *) {
                VStack(spacing: 6) {
                    if context.state.isPaused {
                        Button(intent: ResumeTimerIntent()) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.primary.opacity(0.7))
                                .frame(width: 32, height: 32)
                                .background(Color.secondary.opacity(0.15))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(intent: PauseTimerIntent()) {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.primary.opacity(0.7))
                                .frame(width: 32, height: 32)
                                .background(Color.secondary.opacity(0.15))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    Button(intent: CompleteTimerIntent()) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Shared Helpers

@available(iOS 16.1, *)
@ViewBuilder
private func timerText(state: TimerActivityAttributes.ContentState) -> some View {
    if state.isPaused {
        Text(formatMs(state.accumulatedMs))
    } else if let startDate = state.timerStartDate {
        Text(startDate, style: .timer)
            .multilineTextAlignment(.center)
    } else {
        Text("0:00")
    }
}

@available(iOS 16.1, *)
@ViewBuilder
private func liveActionButton(_ icon: String, _ label: String) -> some View {
    HStack(spacing: 4) {
        Image(systemName: icon)
            .font(.system(size: 12, weight: .semibold))
        Text(label)
            .font(.system(size: 11, weight: .medium))
    }
    .foregroundColor(.primary.opacity(0.7))
    .frame(maxWidth: .infinity)
    .padding(.vertical, 8)
    .background(Color.secondary.opacity(0.12))
    .cornerRadius(8)
}
