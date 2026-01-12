//
//  OnboardingView.swift
//  Locked
//
//  Created by Brandon Scott on 2025-01-12.
//

import SwiftUI
import FamilyControls
import UserNotifications
import CoreNFC

struct OnboardingView: View {
    @StateObject private var onboardingManager = OnboardingManager()
    @EnvironmentObject var profileManager: ProfileManager
    @Binding var isOnboardingComplete: Bool
    
    var body: some View {
        TabView(selection: $onboardingManager.currentPage) {
            WelcomePage(onboardingManager: onboardingManager)
                .tag(0)
            
            PermissionsPage(onboardingManager: onboardingManager)
                .tag(1)
            
            AppSelectionPage(onboardingManager: onboardingManager, profileManager: profileManager)
                .tag(2)
            
            NFCSetupPage(onboardingManager: onboardingManager, isOnboardingComplete: $isOnboardingComplete)
                .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .ignoresSafeArea()
    }
}

// MARK: - Welcome Page
struct WelcomePage: View {
    @ObservedObject var onboardingManager: OnboardingManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.1, green: 0.5, blue: 0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: horizontalSizeClass == .regular ? 50 : 40) {
                Spacer()
                
                // App Icon
                Image("GreenIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: horizontalSizeClass == .regular ? 220 : 180, 
                           height: horizontalSizeClass == .regular ? 220 : 180)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                
                VStack(spacing: 16) {
                    Text("Welcome to Locked")
                        .font(.system(size: horizontalSizeClass == .regular ? 52 : 40, 
                                    weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Take control of your digital wellbeing with NFC-powered app locking")
                        .font(.system(size: horizontalSizeClass == .regular ? 22 : 18, 
                                    weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, horizontalSizeClass == .regular ? 100 : 40)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        onboardingManager.nextPage()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text("Get Started")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: horizontalSizeClass == .regular ? 500 : .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                    )
                }
                .padding(.horizontal, horizontalSizeClass == .regular ? 150 : 40)
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Permissions Page
struct PermissionsPage: View {
    @ObservedObject var onboardingManager: OnboardingManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.4, green: 0.2, blue: 0.8), Color(red: 0.2, green: 0.4, blue: 0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: horizontalSizeClass == .regular ? 50 : 40) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: horizontalSizeClass == .regular ? 100 : 80, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                    
                    Text("Grant Permissions")
                        .font(.system(size: horizontalSizeClass == .regular ? 44 : 36, 
                                    weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Locked needs access to manage app restrictions and send you reminders")
                        .font(.system(size: horizontalSizeClass == .regular ? 20 : 17, 
                                    weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, horizontalSizeClass == .regular ? 100 : 40)
                }
                
                VStack(spacing: 20) {
                    PermissionRowButton(
                        icon: "hourglass",
                        title: "Screen Time",
                        description: "Control which apps can be used",
                        isGranted: onboardingManager.screenTimeAuthorized,
                        isRequesting: onboardingManager.isRequestingScreenTime,
                        action: {
                            Task {
                                await onboardingManager.requestScreenTime()
                            }
                        }
                    )
                    
                    PermissionRowButton(
                        icon: "bell.badge.fill",
                        title: "Notifications",
                        description: "Receive lock reminders",
                        isGranted: onboardingManager.notificationsAuthorized,
                        isRequesting: onboardingManager.isRequestingNotifications,
                        action: {
                            Task {
                                await onboardingManager.requestNotifications()
                            }
                        }
                    )
                }
                .padding(.horizontal, horizontalSizeClass == .regular ? 150 : 30)
                .frame(maxWidth: horizontalSizeClass == .regular ? 700 : .infinity)
                
                Spacer()
                
                VStack(spacing: 16) {
                    if onboardingManager.allPermissionsGranted {
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                onboardingManager.nextPage()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Text("Continue")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: horizontalSizeClass == .regular ? 500 : .infinity)
                            .padding(.vertical, 18)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                            )
                        }
                    }
                }
                .padding(.horizontal, horizontalSizeClass == .regular ? 150 : 40)
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - App Selection Page
struct AppSelectionPage: View {
    @ObservedObject var onboardingManager: OnboardingManager
    @ObservedObject var profileManager: ProfileManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var activitySelection = FamilyActivitySelection()
    @State private var showAppPicker = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.9, green: 0.5, blue: 0.2), Color(red: 0.8, green: 0.3, blue: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: horizontalSizeClass == .regular ? 50 : 40) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "apps.iphone.badge.plus")
                        .font(.system(size: horizontalSizeClass == .regular ? 100 : 80, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                    
                    Text("Select Distracting Apps")
                        .font(.system(size: horizontalSizeClass == .regular ? 44 : 36, 
                                    weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Choose at least one app you find distracting. These will be added to your Personal profile")
                        .font(.system(size: horizontalSizeClass == .regular ? 20 : 17, 
                                    weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, horizontalSizeClass == .regular ? 100 : 40)
                }
                
                // App count indicator
                if !activitySelection.applicationTokens.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "apps.iphone")
                            .font(.system(size: 20, weight: .semibold))
                        Text("\(activitySelection.applicationTokens.count) app\(activitySelection.applicationTokens.count == 1 ? "" : "s") selected")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button {
                        showAppPicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "apps.iphone")
                                .font(.system(size: 18, weight: .bold))
                            Text(hasSelectedApps ? "Change Selection" : "Select Apps")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: horizontalSizeClass == .regular ? 500 : .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                        )
                    }
                    
                    Button {
                        saveAppsToPersonalProfile()
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            onboardingManager.nextPage()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text("Continue")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: horizontalSizeClass == .regular ? 500 : .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                        )
                    }
                    .disabled(!hasSelectedApps)
                    .opacity(hasSelectedApps ? 1.0 : 0.5)
                }
                .padding(.horizontal, horizontalSizeClass == .regular ? 150 : 40)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            loadPersonalProfileSelection()
        }
        .sheet(isPresented: $showAppPicker) {
            NavigationView {
                FamilyActivityPicker(selection: $activitySelection)
                    .navigationTitle("Select Distracting Apps")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showAppPicker = false
                            }
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                    }
            }
            .navigationViewStyle(.stack)
        }
    }
    
    private var hasSelectedApps: Bool {
        !activitySelection.applicationTokens.isEmpty
    }
    
    private func loadPersonalProfileSelection() {
        // Load existing Personal profile selection if it exists
        if let personalProfile = profileManager.profiles.first(where: { $0.name == "Personal" }) {
            activitySelection.applicationTokens = personalProfile.appTokens
            activitySelection.categoryTokens = personalProfile.categoryTokens
        }
    }
    
    private func saveAppsToPersonalProfile() {
        // Find the Personal profile and update it with selected apps
        if let personalProfile = profileManager.profiles.first(where: { $0.name == "Personal" }) {
            profileManager.updateProfile(
                id: personalProfile.id,
                appTokens: activitySelection.applicationTokens,
                categoryTokens: activitySelection.categoryTokens
            )
        }
    }
}

