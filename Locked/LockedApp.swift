//
//  LockedApp.swift
//  Locked
//
//  Created by Brandon Scott on 2025-06-11.
//

import SwiftUI

@main
struct LockedApp: App {
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainAppView()
            } else {
                OnboardingView(isOnboardingComplete: $hasCompletedOnboarding)
            }
        }
    }
}
struct MainAppView: View {
    @StateObject private var appLocker = AppLocker()
    @StateObject private var profileManager = ProfileManager()
    
    var body: some View {
        LockedView()
            .environmentObject(appLocker)
            .environmentObject(profileManager)
            .onAppear {
                print("✅ MainAppView appeared")
                print("   - AppLocker initialized: \(appLocker.isAuthorized)")
                print("   - Profiles loaded: \(profileManager.profiles.count)")
            }
    }
}

