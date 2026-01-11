//
//  SettingsView.swift
//  Locked
//
//  Created by Assistant on 2026-01-10.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var snoozeManager: SnoozeManager
    @Environment(\.dismiss) var dismiss
    @State private var notificationStatus: String = "Checking..."
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Snooze Duration", selection: $snoozeManager.snoozeDuration) {
                        ForEach(1...15, id: \.self) { minutes in
                            Text("\(minutes) minute\(minutes == 1 ? "" : "s")").tag(Double(minutes * 60))
                        }
                    }
                    
                    Stepper("Max Snoozes Per Day: \(snoozeManager.maxSnoozesPerDay)", 
                            value: $snoozeManager.maxSnoozesPerDay, 
                            in: 1...10)
                    
                    HStack {
                        Text("Snoozes Used Today")
                        Spacer()
                        Text("\(snoozeManager.snoozesUsedToday) / \(snoozeManager.maxSnoozesPerDay)")
                            .foregroundColor(.secondary)
                    }
                    
                    #if DEBUG
                    Button("Reset Count (Debug Only)") {
                        snoozeManager.resetSnoozesUsed()
                    }
                    .foregroundColor(.orange)
                    #endif
                } header: {
                    Text("Snooze Settings")
                } footer: {
                    Text("Customize how snooze works when apps are locked. The counter resets automatically at midnight each day.")
                }
                
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Snooze temporarily unlocks your apps for quick access. Use it wisely!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    HStack {
                        Text("Status:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(notificationStatus)
                            .foregroundColor(notificationStatus.contains("Authorized") ? .green : .orange)
                    }
                    
                    Button(action: sendTestNotification) {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(.blue)
                            Text("Send Test Notification")
                            Spacer()
                        }
                    }
                    
                    if !notificationStatus.contains("Authorized") {
                        Button(action: openSettings) {
                            HStack {
                                Image(systemName: "gear")
                                    .foregroundColor(.orange)
                                Text("Open Settings")
                                Spacer()
                                Image(systemName: "arrow.up.forward.app")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Tap to test if notifications are working. You should see a notification appear immediately.")
                }
                .onAppear {
                    checkNotificationStatus()
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "app.badge.checkmark")
                                .foregroundColor(.green)
                            Text("Keep Running in Background")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("This app works best when kept in the background. Please don't force-quit the app, as this may prevent app locking from working properly.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Important")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    self.notificationStatus = "✅ Authorized"
                case .denied:
                    self.notificationStatus = "❌ Denied"
                case .notDetermined:
                    self.notificationStatus = "⚠️ Not Requested"
                case .provisional:
                    self.notificationStatus = "⚠️ Provisional"
                case .ephemeral:
                    self.notificationStatus = "⚠️ Ephemeral"
                @unknown default:
                    self.notificationStatus = "❓ Unknown"
                }
                
                NSLog("📱 Notification Status: \(self.notificationStatus)")
                NSLog("📱 Alert Style: \(settings.alertStyle.rawValue)")
                NSLog("📱 Badge: \(settings.badgeSetting.rawValue)")
                NSLog("📱 Sound: \(settings.soundSetting.rawValue)")
                NSLog("📱 Lock Screen: \(settings.lockScreenSetting.rawValue)")
                NSLog("📱 Notification Center: \(settings.notificationCenterSetting.rawValue)")
            }
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendTestNotification() {
        // First, check for delivered notifications
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            NSLog("📬 Currently delivered notifications: \(notifications.count)")
            for notif in notifications {
                NSLog("   - \(notif.request.identifier): \(notif.request.content.title)")
            }
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "Notifications are working! ✅"
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "test-notification-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Immediate
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                NSLog("❌ Test notification failed: \(error)")
            } else {
                NSLog("✅ Test notification sent successfully")
                
                // Check if it was delivered
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                        NSLog("📬 Delivered notifications after sending: \(notifications.count)")
                        let found = notifications.contains(where: { $0.request.identifier.hasPrefix("test-notification") })
                        if found {
                            NSLog("✅ Test notification IS in delivered list!")
                        } else {
                            NSLog("❌ Test notification NOT in delivered list!")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SnoozeManager())
}
