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
        // TEMPORARY: Reset onboarding for testing - remove this line after testing!
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        
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
    
    private let maxSnoozesPerDay = 5
    private let lastResetDateKey = "lastSnoozeResetDate"
    private let snoozesUsedKey = "snoozesUsedToday"
    
    init() {
        loadSnoozeData()
        checkAndResetIfNewDay()
    }
    
    var snoozesRemaining: Int {
        max(0, maxSnoozesPerDay - snoozesUsedToday)
    }
    
    var canSnooze: Bool {
        snoozesRemaining > 0
    }
    
    func startSnooze(duration: TimeInterval = 300) {
        guard canSnooze else {
            NSLog("⚠️ No snoozes remaining today")
            return
        }
        
        isSnoozed = true
        snoozeTimeRemaining = duration
        snoozesUsedToday += 1
        saveSnoozeData()
        NSLog("⏰ Snooze started for \(duration) seconds (\(snoozesRemaining) remaining today)")
    }
    
    func endSnooze() {
        isSnoozed = false
        snoozeTimeRemaining = 0
        NSLog("⏰ Snooze ended")
    }
    
    func updateTimeRemaining(_ time: TimeInterval) {
        snoozeTimeRemaining = time
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
    }
    
    private func saveSnoozeData() {
        UserDefaults.standard.set(snoozesUsedToday, forKey: snoozesUsedKey)
    }
}


