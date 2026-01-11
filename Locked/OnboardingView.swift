//
//  OnboardingView.swift
//  Locked
//
//  Created by Assistant on 2026-01-10.
//

import SwiftUI
import CoreNFC
import UserNotifications
import FamilyControls

struct OnboardingView: View {
    @StateObject private var nfcReader = NFCReader()
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject private var profileManager: ProfileManager
    
    @State private var currentStep = 0
    @State private var showNFCScanner = false
    @State private var nfcWriteSuccess = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var notificationsGranted = false
    @State private var screenTimeGranted = false
    @State private var activitySelection = FamilyActivitySelection()
    @State private var showAppPicker = false
    
    private let tagPhrase = "LOCKED-IS-GREAT"
    
    var body: some View {
        ZStack {
            // Background - dynamic color that adapts to light/dark mode
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if currentStep == 0 {
                    welcomeStep
                } else if currentStep == 1 {
                    permissionsStep
                } else if currentStep == 2 {
                    appSelectionStep
                } else if currentStep == 3 {
                    nfcExplanationStep
                } else if currentStep == 4 {
                    nfcSetupStep
                }
            }
        }
        .alert("NFC Tag Setup", isPresented: $nfcWriteSuccess) {
            Button("Continue") {
                completeOnboarding()
            }
        } message: {
            Text("Your NFC tag has been successfully configured! You can now use it to lock and unlock your apps.")
        }
        .alert("Setup Error", isPresented: $showErrorAlert) {
            Button("Try Again", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Step 1: Welcome
    
    private var welcomeStep: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 100))
                .foregroundColor(.primary)
            
