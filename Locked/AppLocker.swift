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
    
    init() {
        loadLockingState()
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
    
    func toggleLocking(for profile: Profile) {
        guard isAuthorized else {
            print("Not authorized to lock apps")
            return
        }
        
        isLocking.toggle()
        saveLockingState()
        applyLockingSettings(for: profile)
    }
    
    func applyLockingSettings(for profile: Profile) {
        if isLocking {
            NSLog("Locking \(profile.appTokens.count) apps")
            store.shield.applications = profile.appTokens.isEmpty ? nil : profile.appTokens
            store.shield.applicationCategories = profile.categoryTokens.isEmpty ? ShieldSettings.ActivityCategoryPolicy.none : .specific(profile.categoryTokens)
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
}
