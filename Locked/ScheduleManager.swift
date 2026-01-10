//
//  ScheduleManager.swift
//  Locked
//
//  Created by Brandon Scott on 2025-01-09.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ScheduleManager: ObservableObject {
    @Published var schedules: [Schedule] = []
    
    private var timer: Timer?
    private var appLocker: AppLocker?
    private var profileManager: ProfileManager?
    
    init() {
        loadSchedules()
    }
    
    func configure(appLocker: AppLocker, profileManager: ProfileManager) {
        self.appLocker = appLocker
        self.profileManager = profileManager
        startMonitoring()
    }
    
    func addSchedule(_ schedule: Schedule) {
        schedules.append(schedule)
        saveSchedules()
        evaluateSchedules()
    }
    
    func updateSchedule(_ schedule: Schedule) {
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index] = schedule
            saveSchedules()
            evaluateSchedules()
        }
    }
    
    func deleteSchedule(withId id: UUID) {
        schedules.removeAll { $0.id == id }
        saveSchedules()
        evaluateSchedules()
    }
    
    func toggleSchedule(withId id: UUID) {
        if let index = schedules.firstIndex(where: { $0.id == id }) {
            schedules[index].isEnabled.toggle()
            saveSchedules()
            evaluateSchedules()
        }
    }
    
    /// Start monitoring schedules every minute
    func startMonitoring() {
        stopMonitoring()
        
        // Check immediately
        evaluateSchedules()
        
        // Then check every minute
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.evaluateSchedules()
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Evaluate all schedules and apply appropriate locking state
    func evaluateSchedules() {
        guard let appLocker = appLocker,
              let profileManager = profileManager else {
            return
        }
        
        let now = Date()
        
        // Find all active schedules
        let activeSchedules = schedules.filter { $0.isActive(at: now) }
        
        NSLog("Evaluating schedules: \(activeSchedules.count) active out of \(schedules.count) total")
        
        if let activeSchedule = activeSchedules.first {
            // If there's an active schedule and we're not locking, start locking
            if !appLocker.isLocking {
                NSLog("Starting scheduled lock for schedule: \(activeSchedule.name)")
                
                // Find the profile for this schedule
                if let profile = profileManager.profiles.first(where: { $0.id == activeSchedule.profileId }) {
                    // Set the current profile
                    profileManager.setCurrentProfile(id: profile.id)
                    
                    // Start the session
                    appLocker.startSessionManually(for: profile)
                    
                    // Send a notification
                    sendNotification(
                        title: "Apps Locked",
                        body: "Schedule '\(activeSchedule.name)' is now active"
                    )
                }
            }
        } else {
            // No active schedules, unlock if we're currently locked by a schedule
            if appLocker.isLocking && wasLockedBySchedule() {
                NSLog("Ending scheduled lock - no active schedules")
                appLocker.endSession(for: profileManager.currentProfile)
                
                // Send a notification
                sendNotification(
                    title: "Apps Unlocked",
                    body: "Schedule has ended"
                )
            }
        }
        
        // Update the flag
        setLockedBySchedule(activeSchedules.count > 0)
    }
    
    // MARK: - Persistence
    
    private func loadSchedules() {
        if let data = UserDefaults.standard.data(forKey: "savedSchedules"),
           let decoded = try? JSONDecoder().decode([Schedule].self, from: data) {
            schedules = decoded
        }
    }
    
    private func saveSchedules() {
        if let encoded = try? JSONEncoder().encode(schedules) {
            UserDefaults.standard.set(encoded, forKey: "savedSchedules")
        }
    }
    
    // MARK: - Helper Methods
    
    private func wasLockedBySchedule() -> Bool {
        return UserDefaults.standard.bool(forKey: "wasLockedBySchedule")
    }
    
    private func setLockedBySchedule(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: "wasLockedBySchedule")
    }
    
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                NSLog("Error sending notification: \(error)")
            }
        }
    }
    
    /// Request notification permissions
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                NSLog("Error requesting notification permissions: \(error)")
            } else {
                NSLog("Notification permissions granted: \(granted)")
            }
        }
    }
}
