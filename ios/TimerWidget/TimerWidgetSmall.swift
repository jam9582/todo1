import SwiftUI
import WidgetKit

// MARK: - Small Widget Config

struct TimerWidgetSmall: Widget {
    let kind = "TimerWidgetSmall"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimerWidgetProvider()) { entry in
            SmallWidgetView(entry: entry)
        }
        .configurationDisplayName("타이머 위젯 (소)")
        .description("카테고리별 시간 측정")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: TimerEntry

    var body: some View {
        Group {
            if let timer = entry.timer {
                SmallMeasuringView(timer: timer)
            } else {
                SmallNormalView(entry: entry)
            }
        }
        .if17Available()
    }
}

// MARK: - Normal State (카테고리 카드)

private struct SmallNormalView: View {
    let entry: TimerEntry

    private var category: CategoryData? {
        guard !entry.categories.isEmpty else { return nil }
        return entry.categories[entry.smallPage]
    }

    private var totalCategories: Int { min(entry.categories.count, 4) }

    var body: some View {
        ZStack {
            Color.widgetBg

            if let cat = category {
                VStack(spacing: 0) {
                    // 카테고리 카드 (탭하면 앱 열기)
                    Link(destination: startURL(for: cat)) {
                        CategoryCardSmall(category: cat)
                    }

                    // 하단 네비게이션 (◀ 인디케이터 ▶)
                    if totalCategories > 1 {
                        HStack(spacing: 6) {
                            if #available(iOS 17.0, *) {
                                Button(intent: PrevPageSmallIntent()) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary.opacity(0.3))
                            }

                            // 점 인디케이터
                            HStack(spacing: 4) {
                                ForEach(0..<totalCategories, id: \.self) { i in
                                    Circle()
                                        .fill(i == entry.smallPage
                                              ? colorForIndex(cat.colorIndex)
                                              : Color.secondary.opacity(0.25))
                                        .frame(width: 5, height: 5)
                                }
                            }

                            if #available(iOS 17.0, *) {
                                Button(intent: NextPageSmallIntent()) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary.opacity(0.3))
                            }
                        }
                        .padding(.bottom, 8)
                    }
                }
            } else {
                // 카테고리 없음
                VStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    Text("카테고리 추가")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

private struct CategoryCardSmall: View {
    let category: CategoryData

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(colorForIndex(category.colorIndex))
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .overlay(
                VStack(spacing: 4) {
                    Text(category.emoji)
                        .font(.system(size: 28))
                    Text(category.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.black.opacity(0.75))
                        .lineLimit(1)
                    Text(formatMinutes(category.todayMinutes))
                        .font(.system(size: 11))
                        .foregroundColor(.black.opacity(0.55))
                }
                .padding(.top, 12)
            )
    }
}

// MARK: - Measuring State (타이머 진행 중)

private struct SmallMeasuringView: View {
    let timer: TimerWidgetData

    private var cardColor: Color { colorForIndex(timer.colorIndex) }
    private var hasCategory: Bool { timer.categoryId > 0 }

    var body: some View {
        ZStack {
            Color.widgetBg

            VStack(spacing: 0) {
                // 타이머 카드
                RoundedRectangle(cornerRadius: 12)
                    .fill(cardColor)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    .overlay(
                        VStack(spacing: 3) {
                            if hasCategory {
                                Text(timer.categoryEmoji)
                                    .font(.system(size: 20))
                                Text(timer.categoryName)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.black.opacity(0.7))
                                    .lineLimit(1)
                            } else {
                                Image(systemName: "timer")
                                    .font(.system(size: 20))
                                    .foregroundColor(.black.opacity(0.6))
                            }

                            // 타이머 표시
                            if timer.isPaused {
                                Text(formatMs(timer.accumulatedMs))
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black.opacity(0.8))
                            } else if let refDate = timerReferenceDate(from: timer) {
                                Text(refDate, style: .timer)
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black.opacity(0.8))
                            }
                        }
                        .padding(.top, 12)
                    )

                // 액션 버튼
                HStack(spacing: 8) {
                    if #available(iOS 17.0, *) {
                        if timer.isPaused {
                            Button(intent: ResumeTimerIntent()) {
                                actionIcon("play.fill")
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button(intent: PauseTimerIntent()) {
                                actionIcon("pause.fill")
                            }
                            .buttonStyle(.plain)
                        }
                        Button(intent: CompleteTimerIntent()) {
                            actionIcon("checkmark")
                        }
                        .buttonStyle(.plain)
                        Button(intent: CancelTimerIntent()) {
                            actionIcon("xmark")
                        }
                        .buttonStyle(.plain)
                    } else {
                        actionIcon("pause.fill").opacity(0.3)
                        actionIcon("checkmark").opacity(0.3)
                        actionIcon("xmark").opacity(0.3)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    private func actionIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.secondary)
            .frame(width: 28, height: 22)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(6)
    }
}

// MARK: - Helpers

private func startURL(for cat: CategoryData) -> URL {
    let nameEncoded = cat.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cat.name
    let emojiEncoded = cat.emoji.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cat.emoji
    return URL(string: "todo1://start?categoryId=\(cat.id)&name=\(nameEncoded)&emoji=\(emojiEncoded)&colorIndex=\(cat.colorIndex)")
        ?? URL(string: "todo1://start")!
}

// MARK: - iOS 17 Background Helper

extension View {
    @ViewBuilder
    func if17Available() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) {
                Color.widgetBg
            }
        } else {
            self
        }
    }
}
