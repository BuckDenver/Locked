//
//  AppBlocker.swift
//  Locked
//
//  Created by Brandon Scott on 2025-06-11.
//

import SwiftUI
import ManagedSettings
import FamilyControls

@MainActor
class AppLocker: ObservableObject {
    let store = ManagedSettingsStore()
    @Published var isLocking = false
    @Published var isAuthorized = false
    @Published var hasUsedNFC = false
    @Published var timerEndDate: Date?

    init() {
        loadLockingState()
        loadNFCUsageState()
        loadTimerEndDate()
        // Check authorization status without requesting
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        let status = AuthorizationCenter.shared.authorizationStatus
        self.isAuthorized = (status == .approved)
    }
    
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            DispatchQueue.main.async {
                self.isAuthorized = true
            }
        } catch {
            print("Failed to request authorization: \(error)")
            DispatchQueue.main.async {
                self.isAuthorized = false
            }
        }
    }
    
    func startSessionWithNFC(for profile: Profile) {
        guard isAuthorized else {
            print("Not authorized to lock apps")
            return
        }
        guard isLocking == false else { return }

        // Record that the user has successfully used NFC
        if !hasUsedNFC {
            hasUsedNFC = true
            saveNFCUsageState()
        }

        isLocking = true
        saveLockingState()
        applyLockingSettings(for: profile)
    }
    
    func startSessionManually(for profile: Profile) {
        guard isAuthorized else {
            print("Not authorized to lock apps")
            return
        }
        guard isLocking == false else { return }
        
        isLocking = true
        saveLockingState()
        applyLockingSettings(for: profile)
    }

    func endSession(for profile: Profile) {
        guard isAuthorized else {
            print("Not authorized to unlock apps")
            return
        }
        guard isLocking == true else { return }
        
        isLocking = false
        timerEndDate = nil
        saveLockingState()
        saveTimerEndDate()
        applyLockingSettings(for: profile)
    }
    
    func temporaryUnlock(for profile: Profile) {
        guard isAuthorized else {
            print("Not authorized to unlock apps")
            return
        }
        guard isLocking == true else { return }
        
        // Unlock but keep the timer
        isLocking = false
        saveLockingState()
        applyLockingSettings(for: profile)
    }
    
    func applyLockingSettings(for profile: Profile) {
        if isLocking {
            if profile.isAllowListMode {
                NSLog("🛡️ Allow List Mode: Allowing only \(profile.appTokens.count) apps")
                store.shield.applications = nil

                if profile.appTokens.isEmpty {
                    NSLog("⚠️ WARNING: Allow list is empty - ALL APPS will be blocked!")
                    store.shield.applicationCategories = .all()
                } else {
                    NSLog("✅ Blocking all apps except the \(profile.appTokens.count) in allow list")
                    store.shield.applicationCategories = .all(except: profile.appTokens)
                }
            } else {
                NSLog("🛡️ Block List Mode: Blocking \(profile.appTokens.count) apps and \(profile.categoryTokens.count) categories")
                if profile.appTokens.isEmpty && profile.categoryTokens.isEmpty {
                    NSLog("⚠️ WARNING: No apps or categories selected - nothing will be blocked!")
                }
                store.shield.applications = profile.appTokens.isEmpty ? nil : profile.appTokens
                store.shield.applicationCategories = profile.categoryTokens.isEmpty ? ShieldSettings.ActivityCategoryPolicy.none : .specific(profile.categoryTokens)
            }
        } else {
            NSLog("🔓 Unlocking all apps")
            store.shield.applications = nil
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.none
        }
    }
    
    private func loadLockingState() {
        isLocking = UserDefaults.standard.bool(forKey: "isLocking")
    }

    private func saveLockingState() {
        UserDefaults.standard.set(isLocking, forKey: "isLocking")
    }

    private func loadNFCUsageState() {
        hasUsedNFC = UserDefaults.standard.bool(forKey: "hasUsedNFC")
    }

    private func saveNFCUsageState() {
        UserDefaults.standard.set(hasUsedNFC, forKey: "hasUsedNFC")
    }
    
    private func loadTimerEndDate() {
        if let timestamp = UserDefaults.standard.object(forKey: "timerEndDate") as? TimeInterval {
            timerEndDate = Date(timeIntervalSince1970: timestamp)
        }
    }
    
    private func saveTimerEndDate() {
        if let endDate = timerEndDate {
            UserDefaults.standard.set(endDate.timeIntervalSince1970, forKey: "timerEndDate")
        } else {
            UserDefaults.standard.removeObject(forKey: "timerEndDate")
        }
    }
    
    func setTimerEndDate(_ date: Date?) {
        timerEndDate = date
        saveTimerEndDate()
    }
}