// MARK: - NFC Setup Page
struct NFCSetupPage: View {
    @ObservedObject var onboardingManager: OnboardingManager
    @Binding var isOnboardingComplete: Bool
    @StateObject private var nfcReader = NFCReader()
    @State private var showWriteAlert = false
    @State private var writeSuccess = false
    @State private var hasWrittenTag = false
    @State private var showDebugSkipAlert = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    private let tagPhrase = "LOCKED-IS-GREAT"
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.8, green: 0.2, blue: 0.2), Color(red: 0.5, green: 0.1, blue: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: horizontalSizeClass == .regular ? 50 : 40) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image("RedIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: horizontalSizeClass == .regular ? 180 : 140, 
                               height: horizontalSizeClass == .regular ? 180 : 140)
                        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                    
                    Text("Setup Your NFC Tag")
                        .font(.system(size: horizontalSizeClass == .regular ? 44 : 36, 
                                    weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Create your lock tag by writing to an NFC chip. You'll need this tag to lock and unlock your apps")
                        .font(.system(size: horizontalSizeClass == .regular ? 20 : 17, 
                                    weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, horizontalSizeClass == .regular ? 100 : 40)
                }
                
                VStack(spacing: 16) {
                    NFCInfoRow(icon: "1.circle.fill", text: "Tap 'Create Lock Tag' below")
                    NFCInfoRow(icon: "2.circle.fill", text: "Hold your iPhone near an NFC tag")
                    NFCInfoRow(icon: "3.circle.fill", text: "Wait for confirmation")
                }
                .padding(.horizontal, horizontalSizeClass == .regular ? 150 : 40)
                .frame(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
                
                if hasWrittenTag {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                        Text("Tag Created Successfully!")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    if !hasWrittenTag {
                        Button {
                            createLockedTag()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "dot.radiowaves.left.and.right")
                                    .font(.system(size: 18, weight: .bold))
                                Text("Create Lock Tag")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: horizontalSizeClass == .regular ? 500 : .infinity)
                            .padding(.vertical, 18)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                            )
                        }
                        .disabled(!NFCNDEFReaderSession.readingAvailable)
                        
                        #if DEBUG
                        // Debug skip button for simulator testing
                        if !NFCNDEFReaderSession.readingAvailable {
                            Button {
                                showDebugSkipAlert = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 18, weight: .bold))
                                    Text("Skip NFC Setup (Debug)")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: horizontalSizeClass == .regular ? 500 : .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    Capsule()
                                        .fill(Color.yellow.opacity(0.3))
                                )
                            }
                        }
                        #endif
                    } else {
                        Button {
                            completeOnboarding()
                        } label: {
                            HStack(spacing: 12) {
                                Text("Finish Setup")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                Image(systemName: "checkmark")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: horizontalSizeClass == .regular ? 500 : .infinity)
                            .padding(.vertical, 18)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                            )
                        }
                    }
                }
                .padding(.horizontal, horizontalSizeClass == .regular ? 150 : 40)
                .padding(.bottom, 50)
            }
        }
        .alert("Tag Creation", isPresented: $showWriteAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(writeSuccess ? "Lock tag created successfully!" : "Failed to create lock tag. Please try again.")
        }
        .alert("Skip NFC Setup?", isPresented: $showDebugSkipAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Skip", role: .destructive) {
                debugSkipNFCSetup()
            }
        } message: {
            Text("This will skip NFC tag creation for testing in the simulator. This is only available in debug builds.")
        }
    }
    
    private func createLockedTag() {
        nfcReader.write(tagPhrase) { success in
            writeSuccess = success
            hasWrittenTag = success
            showWriteAlert = true
        }
    }
    
    #if DEBUG
    private func debugSkipNFCSetup() {
        writeSuccess = true
        hasWrittenTag = true
    }
    #endif
    
    private func completeOnboarding() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            isOnboardingComplete = true
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }
    }
}

