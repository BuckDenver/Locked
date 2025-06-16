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
    private let tagPhrase = "LOCKED-IS-GREAT"
    
    @State private var showWrongTagAlert = false
    @State private var showCreateTagAlert = false
    @State private var nfcWriteSuccess = false
    
    private var isLocking : Bool {
        return appLocker.isLocking
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    ZStack {
                        Color("NonBlockingBackground")
                            .opacity(isLocking ? 0 : 1)
                        Color("BlockingBackground")
                            .opacity(isLocking ? 1 : 0)
                    }
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.5), value: isLocking)

                    // Lock button layer, centered
                    Group {
                        if isLocking {
                            lockOrUnlockButton(geometry: geometry)
                        } else {
                            lockOrUnlockButton(geometry: geometry)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .offset(y: -geometry.size.height * 0.15)
                    .transition(.opacity)
                    .animation(.spring(), value: isLocking)

                    // Profiles strip layer at bottom when unlocked
                    if !isLocking {
                        ProfilesPicker(profileManager: profileManager)
                            .frame(height: geometry.size.height / 2)
                            .position(x: geometry.size.width / 2,
                                      y: geometry.size.height * 1)
                    }
                }
            }
            .toolbar {
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
        }
    }
    
    @ViewBuilder
    private func lockOrUnlockButton(geometry: GeometryProxy) -> some View {
        VStack(spacing: 8) {
            Text(isLocking ? "Tap To Unlock" : "Tap To Lock")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .opacity(1)

            Button(action: {
                withAnimation(.spring()) {
                    scanTag()
                }
            }) {
                Image(isLocking ? "RedIcon" : "GreenIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: geometry.size.height / 3)
            }
        }
        .id(isLocking)
    }
    
    private func scanTag() {
        nfcReader.scan { payload in
            if payload == tagPhrase {
                NSLog("Toggling lock")
                appLocker.toggleLocking(for: profileManager.currentProfile)
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
            Text("New Lock")
                .bold()
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
}
