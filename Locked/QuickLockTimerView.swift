//
//  QuickLockTimerView.swift
//  Locked
//
//  Created by Assistant on 2026-01-10.
//

import SwiftUI
import UserNotifications

struct QuickLockTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appLocker: AppLocker
    @ObservedObject var profileManager: ProfileManager
    
    @State private var selectedHours: Int = 2
    @State private var selectedMinutes: Int = 0
    
    let hourOptions = Array(0...23)
    let minuteOptions = Array(0...59)
    
    var totalMinutes: Int {
        selectedHours * 60 + selectedMinutes
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Icon
                Image(systemName: "timer")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                // Title
                Text("Quick Lock Timer")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Lock apps for a set duration")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Time picker
                VStack(spacing: 20) {
                    HStack(spacing: 40) {
                        // Hours picker
                        VStack {
                            Text("Hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Picker("Hours", selection: $selectedHours) {
                                ForEach(hourOptions, id: \.self) { hour in
                                    Text("\(hour)").tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 120)
                            .clipped()
                        }
                        
                        Text(":")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        // Minutes picker
                        VStack {
                            Text("Minutes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Picker("Minutes", selection: $selectedMinutes) {
                                ForEach(minuteOptions, id: \.self) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 120)
                            .clipped()
                        }
                    }
                    
                    // Duration preview
                    if totalMinutes > 0 {
                        Text("Lock for \(durationString)")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                // Start button
                Button(action: {
                    startQuickLock()
                }) {
                    Text("Start Lock Timer")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(totalMinutes > 0 ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(totalMinutes == 0)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("Quick Lock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var durationString: String {
        if selectedHours > 0 && selectedMinutes > 0 {
            return "\(selectedHours)h \(selectedMinutes)m"
        } else if selectedHours > 0 {
            return "\(selectedHours) hour\(selectedHours > 1 ? "s" : "")"
        } else {
            return "\(selectedMinutes) minutes"
        }
    }
    
    private func startQuickLock() {
        guard totalMinutes > 0 else { return }
        
        // Calculate end date
        let endDate = Date().addingTimeInterval(TimeInterval(totalMinutes * 60))
        
        // Start the lock and save the timer end date
        appLocker.startSessionManually(for: profileManager.currentProfile)
        appLocker.setTimerEndDate(endDate)
        
        // Schedule notification for when timer ends
        let content = UNMutableNotificationContent()
        content.title = "Lock Timer Ended"
        content.body = "Your \(durationString) lock timer has expired. Open the app to unlock."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(totalMinutes * 60),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "quick-lock-timer",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                NSLog("❌ Error scheduling notification: \(error)")
            } else {
                NSLog("✅ Quick lock timer scheduled for \(durationString)")
            }
        }
        
        // Show confirmation and dismiss
        dismiss()
        
        // Log for debugging
        NSLog("⏲️ Quick lock started for \(totalMinutes) minutes until \(endDate)")
    }
}

#Preview {
    QuickLockTimerView(
        appLocker: AppLocker(),
        profileManager: ProfileManager()
    )
}
