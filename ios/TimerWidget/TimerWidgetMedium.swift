import SwiftUI
import WidgetKit

// MARK: - Medium Widget Config

struct TimerWidgetMedium: Widget {
    let kind = "TimerWidgetMedium"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimerWidgetProvider()) { entry in
            MediumWidgetView(entry: entry)
        }
        .configurationDisplayName("타이머 위젯 (중)")
        .description("카테고리 2개 표시")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: TimerEntry

    var body: some View {
        Group {
            if let timer = entry.timer {
                MediumMeasuringView(timer: timer)
            } else {
                MediumNormalView(entry: entry)
            }
        }
        .if17Available()
    }
}

// MARK: - Normal State

private struct MediumNormalView: View {
    let entry: TimerEntry

    // 현재 페이지에서 보이는 카테고리 2개
    private var visibleCategories: [CategoryData] {
        let cats = entry.categories
        guard !cats.isEmpty else { return [] }
        let start = entry.mediumPage * 2
        let end = min(start + 2, cats.count)
        return Array(cats[start..<end])
    }

    private var totalPages: Int {
        let count = min(entry.categories.count, 4)
        return max(1, (count + 1) / 2)
    }

    var body: some View {
        ZStack {
            Color.widgetBg

            if entry.categories.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("카테고리를 추가하세요")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 0) {
                    // 카드 2개 나란히
                    HStack(spacing: 8) {
                        ForEach(visibleCategories) { cat in
                            Link(destination: startURL(for: cat)) {
                                MediumCategoryCard(category: cat)
                            }
                        }
                        // 카테고리가 1개뿐인 페이지면 빈 공간
                        if visibleCategories.count == 1 {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.08))
                                .overlay(
                                    Image(systemName: "plus")
                                        .foregroundColor(.secondary.opacity(0.3))
                                )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 6)

                    // 하단 네비게이션
                    if totalPages > 1 {
                        HStack(spacing: 10) {
                            if #available(iOS 17.0, *) {
                                Button(intent: PrevPageMediumIntent()) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary.opacity(0.3))
                            }

                            HStack(spacing: 5) {
                                ForEach(0..<totalPages, id: \.self) { i in
                                    let cat = visibleCategories.first
                                    Circle()
                                        .fill(i == entry.mediumPage
                                              ? colorForIndex(cat?.colorIndex ?? 0)
                                              : Color.secondary.opacity(0.25))
                                        .frame(width: 5, height: 5)
                                }
                            }

                            if #available(iOS 17.0, *) {
                                Button(intent: NextPageMediumIntent()) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary.opacity(0.3))
                            }
                        }
                        .padding(.bottom, 10)
                    }
                }
            }
        }
    }
}

private struct MediumCategoryCard: View {
    let category: CategoryData

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(colorForIndex(category.colorIndex))
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                VStack(spacing: 5) {
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
            )
    }
}

// MARK: - Measuring State

private struct MediumMeasuringView: View {
    let timer: TimerWidgetData

    private var cardColor: Color { colorForIndex(timer.colorIndex) }
    private var hasCategory: Bool { timer.categoryId > 0 }

    var body: some View {
        ZStack {
            Color.widgetBg

            HStack(spacing: 12) {
                // 왼쪽: 타이머 카드
                RoundedRectangle(cornerRadius: 12)
                    .fill(cardColor)
                    .overlay(
                        VStack(spacing: 6) {
                            if hasCategory {
                                Text(timer.categoryEmoji)
                                    .font(.system(size: 28))
                                Text(timer.categoryName)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.black.opacity(0.7))
                                    .lineLimit(1)
                            } else {
                                Image(systemName: "timer")
                                    .font(.system(size: 26))
                                    .foregroundColor(.black.opacity(0.6))
                            }

                            if timer.isPaused {
                                Text(formatMs(timer.accumulatedMs))
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black.opacity(0.8))
                            } else if let refDate = timerReferenceDate(from: timer) {
                                Text(refDate, style: .timer)
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black.opacity(0.8))
                            }
                        }
                    )

                // 오른쪽: 버튼 컬럼
                VStack(spacing: 10) {
                    if #available(iOS 17.0, *) {
                        if timer.isPaused {
                            Button(intent: ResumeTimerIntent()) {
                                mediumActionButton("play.fill", "재개")
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button(intent: PauseTimerIntent()) {
                                mediumActionButton("pause.fill", "일시정지")
                            }
                            .buttonStyle(.plain)
                        }
                        Button(intent: CompleteTimerIntent()) {
                            mediumActionButton("checkmark", "완료")
                        }
                        .buttonStyle(.plain)
                        Button(intent: CancelTimerIntent()) {
                            mediumActionButton("xmark", "취소")
                        }
                        .buttonStyle(.plain)
                    } else {
                        mediumActionButton("pause.fill", "일시정지").opacity(0.3)
                        mediumActionButton("checkmark", "완료").opacity(0.3)
                        mediumActionButton("xmark", "취소").opacity(0.3)
                    }
                }
                .frame(width: 80)
            }
            .padding(12)
        }
    }

    @ViewBuilder
    private func mediumActionButton(_ icon: String, _ label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
            Text(label)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Helpers

private func startURL(for cat: CategoryData) -> URL {
    let nameEncoded = cat.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cat.name
    let emojiEncoded = cat.emoji.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cat.emoji
    return URL(string: "todo1://start?categoryId=\(cat.id)&name=\(nameEncoded)&emoji=\(emojiEncoded)&colorIndex=\(cat.colorIndex)")
        ?? URL(string: "todo1://start")!
}
