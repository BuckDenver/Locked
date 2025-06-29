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
        
        var selection = FamilyActivitySelection()
        selection.applicationTokens = profile?.appTokens ?? []
        selection.categoryTokens = profile?.categoryTokens ?? []
        _activitySelection = State(initialValue: selection)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Details")) {
                    VStack(alignment: .leading) {
                        Text("Profile Name")
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
                            Text("Choose Icon")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("App Configuration")) {
                    Button(action: { showAppSelection = true }) {
                        Text("Configure Locked Apps")
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Locked Apps:")
                            Spacer()
                            Text("\(activitySelection.applicationTokens.count)")
                                .fontWeight(.bold)
                        }
                        HStack {
                            Text("Locked Categories:")
                            Spacer()
                            Text("\(activitySelection.categoryTokens.count)")
                                .fontWeight(.bold)
                        }
                        Text("Locked can't list the names of the apps due to privacy concerns, it is only able to see the amount of apps selected in the configuration screen.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
            }
            .navigationTitle(profile == nil ? "Add Profile" : "Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel", action: onDismiss),
                trailing: Button("Save", action: handleSave)
                    .disabled(profileName.isEmpty)
            )
            .sheet(isPresented: $showSymbolsPicker) {
                SymbolsPicker(selection: $profileIcon, title: "Pick an icon", autoDismiss: true)
            }
            .sheet(isPresented: $showAppSelection) {
                NavigationView {
                    FamilyActivityPicker(selection: $activitySelection)
                        .navigationTitle("Select Apps")
                        .navigationBarItems(trailing: Button("Done") {
                            showAppSelection = false
                        })
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
                categoryTokens: activitySelection.categoryTokens,
                icon: profileIcon
            )
        } else {
            let newProfile = Profile(
                name: profileName,
                appTokens: activitySelection.applicationTokens,
                categoryTokens: activitySelection.categoryTokens,
                icon: profileIcon
            )
            profileManager.addProfile(newProfile: newProfile)
        }
        onDismiss()
    }
}
