//
//  TimerLockView.swift
//  Locked
//
//  Created by Brandon Scott on 2025-01-12.
//

import SwiftUI

struct TimerLockView: View {
    @EnvironmentObject private var appLocker: AppLocker
    @EnvironmentObject private var profileManager: ProfileManager
    @EnvironmentObject private var timerManager: TimerManager
    @Environment(\.dismiss) var dismiss
    
    @State private var hours: Int = 0
    @State private var minutes: Int = 30
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.9, green: 0.5, blue: 0.2), Color(red: 0.8, green: 0.3, blue: 0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "timer")
                            .font(.system(size: 80, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                        
                        Text("Set Timer Lock")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Apps will automatically lock for the selected duration")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    // Timer Picker
                    VStack(spacing: 16) {
                        HStack(spacing: 0) {
                            // Hours Picker
                            Picker("Hours", selection: $hours) {
                                ForEach(0...23, id: \.self) { hour in
                                    Text("\(hour)")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80)
                            
                            Text("h")
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 8)
                            
                            // Minutes Picker
                            Picker("Minutes", selection: $minutes) {
                                ForEach(0...59, id: \.self) { minute in
                                    Text("\(minute)")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80)
                            
                            Text("m")
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 8)
                        }
                        .padding(.horizontal, 40)
                        
                        Text(totalTimeString)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                    )
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Button {
                            showConfirmation = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 18, weight: .bold))
                                Text("Start Timer Lock")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                            )
                        }
                        .disabled(hours == 0 && minutes == 0)
                        .opacity((hours == 0 && minutes == 0) ? 0.5 : 1.0)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
        .alert("Start Timer Lock?", isPresented: $showConfirmation) {
            Button("Start", role: .destructive) {
                startTimerLock()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Apps will be locked for \(totalTimeString). They will automatically unlock when the timer expires.")
        }
    }
    
    private var totalTimeString: String {
        if hours == 0 && minutes == 0 {
            return "Select a duration"
        } else if hours == 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else if minutes == 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(hours) hour\(hours == 1 ? "" : "s") \(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
    
    private func startTimerLock() {
        let totalMinutes = (hours * 60) + minutes
        
        // Start the lock
        appLocker.startSessionManually(for: profileManager.currentProfile)
        
        // Schedule notification to unlock after timer
        scheduleUnlockNotification(afterMinutes: totalMinutes)
        
        // Store timer end time and update manager
        let endTime = Date().addingTimeInterval(TimeInterval(totalMinutes * 60))
        timerManager.setTimer(endTime: endTime)
        
        dismiss()
    }
    
    private func scheduleUnlockNotification(afterMinutes minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Timer Lock Expired"
        content.body = "Your \(totalTimeString) timer has ended. Your apps have been unlocked!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let request = UNNotificationRequest(identifier: "timerLockExpired", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
}

#Preview {
    TimerLockView()
        .environmentObject(AppLocker())
        .environmentObject(ProfileManager())
}
