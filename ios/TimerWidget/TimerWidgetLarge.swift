import SwiftUI
import WidgetKit

// MARK: - Large Widget Config

struct TimerWidgetLarge: Widget {
    let kind = "TimerWidgetLarge"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimerWidgetProvider()) { entry in
            LargeWidgetView(entry: entry)
        }
        .configurationDisplayName("타이머 위젯 (대)")
        .description("카테고리 4개 2×2 그리드")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let entry: TimerEntry

    var body: some View {
        Group {
            if let timer = entry.timer {
                LargeMeasuringView(timer: timer)
            } else {
                LargeNormalView(entry: entry)
            }
        }
        .if17Available()
    }
}

// MARK: - Normal State (2×2 그리드)

private struct LargeNormalView: View {
    let entry: TimerEntry

    private var cats: [CategoryData?] {
        var arr: [CategoryData?] = entry.categories.prefix(4).map { Optional($0) }
        while arr.count < 4 { arr.append(nil) }
        return arr
    }

    var body: some View {
        ZStack {
            Color.widgetBg

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    cardOrPlaceholder(cats[0])
                    cardOrPlaceholder(cats[1])
                }
                HStack(spacing: 10) {
                    cardOrPlaceholder(cats[2])
                    cardOrPlaceholder(cats[3])
                }
            }
            .padding(12)
        }
    }

    @ViewBuilder
    private func cardOrPlaceholder(_ cat: CategoryData?) -> some View {
        if let cat = cat {
            Link(destination: startURL(for: cat)) {
                LargeCategoryCard(category: cat)
            }
        } else {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.secondary.opacity(0.07))
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary.opacity(0.25))
                )
        }
    }
}

private struct LargeCategoryCard: View {
    let category: CategoryData

    var body: some View {
        VStack(spacing: 8) {
            Text(category.emoji)
                .font(.system(size: 36))
            Text(category.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary.opacity(0.75))
                .lineLimit(1)
            Text(formatMinutes(category.todayMinutes))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}

// MARK: - Measuring State

private struct LargeMeasuringView: View {
    let timer: TimerWidgetData

    private var hasCategory: Bool { timer.categoryId > 0 }

    var body: some View {
        ZStack {
            Color.widgetBg

            VStack(spacing: 10) {
                // 타이머 영역
                VStack(spacing: 6) {
                    if hasCategory {
                        Text(timer.categoryEmoji)
                            .font(.system(size: 36))
                        Text(timer.categoryName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary.opacity(0.75))
                            .lineLimit(1)
                    } else {
                        Image(systemName: "timer")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                    }

                    if timer.isPaused {
                        Text(formatMs(timer.accumulatedMs))
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary.opacity(0.8))
                            .minimumScaleFactor(0.7)
                        Text("일시정지")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else if let refDate = timerReferenceDate(from: timer) {
                        Text(refDate, style: .timer)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary.opacity(0.8))
                            .minimumScaleFactor(0.7)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                        Text("측정 중")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 8)

                // 하단 버튼 행
                HStack(spacing: 8) {
                    if #available(iOS 17.0, *) {
                        if timer.isPaused {
                            Button(intent: ResumeTimerIntent()) {
                                largeActionButton("play.fill", "재개")
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button(intent: PauseTimerIntent()) {
                                largeActionButton("pause.fill", "일시정지")
                            }
                            .buttonStyle(.plain)
                        }
                        Button(intent: CompleteTimerIntent()) {
                            largeActionButton("checkmark", "완료")
                        }
                        .buttonStyle(.plain)
                        Button(intent: CancelTimerIntent()) {
                            largeActionButton("xmark", "취소")
                        }
                        .buttonStyle(.plain)
                    } else {
                        largeActionButton("pause.fill", "일시정지").opacity(0.3)
                        largeActionButton("checkmark", "완료").opacity(0.3)
                        largeActionButton("xmark", "취소").opacity(0.3)
                    }
                }
                .frame(height: 44)
            }
            .padding(12)
        }
    }

    @ViewBuilder
    private func largeActionButton(_ icon: String, _ label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
            Text(label)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Helpers

private func startURL(for cat: CategoryData) -> URL {
    let nameEncoded = cat.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cat.name
    let emojiEncoded = cat.emoji.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cat.emoji
    return URL(string: "tinylog://start?categoryId=\(cat.id)&name=\(nameEncoded)&emoji=\(emojiEncoded)&colorIndex=\(cat.colorIndex)")
        ?? URL(string: "tinylog://start")!
}
