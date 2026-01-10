//
//  LockedApp.swift
//  Locked
//
//  Created by Brandon Scott on 2025-06-11.
//

import SwiftUI
import UserNotifications

@main
struct LockedApp: App {
    @StateObject private var appLocker = AppLocker()
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var snoozeManager = SnoozeManager()
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    init() {
        // Request notification permissions on launch
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                NSLog("Error requesting notification permissions: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                LockedView()
                    .environmentObject(appLocker)
                    .environmentObject(profileManager)
                    .environmentObject(snoozeManager)
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
    }
}

// Snooze manager to track snooze state across the app
@MainActor
class SnoozeManager: ObservableObject {
    @Published var isSnoozed: Bool = false
    @Published var snoozeTimeRemaining: TimeInterval = 0
    @Published var snoozesUsedToday: Int = 0
    @Published var maxSnoozesPerDay: Int = 5 {
        didSet {
            UserDefaults.standard.set(maxSnoozesPerDay, forKey: maxSnoozesKey)
        }
    }
    @Published var snoozeDuration: TimeInterval = 300 {
        didSet {
            UserDefaults.standard.set(snoozeDuration, forKey: snoozeDurationKey)
        }
    }
    
    private let lastResetDateKey = "lastSnoozeResetDate"
    private let snoozesUsedKey = "snoozesUsedToday"
    private let maxSnoozesKey = "maxSnoozesPerDay"
    private let snoozeDurationKey = "snoozeDuration"
    private let snoozeEndTimeKey = "snoozeEndTime"
    
    init() {
        loadSnoozeData()
        checkAndResetIfNewDay()
        checkForActiveSnooze()
    }
    
    var snoozesRemaining: Int {
        max(0, maxSnoozesPerDay - snoozesUsedToday)
    }
    
    var canSnooze: Bool {
        snoozesRemaining > 0
    }
    
    func startSnooze(duration: TimeInterval? = nil) {
        guard canSnooze else {
            NSLog("⚠️ No snoozes remaining today")
            return
        }
        
        let actualDuration = duration ?? snoozeDuration
        
        isSnoozed = true
        snoozeTimeRemaining = actualDuration
        snoozesUsedToday += 1
        
        // Save the end time to UserDefaults
        let endTime = Date().addingTimeInterval(actualDuration)
        UserDefaults.standard.set(endTime, forKey: snoozeEndTimeKey)
        
        saveSnoozeData()
        NSLog("⏰ Snooze started for \(actualDuration) seconds (\(snoozesRemaining) remaining today)")
    }
    
    func endSnooze() {
        isSnoozed = false
        snoozeTimeRemaining = 0
        UserDefaults.standard.removeObject(forKey: snoozeEndTimeKey)
        NSLog("⏰ Snooze ended")
    }
    
    func updateTimeRemaining(_ time: TimeInterval) {
        snoozeTimeRemaining = time
    }
    
    func resetSnoozesUsed() {
        snoozesUsedToday = 0
        saveSnoozeData()
        NSLog("🔄 Snooze counter manually reset to 0")
    }
    
    private func checkForActiveSnooze() {
        // Check if there's a saved snooze end time
        if let endTime = UserDefaults.standard.object(forKey: snoozeEndTimeKey) as? Date {
            let now = Date()
            let remaining = endTime.timeIntervalSince(now)
            
            if remaining > 0 {
                // Snooze is still active
                isSnoozed = true
                snoozeTimeRemaining = remaining
                NSLog("⏰ Restored active snooze with \(remaining) seconds remaining")
            } else {
                // Snooze expired while app was closed
                UserDefaults.standard.removeObject(forKey: snoozeEndTimeKey)
                NSLog("⏰ Snooze expired while app was closed")
            }
        }
    }
    
    private func checkAndResetIfNewDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastResetDate = UserDefaults.standard.object(forKey: lastResetDateKey) as? Date {
            let lastResetDay = calendar.startOfDay(for: lastResetDate)
            
            if today > lastResetDay {
                // It's a new day, reset the counter
                snoozesUsedToday = 0
                saveSnoozeData()
                NSLog("🔄 New day detected - snooze counter reset to 0")
            }
        } else {
            // First time running
            UserDefaults.standard.set(today, forKey: lastResetDateKey)
        }
        
        // Always update the last reset date to today
        UserDefaults.standard.set(today, forKey: lastResetDateKey)
    }
    
    private func loadSnoozeData() {
        snoozesUsedToday = UserDefaults.standard.integer(forKey: snoozesUsedKey)
        
        // Load max snoozes (default to 5 if not set)
        let savedMaxSnoozes = UserDefaults.standard.integer(forKey: maxSnoozesKey)
        maxSnoozesPerDay = savedMaxSnoozes > 0 ? savedMaxSnoozes : 5
        
        // Load snooze duration (default to 300 seconds / 5 minutes if not set)
        let savedDuration = UserDefaults.standard.double(forKey: snoozeDurationKey)
        snoozeDuration = savedDuration > 0 ? savedDuration : 300
    }
    
    private func saveSnoozeData() {
        UserDefaults.standard.set(snoozesUsedToday, forKey: snoozesUsedKey)
    }
}


