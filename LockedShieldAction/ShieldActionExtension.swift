//
//  ShieldActionExtension.swift
//  LockedShieldAction
//
//  Extension that provides the "Snooze" button on shield screens
//

import ManagedSettings
import ManagedSettingsUI
import DeviceActivity
import Foundation

class ShieldActionExtension: ShieldActionDelegate {
    
    // App Group for sharing data between app and extension
    private let appGroupIdentifier = "group.com.locked.app"
    
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        
        switch action {
        case .primaryButtonPressed:
            // User tapped "Snooze for 5 mins"
            handleSnoozeRequest(for: application, completionHandler: completionHandler)
            
        case .secondaryButtonPressed:
            // User tapped cancel/close - just close the shield temporarily
            completionHandler(.close)
            
        @unknown default:
            completionHandler(.close)
        }
    }
    
    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        
        switch action {
        case .primaryButtonPressed:
            // User tapped "Snooze for 5 mins" on a website
            handleSnoozeRequest(for: webDomain, completionHandler: completionHandler)
            
        case .secondaryButtonPressed:
            completionHandler(.close)
            
        @unknown default:
            completionHandler(.close)
        }
    }
    
    // MARK: - Snooze Handling
    
    private func handleSnoozeRequest(for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            NSLog("❌ Failed to access App Group")
            completionHandler(.close)
            return
        }
        
        // Check if snooze is available
        let maxSnoozesPerDay = sharedDefaults.integer(forKey: "maxSnoozesPerDay")
        let snoozesUsedToday = sharedDefaults.integer(forKey: "snoozesUsedToday")
        let snoozesRemaining = max(0, maxSnoozesPerDay - snoozesUsedToday)
        
        if snoozesRemaining <= 0 {
            NSLog("⚠️ No snoozes remaining today")
            completionHandler(.close)
            return
        }
        
        // Get snooze duration (default 5 minutes)
        let snoozeDuration = sharedDefaults.double(forKey: "snoozeDuration")
        let duration = snoozeDuration > 0 ? snoozeDuration : 300
        
        // Calculate snooze end time
        let snoozeEndTime = Date().addingTimeInterval(duration)
        
        // Save snooze state to App Group
        sharedDefaults.set(true, forKey: "isSnoozing")
        sharedDefaults.set(snoozeEndTime, forKey: "snoozeEndTime")
        sharedDefaults.set(snoozesUsedToday + 1, forKey: "snoozesUsedToday")
        sharedDefaults.synchronize()
        
        NSLog("⏰ Snooze started from shield action - ends at \(snoozeEndTime)")
        
        // Schedule DeviceActivity to re-lock after snooze ends
        scheduleRelockActivity(endTime: snoozeEndTime)
        
        // Notify main app that snooze was activated
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.locked.app.snoozeActivated" as CFString),
            nil,
            nil,
            true
        )
        
        // Close the shield - user can now access the app
        completionHandler(.close)
    }
    
    private func handleSnoozeRequest(for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        // Same logic as apps
        handleSnoozeRequest(for: ApplicationToken(), completionHandler: completionHandler)
    }
    
    // MARK: - DeviceActivity Scheduling
    
    private func scheduleRelockActivity(endTime: Date) {
        let center = DeviceActivityCenter()
        let activityName = DeviceActivityName("snooze-relock")
        
        // Create a schedule that ends when snooze should finish
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute, .second], from: Date())
        let endComponents = calendar.dateComponents([.hour, .minute, .second], from: endTime)
        
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: startComponents.hour, minute: startComponents.minute),
            intervalEnd: DateComponents(hour: endComponents.hour, minute: endComponents.minute),
            repeats: false
        )
        
        do {
            // Start monitoring - when interval ends, DeviceActivityMonitor will be called
            try center.startMonitoring(activityName, during: schedule)
            NSLog("✅ Scheduled DeviceActivity to re-lock at \(endTime)")
        } catch {
            NSLog("❌ Failed to schedule DeviceActivity: \(error)")
        }
    }
}
