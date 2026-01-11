//
//  ShieldActionExtension.swift
//  LockedShieldAction
//
//  Created by Assistant on 2026-01-10.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit
import Foundation

// This extension handles actions when users interact with the shield
class ShieldActionExtension: ShieldActionDelegate {
    
    // App Group identifier - must match in both main app and extension
    private let appGroupIdentifier = "group.com.locked.app"
    
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        
        NSLog("🛡️ Shield Action Extension - handle called for APPLICATION")
        NSLog("🛡️ Action type: \(action)")
        
        switch action {
        case .primaryButtonPressed:
            NSLog("🛡️ PRIMARY button pressed (Close)")
            completionHandler(.close)
            
        case .secondaryButtonPressed:
            NSLog("🛡️ SECONDARY button pressed (SNOOZE)")
            handleSnoozeRequest()
            completionHandler(.close)
            
        @unknown default:
            NSLog("🛡️ UNKNOWN action")
            completionHandler(.close)
        }
    }
    
    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        
        NSLog("🛡️ Shield Action Extension - handle called for WEB DOMAIN")
        
        switch action {
        case .primaryButtonPressed:
            NSLog("🛡️ PRIMARY button pressed")
            completionHandler(.close)
            
        case .secondaryButtonPressed:
            NSLog("🛡️ SECONDARY button pressed (SNOOZE)")
            handleSnoozeRequest()
            completionHandler(.close)
            
        @unknown default:
            NSLog("🛡️ UNKNOWN action")
            completionHandler(.close)
        }
    }
    
    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        
        NSLog("🛡️ Shield Action Extension - handle called for CATEGORY")
        
        switch action {
        case .primaryButtonPressed:
            NSLog("🛡️ PRIMARY button pressed")
            completionHandler(.close)
            
        case .secondaryButtonPressed:
            NSLog("🛡️ SECONDARY button pressed (SNOOZE)")
            handleSnoozeRequest()
            completionHandler(.close)
            
        @unknown default:
            NSLog("🛡️ UNKNOWN action")
            completionHandler(.close)
        }
    }
    
    private func handleSnoozeRequest() {
        NSLog("🛡️ Shield Action: handleSnoozeRequest called")
        
        // Use App Groups to communicate with main app
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            NSLog("❌ Failed to access App Group: \(appGroupIdentifier)")
            return
        }
        
        NSLog("✅ App Group accessed successfully")
        
        // Check if snooze is available
        let snoozesUsed = sharedDefaults.integer(forKey: "snoozesUsedToday")
        let maxSnoozes = sharedDefaults.integer(forKey: "maxSnoozesPerDay")
        let snoozesRemaining = max(0, (maxSnoozes > 0 ? maxSnoozes : 5) - snoozesUsed)
        
        NSLog("📊 Snoozes used: \(snoozesUsed), Max: \(maxSnoozes), Remaining: \(snoozesRemaining)")
        
        if snoozesRemaining > 0 {
            // Trigger snooze request
            sharedDefaults.set(true, forKey: "snoozeRequested")
            sharedDefaults.set(Date().timeIntervalSince1970, forKey: "snoozeRequestTime")
            let synchronized = sharedDefaults.synchronize()
            
            NSLog("✅ Snooze requested from shield (synchronized: \(synchronized))")
            
            // Post notification to wake up main app if needed
            notifyMainApp()
        } else {
            // No snoozes remaining
            sharedDefaults.set(true, forKey: "snoozeRequestDenied")
            sharedDefaults.synchronize()
            
            NSLog("⚠️ Snooze request denied - no snoozes remaining")
        }
    }
    
    private func notifyMainApp() {
        // Post Darwin notification to wake up main app
        // This is a cross-process notification mechanism
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.locked.app.snoozeRequested" as CFString),
            nil,
            nil,
            true
        )
    }
}

