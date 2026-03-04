import Flutter
import UIKit

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
}
