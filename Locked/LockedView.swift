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
    @StateObject private var nfcReader = NFCReader()
    @StateObject private var timerManager = TimerManager()
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    private let tagPhrase = "LOCKED-IS-GREAT"
    
    @State private var showWrongTagAlert = false
    @State private var showCreateTagAlert = false
    @State private var nfcWriteSuccess = false
    @State private var showStartSessionWarning = false
    @State private var showSessionStartOptions = false
    @State private var showTimerLock = false
    @State private var timerExpired = false
    
    private var isLocking : Bool {
        return appLocker.isLocking
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Modern gradient background
                    ZStack {
                        LinearGradient(
                            colors: isLocking ? 
                                (timerManager.isTimerActive ? 
                                    [Color(red: 0.9, green: 0.5, blue: 0.2), Color(red: 0.8, green: 0.3, blue: 0.1)] :
                                    [Color(red: 0.8, green: 0.2, blue: 0.2), Color(red: 0.5, green: 0.1, blue: 0.1)]) :
                                [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.1, green: 0.5, blue: 0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.6), value: isLocking)
                    .animation(.easeInOut(duration: 0.6), value: timerManager.isTimerActive)

                    // Lock button layer, centered
                    Group {
                        if isLocking {
                            lockOrUnlockButton(geometry: geometry)
                        } else {
                            lockOrUnlockButton(geometry: geometry)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .offset(y: -geometry.size.height * 0.20)
                    .transition(.opacity)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isLocking)

                    // Profiles strip layer at bottom when unlocked
                    if !isLocking {
                        VStack {
                            Spacer()
                            ProfilesPicker(profileManager: profileManager)
                                .padding(.top, 20)
                        }
                        .ignoresSafeArea(edges: .bottom)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .onAppear {
                setupTimerCallback()
                checkTimerExpiration()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isLocking {
                        Button {
                            showTimerLock = true
                        } label: {
                            Image(systemName: "timer")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isLocking {
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
                Text("Make sure you have access to your NFC tag. You will not be able to unlock without it.")
            }
            .fullScreenCover(isPresented: $showTimerLock) {
                timerLockSheet
            }
        }
        .navigationViewStyle(.stack)
    }
    
    @ViewBuilder
    private func lockOrUnlockButton(geometry: GeometryProxy) -> some View {
        let isIPad = horizontalSizeClass == .regular
        
        VStack(spacing: isIPad ? 32 : 24) {
            Text(isLocking ? "Tap To Unlock" : "Tap To Lock")
                .font(.system(size: isIPad ? 44 : 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    onPrimaryTap()
                }
            }) {
                Image(isLocking ? "RedIcon" : "GreenIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: isIPad ? min(geometry.size.height / 2.5, 400) : geometry.size.height / 3)
                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
            }
            .scaleEffect(isLocking ? 1.0 : 1.05)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isLocking)
            
            // Timer display when active - now below lock icon
            if isLocking && timerManager.isTimerActive {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                            .font(.system(size: isIPad ? 24 : 20, weight: .semibold))
                        Text(timerManager.remainingTimeString)
                            .font(.system(size: isIPad ? 32 : 28, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, isIPad ? 32 : 24)
                    .padding(.vertical, isIPad ? 16 : 12)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    )
                    
                    Text("Time Remaining")
                        .font(.system(size: isIPad ? 16 : 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 8)
            }
            
            // Show unlock button when timer has expired
            if isLocking && timerExpired {
                Button {
                    unlockAfterTimer()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: isIPad ? 18 : 16, weight: .semibold))
                        Text("Unlock Without NFC")
                            .font(.system(size: isIPad ? 20 : 18, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, isIPad ? 32 : 24)
                    .padding(.vertical, isIPad ? 18 : 14)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    )
                }
                .padding(.top, 16)
            }
            
            if !isLocking {
                Button {
                    showStartSessionWarning = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.slash")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Lock Without NFC")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    )
                }
                .padding(.top, 8)
            }
        }
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
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
        }
        .disabled(!NFCNDEFReaderSession.readingAvailable)
    }
    
    private func createLockedTag() {
        nfcReader.write(tagPhrase) { success in
            nfcWriteSuccess = success
            showCreateTagAlert = false
        }
    }
    
    private func setupTimerCallback() {
        timerManager.onTimerExpired = {
            // Set flag to show unlock button instead of auto-unlocking
            Task { @MainActor in
                self.timerExpired = true
            }
        }
    }
    
    private func checkTimerExpiration() {
        // Check if timer has expired and show unlock button
        if let endTime = UserDefaults.standard.object(forKey: "timerLockEndTime") as? Date {
            NSLog("Timer end time found: \(endTime), current time: \(Date()), isLocking: \(appLocker.isLocking)")
            if endTime <= Date() && appLocker.isLocking {
                // Timer expired, show unlock button
                NSLog("Timer has expired! Setting timerExpired = true")
                timerExpired = true
                // Don't clear timer yet - let the unlock button do that
            }
        } else {
            NSLog("No timer end time found in UserDefaults")
        }
    }
    
    private func unlockAfterTimer() {
        appLocker.endSession(for: profileManager.currentProfile)
        timerManager.clearTimer()
        timerExpired = false
    }
}

extension LockedView {
    var timerLockSheet: some View {
        TimerLockView()
            .environmentObject(appLocker)
            .environmentObject(profileManager)
            .environmentObject(timerManager)
    }
}

