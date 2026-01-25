//
//  HockeyTimerActivity.swift
//  HockeyTimer
//
//  Shared ActivityAttributes for Live Activity / Dynamic Island
//

import ActivityKit
import SwiftUI

struct HockeyTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingTime: Int
        var intervalsCompleted: Int
        var totalIntervals: Int
    }

    var interval: Int
    var totalTime: Int
}
