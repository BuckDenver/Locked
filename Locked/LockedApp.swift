//
//  LockedApp.swift
//  Locked
//
//  Created by Brandon Scott on 2025-06-11.
//

import SwiftUI

@main
struct LockedApp: App {
    @StateObject private var appLocker = AppLocker()
    @StateObject private var profileManager = ProfileManager()
    
    var body: some Scene {
        WindowGroup {
            LockedView()
                .environmentObject(appLocker)
                .environmentObject(profileManager)
        }
    }
}