            Text("Welcome to Locked")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("Take control of your app usage with NFC-powered app locking")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    currentStep = 1
                }
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
    
    // MARK: - Step 2: Permissions
    
    private var permissionsStep: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.primary)
            
            Text("Enable Permissions")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Locked needs these permissions to work properly")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack(spacing: 16) {
                // Notifications Permission
                PermissionButton(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Get alerts when apps lock and unlock",
                    isGranted: notificationsGranted,
                    action: requestNotificationPermission
                )
                
                // Screen Time Permission
                PermissionButton(
                    icon: "hourglass",
                    title: "Screen Time",
                    description: "Required to block and unblock apps",
                    isGranted: screenTimeGranted,
                    action: requestScreenTimePermission
                )
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            VStack(spacing: 16) {
                if notificationsGranted && screenTimeGranted {
                    Button(action: {
                        withAnimation {
                            currentStep = 2
                        }
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                } else {
                    Text("Please enable both permissions to continue")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: {
                    withAnimation {
                        currentStep = 0
                    }
                }) {
                    Text("Back")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
        .onAppear {
            checkPermissions()
        }
    }
    
    // MARK: - Step 3: App Selection
    
    private var appSelectionStep: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "apps.iphone")
                .font(.system(size: 80))
                .foregroundColor(.primary)
            
            Text("Select Apps to Lock")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Choose which apps you want to lock in your Personal profile. You can always change this later in settings.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Select Apps Button
            Button(action: {
                showAppPicker = true
            }) {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Choose Apps to Block")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
            
            // Selection Summary
            if activitySelection.applicationTokens.count > 0 || activitySelection.categoryTokens.count > 0 {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Selection Complete")
                            .font(.headline)
                            .foregroundColor(.green)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.blue)
                        Text("Apps Selected:")
                            .font(.subheadline)
                        Spacer()
                        Text("\(activitySelection.applicationTokens.count)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                    
                    if !activitySelection.categoryTokens.isEmpty {
                        HStack {
                            Image(systemName: "square.grid.2x2.fill")
                                .foregroundColor(.blue)
                            Text("Categories Selected:")
                                .font(.subheadline)
                            Spacer()
                            Text("\(activitySelection.categoryTokens.count)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(uiColor: .secondarySystemBackground))
                        )
                    }
                }
                .padding(.horizontal, 40)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "app.badge")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No apps selected yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Tap the button above to choose apps")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    // Save selection and continue
                    savePersonalProfile()
                    withAnimation {
                        currentStep = 3
                    }
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    withAnimation {
                        currentStep = 1
                    }
                }) {
                    Text("Back")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
        .familyActivityPicker(isPresented: $showAppPicker, selection: $activitySelection)
    }
    
    // MARK: - Step 4: NFC Explanation
    
    private var nfcExplanationStep: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "wave.3.right.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.primary)
            
            Text("Set Up NFC Tag")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
            
            Text("An NFC tag is required to unlock your apps. This ensures maximum security and commitment.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(
                    icon: "lock.fill",
                    title: "True Commitment",
                    description: "Physical NFC tags prevent impulse app usage"
                )
                
                FeatureRow(
                    icon: "hand.tap.fill",
                    title: "Easy Access",
                    description: "Quick tap to unlock when you really need it"
                )
                
                FeatureRow(
                    icon: "shield.fill",
                    title: "Maximum Security",
                    description: "Only your physical tag can unlock apps"
                )
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    withAnimation {
                        currentStep = 4
                    }
                }) {
                    Text("Continue to NFC Setup")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    withAnimation {
                        currentStep = 2
                    }
                }) {
                    Text("Back")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
    
    // MARK: - Step 5: NFC Setup
    
    private var nfcSetupStep: some View {
        VStack(spacing: 30) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 160, height: 160)
                
                Image(systemName: "wave.3.right")
                    .font(.system(size: 80))
                    .foregroundColor(.primary)
            }
            
            Text("Set Up Your NFC Tag")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 16) {
                InstructionRow(number: 1, text: "Get an NFC sticker or card")
                InstructionRow(number: 2, text: "Tap 'Program Tag' below")
                InstructionRow(number: 3, text: "Hold your iPhone near the NFC tag")
                InstructionRow(number: 4, text: "Wait for confirmation")
            }
            .padding(.horizontal, 40)
            
            if !NFCNDEFReaderSession.readingAvailable {
                Text("⚠️ NFC is not available on this device")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Background tip
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.blue)
                    Text("Tip")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    Spacer()
                }
                
                Text("This app works best when kept in the background. Avoid force-quitting it to ensure app locking continues to work properly.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 40)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    writeNFCTag()
                }) {
                    HStack {
                        Image(systemName: "wave.3.right")
                        Text("Program Tag")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(!NFCNDEFReaderSession.readingAvailable)
                
                Button(action: {
                    withAnimation {
                        currentStep = 3
                    }
                }) {
                    Text("Back")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
    
    // MARK: - Helper Views
    
    private struct PermissionButton: View {
        let icon: String
        let title: String
        let description: String
        let isGranted: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(isGranted ? Color.green.opacity(0.2) : Color.primary.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: isGranted ? "checkmark" : icon)
                            .font(.title2)
                            .foregroundColor(isGranted ? .green : .primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    if !isGranted {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .secondarySystemBackground))
                )
            }
            .disabled(isGranted)
        }
    }
    
    private struct FeatureRow: View {
        let icon: String
        let title: String
        let description: String
        
        var body: some View {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private struct InstructionRow: View {
        let number: Int
        let text: String
        
        var body: some View {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Text("\(number)")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Text(text)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Actions
    
    private func savePersonalProfile() {
        // Find the Personal profile and update it with the selected apps
        if let personalProfile = profileManager.profiles.first(where: { $0.name == "Personal" }) {
            profileManager.updateProfile(
                id: personalProfile.id,
                appTokens: activitySelection.applicationTokens,
                categoryTokens: activitySelection.categoryTokens
            )
        }
    }
    
    private func requestNotificationPermission() {
        // First check if already granted
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .authorized {
                    self.notificationsGranted = true
                    return
                } else if settings.authorizationStatus == .denied {
                    // Already denied - direct to settings
                    self.errorMessage = "Notifications are disabled. Please enable them in Settings > Locked > Notifications."
                    self.showErrorAlert = true
                    return
                }
                
                // Not determined yet - request permission
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.errorMessage = "Failed to request notification permission: \(error.localizedDescription)"
                            self.showErrorAlert = true
                        } else {
                            self.notificationsGranted = granted
                            if !granted {
                                self.errorMessage = "Notifications are required for Locked to work properly. Please enable them in Settings."
                                self.showErrorAlert = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func requestScreenTimePermission() {
        // First check current status
        let status = AuthorizationCenter.shared.authorizationStatus
        
        if status == .approved {
            screenTimeGranted = true
            return
        } else if status == .denied {
            errorMessage = "Screen Time access is denied. Please enable it in Settings > Screen Time > Locked."
            showErrorAlert = true
            return
        }
        
        // Not determined yet - request permission
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                await MainActor.run {
                    self.screenTimeGranted = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Screen Time access is required for Locked to block apps. Error: \(error.localizedDescription)"
                    self.showErrorAlert = true
                    self.screenTimeGranted = false
                }
            }
        }
    }
    
    private func checkPermissions() {
        // Check notification permission
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsGranted = settings.authorizationStatus == .authorized
            }
        }
        
        // Check Screen Time permission
        Task {
            let status = AuthorizationCenter.shared.authorizationStatus
            await MainActor.run {
                self.screenTimeGranted = (status == .approved)
            }
        }
    }
    
    private func writeNFCTag() {
        guard NFCNDEFReaderSession.readingAvailable else {
            errorMessage = "NFC is not available on this device. You need an iPhone with NFC capability to use Locked."
            showErrorAlert = true
            return
        }
        
        nfcReader.write(tagPhrase) { success in
            if success {
                nfcWriteSuccess = true
            } else {
                errorMessage = "Failed to write NFC tag. Please try again and make sure to hold your device close to the tag."
                showErrorAlert = true
            }
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environmentObject(ProfileManager())
}
