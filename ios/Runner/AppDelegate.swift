import Flutter
import UIKit
import ActivityKit

// Runner 타겟용 ActivityAttributes 정의 (TimerWidget 타겟과 동일 구조)
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

@main
@objc class AppDelegate: FlutterAppDelegate {
  private static let appGroupId = "group.com.studiovanilla.tinylog"
  private static let widgetLaunchUrlKey = "widget_launch_url"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Cold start: 위젯 탭으로 앱이 처음 열린 경우 URL을 App Group에 저장
    if let url = launchOptions?[.url] as? URL, url.scheme == "tinylog" {
      saveWidgetLaunchUrl(url)
    }
    GeneratedPluginRegistrant.register(with: self)

    // Live Activity MethodChannel 설정
    let controller = window?.rootViewController as! FlutterViewController
    let liveActivityChannel = FlutterMethodChannel(
      name: "com.example.todo1/liveActivity",
      binaryMessenger: controller.binaryMessenger
    )
    liveActivityChannel.setMethodCallHandler(handleLiveActivity)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Warm start: 앱이 백그라운드에 있을 때 위젯 탭으로 URL이 전달된 경우
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.scheme == "tinylog" {
      saveWidgetLaunchUrl(url)
      return true // Flutter 네비게이션 채널에 전달하지 않음 (라우팅 에러 방지)
    }
    return super.application(app, open: url, options: options)
  }

  private func saveWidgetLaunchUrl(_ url: URL) {
    UserDefaults(suiteName: AppDelegate.appGroupId)?
      .set(url.absoluteString, forKey: AppDelegate.widgetLaunchUrlKey)
  }

  // MARK: - Live Activity MethodChannel Handler

  private func handleLiveActivity(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if #available(iOS 16.2, *) {
      switch call.method {
      case "startActivity":
        guard let args = call.arguments as? [String: Any] else {
          result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
          return
        }
        startLiveActivity(args: args, result: result)
      case "updateActivity":
        guard let args = call.arguments as? [String: Any] else {
          result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
          return
        }
        updateLiveActivity(args: args, result: result)
      case "endActivity":
        endLiveActivity(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    } else {
      result(nil) // iOS 16.1 미만은 무시
    }
  }

  @available(iOS 16.2, *)
  private func startLiveActivity(args: [String: Any], result: @escaping FlutterResult) {
    let categoryId = args["categoryId"] as? Int ?? -1
    let categoryName = args["categoryName"] as? String ?? ""
    let categoryEmoji = args["categoryEmoji"] as? String ?? ""
    let startTimeMs = args["startTime"] as? Int64 ?? Int64(Date().timeIntervalSince1970 * 1000)
    let startDate = Date(timeIntervalSince1970: Double(startTimeMs) / 1000.0)

    // 기존 Live Activity가 있으면 먼저 종료
    for activity in Activity<TimerActivityAttributes>.activities {
      Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }

    let attributes = TimerActivityAttributes(
      categoryId: categoryId,
      categoryName: categoryName,
      categoryEmoji: categoryEmoji
    )
    let state = TimerActivityAttributes.ContentState(
      isPaused: false,
      accumulatedMs: 0,
      timerStartDate: startDate
    )

    do {
      _ = try Activity.request(
        attributes: attributes,
        content: .init(state: state, staleDate: nil),
        pushType: nil
      )
      result(nil)
    } catch {
      result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
    }
  }

  @available(iOS 16.2, *)
  private func updateLiveActivity(args: [String: Any], result: @escaping FlutterResult) {
    let isPaused = args["isPaused"] as? Bool ?? false
    let accumulatedMs = args["accumulatedMs"] as? Int ?? 0

    var timerStartDate: Date? = nil
    if !isPaused, let ms = args["timerStartDate"] as? Int64 {
      timerStartDate = Date(timeIntervalSince1970: Double(ms) / 1000.0)
    }

    let state = TimerActivityAttributes.ContentState(
      isPaused: isPaused,
      accumulatedMs: accumulatedMs,
      timerStartDate: timerStartDate
    )

    Task {
      for activity in Activity<TimerActivityAttributes>.activities {
        await activity.update(.init(state: state, staleDate: nil))
      }
      result(nil)
    }
  }

  @available(iOS 16.2, *)
  private func endLiveActivity(result: @escaping FlutterResult) {
    Task {
      for activity in Activity<TimerActivityAttributes>.activities {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
      result(nil)
    }
  }
}
