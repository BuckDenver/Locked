//
//  DeviceActivityMonitorExtension.swift
//  LockedMonitor
//
//  Monitors device activity and re-locks apps when snooze ends
//

import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    let store = ManagedSettingsStore()
    private let appGroupIdentifier = "group.com.brandonscott.locked"
    
    // Called when the schedule interval ends (when snooze timer expires)
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        NSLog("⏰ DeviceActivity interval ended - re-locking apps")
        
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            NSLog("❌ Failed to access App Group in monitor")
            return
        }
        
        // Clear snooze state
        sharedDefaults.set(false, forKey: "isSnoozing")
        sharedDefaults.removeObject(forKey: "snoozeEndTime")
        sharedDefaults.synchronize()
        
        // Re-apply shields using saved profile
        reapplyShields()
        
        // Notify main app
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.locked.app.snoozeEnded" as CFString),
            nil,
            nil,
            true
        )
        
        NSLog("✅ Apps re-locked automatically after snooze")
    }
    
    // Called when schedule starts (when snooze begins)
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        NSLog("⏰ DeviceActivity interval started - snooze active")
    }
    
    // MARK: - Shield Management
    
    private func reapplyShields() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return
        }
        
        // Load the current profile's lock settings from shared storage
        // This requires the main app to save profile info to App Group
        let isAllowListMode = sharedDefaults.bool(forKey: "currentProfile_isAllowListMode")
        
        // For now, we'll restore from the last known locked state
        // The main app needs to save this data when locking
        if let appTokensData = sharedDefaults.data(forKey: "currentProfile_appTokens"),
           let appTokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: appTokensData) {
            
            if isAllowListMode {
                NSLog("🛡️ Reapplying Allow List Mode")
                store.shield.applications = nil
                
                if appTokens.isEmpty {
                    store.shield.applicationCategories = .all()
                } else {
                    store.shield.applicationCategories = .all(except: appTokens)
                }
            } else {
                NSLog("🛡️ Reapplying Block List Mode")
                store.shield.applications = appTokens.isEmpty ? nil : appTokens
                
                if let categoryTokensData = sharedDefaults.data(forKey: "currentProfile_categoryTokens"),
                   let categoryTokens = try? JSONDecoder().decode(Set<ActivityCategoryToken>.self, from: categoryTokensData) {
                    store.shield.applicationCategories = categoryTokens.isEmpty ? .none : .specific(categoryTokens)
                }
            }
        } else {
            NSLog("⚠️ No profile data found - shields may not be correctly applied")
        }
    }
}
