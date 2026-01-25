//
//  HockeyTimerWidgetLiveActivity.swift
//  HockeyTimerWidget
//
//  Created by Sergey Pustovalov on 25/01/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct HockeyTimerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HockeyTimerAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: "hockey.puck.fill")
                            .foregroundColor(.orange)
                        Text("Shift \(context.state.intervalsCompleted + 1)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.intervalsCompleted)/\(context.state.totalIntervals)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(formatTime(context.state.remainingTime))
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: progress(context: context))
                        .tint(.orange)
                }
            } compactLeading: {
                Image(systemName: "hockey.puck.fill")
                    .foregroundColor(.orange)
            } compactTrailing: {
                Text(formatTime(context.state.remainingTime))
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            } minimal: {
                Image(systemName: "hockey.puck.fill")
                    .foregroundColor(.orange)
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }

    private func progress(context: ActivityViewContext<HockeyTimerAttributes>) -> Double {
        let elapsed = context.attributes.totalTime - context.state.remainingTime
        return Double(elapsed) / Double(context.attributes.totalTime)
    }
}

struct LockScreenView: View {
    let context: ActivityViewContext<HockeyTimerAttributes>

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "hockey.puck.fill")
                        .foregroundColor(.orange)
                    Text("Hockey Timer")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                Text("Shift \(context.state.intervalsCompleted + 1) of \(context.state.totalIntervals)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(formatTime(context.state.remainingTime))
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.8))
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }
}

#Preview("Notification", as: .content, using: HockeyTimerAttributes(interval: 60, totalTime: 900)) {
    HockeyTimerWidgetLiveActivity()
} contentStates: {
    HockeyTimerAttributes.ContentState(remainingTime: 540, intervalsCompleted: 6, totalIntervals: 15)
}
