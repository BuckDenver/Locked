//
//  SnoozeActivityAttributes.swift
//  Locked
//
//  Created by Brandon Scott on 2026-01-10.
//

import ActivityKit
import Foundation

/// Attributes for the snooze Live Activity
struct SnoozeActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // The date when the snooze will end
        var endDate: Date
        
        // Number of snoozes remaining today
        var snoozesRemaining: Int
    }
    
    // Fixed attributes that don't change during the activity
    var snoozeDuration: TimeInterval
}
