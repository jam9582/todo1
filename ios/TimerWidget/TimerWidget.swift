import WidgetKit
import SwiftUI

@main
struct TimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimerWidgetSmall()
        TimerWidgetMedium()
        TimerWidgetLarge()
        if #available(iOS 16.1, *) {
            TimerLiveActivity()
        }
    }
}
