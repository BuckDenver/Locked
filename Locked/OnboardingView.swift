//
//  OnboardingView.swift
//  Locked
//
//  Created by Assistant on 2026-01-10.
//

import SwiftUI
import CoreNFC

struct OnboardingView: View {
    @StateObject private var nfcReader = NFCReader()
    @Binding var hasCompletedOnboarding: Bool
    
    @State private var currentStep = 0
    @State private var showNFCScanner = false
    @State private var nfcWriteSuccess = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
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
                    nfcExplanationStep
                } else if currentStep == 2 {
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
    
    // MARK: - Step 2: NFC Explanation
    
    private var nfcExplanationStep: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "wave.3.right.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.primary)
            
            Text("Why NFC?")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
            
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
                    title: "Secure",
                    description: "No bypassing - requires your physical tag"
                )
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    withAnimation {
                        currentStep = 2
                    }
                }) {
                    Text("Set Up NFC Tag")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
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
    }
    
    // MARK: - Step 3: NFC Setup
    
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
    }
    
    // MARK: - Helper Views
    
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
        UserDefaults.standard.set(true, forKey: "hasUsedNFC")
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
