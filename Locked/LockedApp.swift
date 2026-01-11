//
//  LockedApp.swift
//  Locked
//
//  Created by Brandon Scott on 2025-06-11.
//

import SwiftUI
import UserNotifications

// Notification delegate to show notifications even when app is in foreground
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    private override init() {
        super.init()
        NSLog("🔔 NotificationDelegate initialized")
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        NSLog("📬 Notification will present: \(notification.request.identifier)")
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        NSLog("📬 Notification tapped: \(response.notification.request.identifier)")
        completionHandler()
    }
}

@main
struct LockedApp: App {
    @StateObject private var appLocker = AppLocker()
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var snoozeManager = SnoozeManager()
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Set up notification categories and delegate
        setupNotifications()
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
                    .environmentObject(profileManager)
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // Check for pending snooze requests when app becomes active
                snoozeManager.checkForSnoozeRequest()
                
                // Check if snooze expired while app was closed
                if snoozeManager.isSnoozed {
                    let timeRemaining = snoozeManager.snoozeTimeRemaining
                    if timeRemaining <= 0 {
                        NSLog("⏰ Snooze expired while app was inactive - re-locking")
                        // End snooze and re-lock
                        snoozeManager.endSnooze()
                        appLocker.startSessionManually(for: profileManager.currentProfile)
                    }
                }
                
                // Check if timer expired while app was closed
                if appLocker.isLocking, let endDate = appLocker.timerEndDate {
                    if endDate <= Date() {
                        NSLog("⏰ Timer expired while app was inactive - unlocking")
                        appLocker.endSession(for: profileManager.currentProfile)
                    }
                }
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
            saveToAppGroup(maxSnoozesPerDay, forKey: maxSnoozesKey)
            UserDefaults.standard.set(maxSnoozesPerDay, forKey: maxSnoozesKey)
        }
    }
    @Published var snoozeDuration: TimeInterval = 300 {
        didSet {
            saveToAppGroup(snoozeDuration, forKey: snoozeDurationKey)
            UserDefaults.standard.set(snoozeDuration, forKey: snoozeDurationKey)
        }
    }
    
    private let lastResetDateKey = "lastSnoozeResetDate"
    private let snoozesUsedKey = "snoozesUsedToday"
    private let maxSnoozesKey = "maxSnoozesPerDay"
    private let snoozeDurationKey = "snoozeDuration"
    private let snoozeEndTimeKey = "snoozeEndTime"
    
    // App Group for sharing data with extensions
    private let appGroupIdentifier = "group.com.locked.app"
    private var sharedDefaults: UserDefaults?
    
    init() {
        sharedDefaults = UserDefaults(suiteName: appGroupIdentifier)
        loadSnoozeData()
        checkAndResetIfNewDay()
        checkForActiveSnooze()
        startListeningForSnoozeRequests()
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
    
    // MARK: - App Group Communication
    
    private func saveToAppGroup<T>(_ value: T, forKey key: String) {
        sharedDefaults?.set(value, forKey: key)
        sharedDefaults?.synchronize()
    }
    
    private func startListeningForSnoozeRequests() {
        // Listen for Darwin notifications from Shield Action Extension
        let notificationName = CFNotificationName("com.locked.app.snoozeRequested" as CFString)
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            { (center, observer, name, object, userInfo) in
                guard let observer = observer else { return }
                let manager = Unmanaged<SnoozeManager>.fromOpaque(observer).takeUnretainedValue()
                Task { @MainActor in
                    manager.handleSnoozeRequest()
                }
            },
            "com.locked.app.snoozeRequested" as CFString,
            nil,
            .deliverImmediately
        )
        
        // Also check periodically for snooze requests
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForSnoozeRequest()
            }
        }
    }
    
    func checkForSnoozeRequest() {
        guard let sharedDefaults = sharedDefaults else { return }
        
        if sharedDefaults.bool(forKey: "snoozeRequested") {
            let requestTime = sharedDefaults.double(forKey: "snoozeRequestTime")
            
            // Only process recent requests (within last 10 seconds)
            if Date().timeIntervalSince1970 - requestTime < 10 {
                NSLog("📱 Processing pending snooze request from shield")
                
                // Clear the flag
                sharedDefaults.set(false, forKey: "snoozeRequested")
                sharedDefaults.removeObject(forKey: "snoozeRequestTime")
                sharedDefaults.synchronize()
                
                handleSnoozeRequest()
            } else {
                // Clear old request
                sharedDefaults.set(false, forKey: "snoozeRequested")
                sharedDefaults.removeObject(forKey: "snoozeRequestTime")
                sharedDefaults.synchronize()
            }
        }
    }
    
    private func handleSnoozeRequest() {
        NSLog("📱 Snooze request received from shield!")
        
        if canSnooze {
            // Post notification that snooze needs to be activated
            NotificationCenter.default.post(name: NSNotification.Name("ActivateSnoozeFromShield"), object: nil)
        } else {
            NSLog("⚠️ Snooze request denied - no snoozes remaining")
        }
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
                // Snooze expired while app was closed - mark it but don't re-lock yet
                // The app should handle re-locking when it becomes active
                UserDefaults.standard.removeObject(forKey: snoozeEndTimeKey)
                isSnoozed = false
                snoozeTimeRemaining = 0
                NSLog("⏰ Snooze expired while app was closed")
            }
        }
    }
    
    // Public method to check and handle expired snooze/timer
    func handleExpiredTimers() {
        // Check if snooze expired
        if isSnoozed && snoozeTimeRemaining <= 0 {
            NSLog("⏰ Handling expired snooze")
            endSnooze()
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
        
        // Also save to App Group
        saveToAppGroup(snoozesUsedToday, forKey: snoozesUsedKey)
    }
}

// MARK: - Notification Setup

private func setupNotifications() {
    let center = UNUserNotificationCenter.current()
    
    // Use singleton delegate that stays alive
    center.delegate = NotificationDelegate.shared
    
    // Define notification categories
    let snoozeEndCategory = UNNotificationCategory(
        identifier: "SNOOZE_END",
        actions: [],
        intentIdentifiers: [],
        options: []
    )
    
    let timerEndCategory = UNNotificationCategory(
        identifier: "TIMER_END",
        actions: [],
        intentIdentifiers: [],
        options: []
    )
    
    // Register categories
    center.setNotificationCategories([snoozeEndCategory, timerEndCategory])
    
    NSLog("✅ Notification categories registered with singleton delegate")
}



