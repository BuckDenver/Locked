//
//  ProfileFormView.swift
//  Locked
//
//  Created by Brandon Scott on 2025-06-11.
//

import SwiftUI
import SFSymbolsPicker
import FamilyControls

struct ProfileFormView: View {
    @ObservedObject var profileManager: ProfileManager
    @State private var profileName: String
    @State private var profileIcon: String
    @State private var isAllowListMode: Bool
    @State private var showSymbolsPicker = false
    @State private var showAppSelection = false
    @State private var activitySelection: FamilyActivitySelection
    @State private var showDeleteConfirmation = false
    let profile: Profile?
    let onDismiss: () -> Void
    
    init(profile: Profile? = nil, profileManager: ProfileManager, onDismiss: @escaping () -> Void) {
        self.profile = profile
        self.profileManager = profileManager
        self.onDismiss = onDismiss
        _profileName = State(initialValue: profile?.name ?? "")
        _profileIcon = State(initialValue: profile?.icon ?? "bell.slash")
        _isAllowListMode = State(initialValue: profile?.isAllowListMode ?? false)
        
        var selection = FamilyActivitySelection()
        selection.applicationTokens = profile?.appTokens ?? []
        selection.categoryTokens = profile?.categoryTokens ?? []
        _activitySelection = State(initialValue: selection)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profile Name")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        TextField("Enter profile name", text: $profileName)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .textFieldStyle(.plain)
                            .padding(.vertical, 8)
                    }
                    
                    Button(action: { showSymbolsPicker = true }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 56, height: 56)
                                
                                Image(systemName: profileIcon)
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Profile Icon")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text("Tap to change")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                
                Section {
                    Toggle(isOn: $isAllowListMode) {
                        HStack(spacing: 12) {
                            Image(systemName: isAllowListMode ? "checkmark.shield.fill" : "lock.shield.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(isAllowListMode ? .green : .orange)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(isAllowListMode ? "Allow List Mode" : "Lock List Mode")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                Text(isAllowListMode ? "Only selected apps available" : "Selected apps will be locked")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                } header: {
                    Text("Mode")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                
                Section {
                    Button(action: { showAppSelection = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "apps.iphone")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.blue)
                                .frame(width: 32)
                            
                            Text(isAllowListMode ? "Configure Allowed Apps" : "Configure Locked Apps")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label(isAllowListMode ? "Allowed Apps" : "Locked Apps", 
                                  systemImage: "app.badge")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(activitySelection.applicationTokens.count)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.15))
                                )
                        }
                        
                        if !isAllowListMode {
                            HStack {
                                Label("Locked Categories", systemImage: "square.grid.2x2")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(activitySelection.categoryTokens.count)")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.orange.opacity(0.15))
                                    )
                            }
                        }
                        
                        Text("Due to privacy, Locked cannot display specific app names—only the count of selected apps.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                } header: {
                    Text("App Configuration")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(profile == nil ? "Add Profile" : "Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onDismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        handleSave()
                    } label: {
                        Text("Save")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .disabled(profileName.isEmpty)
                }
            }
            .sheet(isPresented: $showSymbolsPicker) {
                SymbolsPicker(selection: $profileIcon, title: "Pick an icon", autoDismiss: true)
            }
            .sheet(isPresented: $showAppSelection) {
                NavigationView {
                    FamilyActivityPicker(selection: $activitySelection)
                        .navigationTitle("Select Apps")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Save") {
                                    showAppSelection = false
                                }
                            }
                        }
                }
                .navigationViewStyle(.stack)
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func handleSave() {
        if let existingProfile = profile {
            profileManager.updateProfile(
                id: existingProfile.id,
                name: profileName,
                appTokens: activitySelection.applicationTokens,
                categoryTokens: isAllowListMode ? [] : activitySelection.categoryTokens, // Clear categories in allow list mode
                icon: profileIcon,
                isAllowListMode: isAllowListMode
            )
        } else {
            let newProfile = Profile(
                name: profileName,
                appTokens: activitySelection.applicationTokens,
                categoryTokens: isAllowListMode ? [] : activitySelection.categoryTokens, // Clear categories in allow list mode
                icon: profileIcon,
                isAllowListMode: isAllowListMode
            )
            profileManager.addProfile(newProfile: newProfile)
        }
        onDismiss()
    }
}