// MARK: - Supporting Views
struct PermissionRowButton: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let isRequesting: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if !isGranted && !isRequesting {
                action()
            }
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isGranted ? Color.green.opacity(0.3) : Color.white.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    if isRequesting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if isGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.green)
                } else if !isRequesting {
                    Text("Allow")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.5))
                        )
                        .fixedSize()
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
        }
        .disabled(isGranted || isRequesting)
        .buttonStyle(.plain)
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isGranted ? Color.green.opacity(0.3) : Color.white.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.green)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
}

struct NFCInfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 40)
            
            Text(text)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

// MARK: - Onboarding Manager
@MainActor
class OnboardingManager: ObservableObject {
    @Published var currentPage = 0
    @Published var screenTimeAuthorized = false
    @Published var notificationsAuthorized = false
    @Published var isRequestingScreenTime = false
    @Published var isRequestingNotifications = false
    
    var allPermissionsGranted: Bool {
        screenTimeAuthorized && notificationsAuthorized
    }
    
    init() {
        // Only check status, don't request
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        // Check Screen Time status without requesting
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved:
            screenTimeAuthorized = true
        default:
            screenTimeAuthorized = false
        }
        
        // Check Notifications status
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                notificationsAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func nextPage() {
        if currentPage < 4 {
            currentPage += 1
        }
    }
    
    func requestScreenTime() async {
        guard !screenTimeAuthorized else { return }
        
        isRequestingScreenTime = true
        
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            screenTimeAuthorized = true
        } catch {
            print("Failed to request Screen Time authorization: \(error)")
            screenTimeAuthorized = false
        }
        
        isRequestingScreenTime = false
    }
    
    func requestNotifications() async {
        guard !notificationsAuthorized else { return }
        
        isRequestingNotifications = true
        
        do {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                notificationsAuthorized = granted
            } else {
                notificationsAuthorized = settings.authorizationStatus == .authorized
            }
        } catch {
            print("Failed to request Notifications authorization: \(error)")
            notificationsAuthorized = false
        }
        
        isRequestingNotifications = false
    }
}
