//
//  LockedView.swift
//  Locked
//
//  Created by Brandon Scott on 2025-06-11.
//

import SwiftUI
import CoreNFC
import SFSymbolsPicker
import FamilyControls
import ManagedSettings

struct LockedView: View {
    @EnvironmentObject private var appLocker: AppLocker
    @EnvironmentObject private var profileManager: ProfileManager
    @EnvironmentObject private var snoozeManager: SnoozeManager
    @StateObject private var nfcReader = NFCReader()
    private let tagPhrase = "LOCKED-IS-GREAT"
    
    @State private var showWrongTagAlert = false
    @State private var showCreateTagAlert = false
    @State private var nfcWriteSuccess = false
    @State private var showStartSessionWarning = false
    @State private var showSessionStartOptions = false
    @State private var showQuickLockOptions = false
    @State private var showSettings = false
    @State private var snoozeTimer: Timer?
    @State private var currentTime = Date()
    @State private var countdownTimer: Timer?
    
    private var isLocking : Bool {
        return appLocker.isLocking
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Background color based on state
                    ZStack {
                        Color("NonBlockingBackground")
                            .opacity(!isLocking && !snoozeManager.isSnoozed ? 1 : 0)
                        Color("BlockingBackground")
                            .opacity(isLocking && !snoozeManager.isSnoozed ? 1 : 0)
                        Color.orange.opacity(0.3) // Snooze background
                            .opacity(snoozeManager.isSnoozed ? 1 : 0)
                    }
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.5), value: isLocking)
                    .animation(.easeInOut(duration: 0.5), value: snoozeManager.isSnoozed)

                    // Main content - three different views
                    Group {
                        if snoozeManager.isSnoozed {
                            snoozeView(geometry: geometry)
                        } else if isLocking {
                            lockOrUnlockButton(geometry: geometry)
                        } else {
                            lockOrUnlockButton(geometry: geometry)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .offset(y: snoozeManager.isSnoozed ? 0 : -geometry.size.height * 0.15)
                    .transition(.opacity)
                    .animation(.spring(), value: isLocking)
                    .animation(.spring(), value: snoozeManager.isSnoozed)

                    // Profiles strip layer at bottom when unlocked (hide when snoozed)
                    if !isLocking && !snoozeManager.isSnoozed {
                        ProfilesPicker(profileManager: profileManager)
                            .frame(height: geometry.size.height / 2)
                            .position(x: geometry.size.width / 2,
                                      y: geometry.size.height * 1)
                    }
                }
            }
            .onAppear {
                // Start countdown timer if there's an active timer
                if isLocking && appLocker.timerEndDate != nil {
                    startCountdownTimer()
                }
                
                // Restart snooze timer if snooze is active
                if snoozeManager.isSnoozed && snoozeManager.snoozeTimeRemaining > 0 {
                    restartSnoozeTimer()
                }
            }
            .onChange(of: appLocker.timerEndDate) { oldValue, newValue in
                // Start countdown when timer is set
                if newValue != nil && isLocking {
                    startCountdownTimer()
                } else if newValue == nil {
                    stopCountdownTimer()
                }
            }
            .onChange(of: isLocking) { oldValue, newValue in
                // Start/stop countdown when locking state changes
                if newValue && appLocker.timerEndDate != nil {
                    startCountdownTimer()
                } else if !newValue {
                    stopCountdownTimer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isLocking && !snoozeManager.isSnoozed {
                        HStack(spacing: 16) {
                            Button(action: {
                                showQuickLockOptions = true
                            }) {
                                Image(systemName: "timer")
                                    .foregroundColor(.primary)
                            }
                            
                            Button(action: {
                                showSettings = true
                            }) {
                                Image(systemName: "gearshape")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isLocking && !snoozeManager.isSnoozed {
                        createTagButton
                    }
                }
            }
            .alert(isPresented: $showWrongTagAlert) {
                Alert(
                    title: Text("Not a Locked Tag"),
                    message: Text("You can create a new Locked tag using the + button"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert("Create Locked Tag", isPresented: $showCreateTagAlert) {
                Button("Create") { createLockedTag() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Do you want to create a new Locked tag?")
            }
            .alert("Tag Creation", isPresented: $nfcWriteSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(nfcWriteSuccess ? "Locked tag created successfully!" : "Failed to create Locked tag. Please try again.")
            }
            .alert("Lock Without NFC?", isPresented: $showStartSessionWarning) {
                Button("Lock") {
                    appLocker.startSessionManually(for: profileManager.currentProfile)
                    showStartSessionWarning = false
                }
                Button("Cancel", role: .cancel) {
                    showStartSessionWarning = false
                }
            } message: {
                Text("Remember: You'll need your NFC tag to unlock!")
            }
            .sheet(isPresented: $showQuickLockOptions) {
                QuickLockTimerView(
                    appLocker: appLocker,
                    profileManager: profileManager
                )
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(snoozeManager)
            }
        }
    }
    
    @ViewBuilder
    private func lockOrUnlockButton(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                // Lock icon button - centered
                Button(action: {
                    withAnimation(.spring()) {
                        onPrimaryTap()
                    }
                }) {
                    Image(isLocking ? "RedIcon" : "GreenIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: geometry.size.height / 3)
                }
                
                // Text content grouped below icon
                VStack(spacing: 16) {
                    // Main heading
                    Text(isLocking ? "Tap To Unlock" : "Tap To Lock")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Subheading / additional options
                    VStack(spacing: 12) {
                        // Show snooze option when locked
                        if isLocking {
                            if snoozeManager.canSnooze {
                                Button("Unlock for \(formatDuration(snoozeManager.snoozeDuration)) (\(snoozeManager.snoozesRemaining) left today)") {
                                    startSnooze()
                                }
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            } else {
                                Text("No snoozes remaining today")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        
                        if !isLocking {
                            Button("Lock Without NFC") {
                                showStartSessionWarning = true
                            }
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
            }
            
            Spacer()
            
            // Timer countdown at bottom when locked
            if isLocking, let endDate = appLocker.timerEndDate {
                let timeRemaining = endDate.timeIntervalSince(currentTime)
                if timeRemaining > 0 {
                    VStack(spacing: 8) {
                        Text("Time Remaining")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(formatTimeRemaining(timeRemaining))
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                            .monospacedDigit()
                    }
                    .padding(.bottom, 60)
                    .onAppear {
                        startCountdownTimer()
                    }
                    .onDisappear {
                        stopCountdownTimer()
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
        .id(isLocking)
    }
    
    private func onPrimaryTap() {
        if isLocking {
            scanTagForUnlock()
        } else {
            scanTagForStart()
        }
    }

    private func scanTagForUnlock() {
        nfcReader.scan { payload in
            if payload == tagPhrase {
                NSLog("Ending session via NFC")
                appLocker.endSession(for: profileManager.currentProfile)
            } else {
                showWrongTagAlert = true
                NSLog("Wrong Tag!\nPayload: \(payload)")
            }
        }
    }
    
    private func scanTagForStart() {
        nfcReader.scan { payload in
            if payload == tagPhrase {
                NSLog("Starting session via NFC")
                appLocker.startSessionWithNFC(for: profileManager.currentProfile)
            } else {
                showWrongTagAlert = true
                NSLog("Wrong Tag!\nPayload: \(payload)")
            }
        }
    }
    
    private var createTagButton: some View {
        Button(action: {
            showCreateTagAlert = true
        }) {
            Text("Register Tag")
                .bold()
                .foregroundColor(.primary)
        }
        .disabled(!NFCNDEFReaderSession.readingAvailable)
    }
    
    private func createLockedTag() {
        nfcReader.write(tagPhrase) { success in
            nfcWriteSuccess = success
            showCreateTagAlert = false
        }
    }
    
    // MARK: - Snooze Functions
    
    @ViewBuilder
    private func snoozeView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Timer icon with pulsing animation
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                
                Image(systemName: "timer")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.orange)
            }
            .onAppear {
                pulseAnimation = true
            }
            
            // "Snoozed" title
            Text("Snoozed")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.primary)
            
            // Countdown timer
            Text(timeString(from: snoozeManager.snoozeTimeRemaining))
                .font(.system(size: 72, weight: .semibold))
                .foregroundColor(.primary)
                .monospacedDigit()
            
            // Description
            VStack(spacing: 8) {
                Text("Apps are temporarily unlocked")
                    .font(.system(size: 18))
                    .foregroundColor(.primary.opacity(0.9))
                
                Text("They will lock again when the timer expires")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            // Cancel snooze button
            Button(action: {
                endSnooze()
            }) {
                Text("End Snooze Early")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.8))
                    )
            }
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @State private var pulseAnimation = false
    
    private func startSnooze() {
        // Temporarily unlock the apps (keeping timer intact)
        appLocker.temporaryUnlock(for: profileManager.currentProfile)
        
        // Set snooze state in shared manager (uses custom duration)
        snoozeManager.startSnooze()
        
        // Invalidate any existing timer
        snoozeTimer?.invalidate()
        
        // Start countdown timer (updates every second)
        snoozeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
            let newTime = snoozeManager.snoozeTimeRemaining - 1
            snoozeManager.updateTimeRemaining(newTime)
            
            if newTime <= 0 {
                endSnooze()
            }
        }
        
        // Send notification
        let content = UNMutableNotificationContent()
        content.title = "Snooze Started"
        content.body = "Apps unlocked for \(formatDuration(snoozeManager.snoozeDuration))"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "snooze-start",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
        
        NSLog("⏰ Snooze timer started for \(snoozeManager.snoozeDuration) seconds")
    }
    
    private func endSnooze() {
        snoozeTimer?.invalidate()
        snoozeTimer = nil
        
        // Clear snooze state in shared manager
        snoozeManager.endSnooze()
        
        // Re-lock the apps
        appLocker.startSessionManually(for: profileManager.currentProfile)
        
        // Send notification
        let content = UNMutableNotificationContent()
        content.title = "Snooze Ended"
        content.body = "Apps are locked again"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "snooze-end",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
        
        NSLog("⏰ Snooze timer ended - re-locking apps")
    }
    
    private func restartSnoozeTimer() {
        // Make sure apps are unlocked
        appLocker.temporaryUnlock(for: profileManager.currentProfile)
        
        // Invalidate any existing timer
        snoozeTimer?.invalidate()
        
        // Start countdown timer (updates every second)
        snoozeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
            let newTime = snoozeManager.snoozeTimeRemaining - 1
            snoozeManager.updateTimeRemaining(newTime)
            
            if newTime <= 0 {
                endSnooze()
            }
        }
        
        NSLog("⏰ Snooze timer restarted with \(snoozeManager.snoozeTimeRemaining) seconds remaining")
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        if minutes < 60 {
            return minutes == 1 ? "1 Minute" : "\(minutes) Minutes"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return hours == 1 ? "1 Hour" : "\(hours) Hours"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
    
    // MARK: - Countdown Timer Functions
    
    private func startCountdownTimer() {
        // Update immediately
        currentTime = Date()
        
        // Then update every second
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.currentTime = Date()
                
                // Check if timer has expired
                if let endDate = self.appLocker.timerEndDate,
                   endDate <= Date() {
                    NSLog("⏰ Timer expired - automatically unlocking")
                    self.stopCountdownTimer()
                    self.appLocker.endSession(for: self.profileManager.currentProfile)
                }
            }
        }
    }
    
    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
