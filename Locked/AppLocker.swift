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

    init() {
        loadLockingState()
        loadNFCUsageState()
        Task {
            await requestAuthorization()
        }
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
        saveLockingState()
        applyLockingSettings(for: profile)
    }
    
    func applyLockingSettings(for profile: Profile) {
        if isLocking {
            if profile.isAllowListMode {
                NSLog("Allow List Mode: Allowing only \(profile.appTokens.count) apps")
                store.shield.applications = nil

                if profile.appTokens.isEmpty {
                    store.shield.applicationCategories = .all()
                } else {
                    store.shield.applicationCategories = .all(except: profile.appTokens)
                }
            } else {
                NSLog("Locking \(profile.appTokens.count) apps")
                store.shield.applications = profile.appTokens.isEmpty ? nil : profile.appTokens
                store.shield.applicationCategories = profile.categoryTokens.isEmpty ? ShieldSettings.ActivityCategoryPolicy.none : .specific(profile.categoryTokens)
            }
        } else {
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
}
