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
                Section() {
                    VStack(alignment: .leading) {
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Enter profile name", text: $profileName)
                    }
                    
                    Button(action: { showSymbolsPicker = true }) {
                        HStack {
                            Image(systemName: profileIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                                .foregroundColor(.blue)
                            Text("Choose Icon")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Mode")) {
                    Toggle(isOn: $isAllowListMode) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isAllowListMode ? "Allow List" : "Lock List")
                                .fontWeight(.medium)
                            Text(isAllowListMode ? "Only selected apps will be available" : "Selected apps will be locked")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("App Configuration")) {
                    Button(action: { showAppSelection = true }) {
                        Text(isAllowListMode ? "Configure Allowed Apps" : "Configure Locked Apps")
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(isAllowListMode ? "Allowed Apps:" : "Locked Apps:")
                            Spacer()
                            Text("\(activitySelection.applicationTokens.count)")
                                .fontWeight(.bold)
                        }
                        if !isAllowListMode {
                            HStack {
                                Text("Locked Categories:")
                                Spacer()
                                Text("\(activitySelection.categoryTokens.count)")
                                    .fontWeight(.bold)
                            }
                        }
                        Text("Locked can't list the names of the apps due to privacy concerns, it's only able to see the amount of apps selected in the configuration screen.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
            }
            .navigationTitle(profile == nil ? "Add Profile" : "Edit Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onDismiss)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: handleSave)
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
            }
        }
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
