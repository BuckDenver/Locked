//
//  ProfileManager.swift
//  Locked
//
//  Created by Brandon Scott on 2025-06-11.
//

import Foundation
import FamilyControls
import ManagedSettings

class ProfileManager: ObservableObject {
    @Published var profiles: [Profile] = []
    @Published var currentProfileId: UUID?
    
    init() {
        loadProfiles()
        ensureDefaultProfile()
    }
    
    var currentProfile: Profile {
        (profiles.first(where: { $0.id == currentProfileId }) ?? profiles.first(where: { $0.name == "Locked" }))!
    }
    
    func loadProfiles() {
        // Attempt to load at least three saved profiles
        if let data = UserDefaults.standard.data(forKey: "savedProfiles"),
           let decoded = try? JSONDecoder().decode([Profile].self, from: data),
           decoded.count >= 3 {
            profiles = decoded
            
            // Migrate any old default icons to updated symbols
            var didUpdateIcons = false
            for index in profiles.indices {
                switch profiles[index].name {
                case "Personal" where profiles[index].icon != "person.fill":
                    profiles[index].icon = "person.fill"
                    didUpdateIcons = true
                case "Work" where profiles[index].icon != "briefcase.fill":
                    profiles[index].icon = "briefcase.fill"
                    didUpdateIcons = true
                case "School" where profiles[index].icon != "graduationcap.fill":
                    profiles[index].icon = "graduationcap.fill"
                    didUpdateIcons = true
                default:
                    break
                }
            }
            if didUpdateIcons {
                saveProfiles()
            }
        } else {
            // Seed three default profiles when no valid saved set exists
            let personalProfile = Profile(name: "Personal", appTokens: [], categoryTokens: [], icon: "person.fill")
            let workProfile     = Profile(name: "Work",     appTokens: [], categoryTokens: [], icon: "briefcase.fill")
            let schoolProfile   = Profile(name: "School",   appTokens: [], categoryTokens: [], icon: "graduationcap.fill")
            profiles = [personalProfile, workProfile, schoolProfile]
            currentProfileId = personalProfile.id
            saveProfiles()
        }

        // Restore or initialize currentProfileId
        if let savedId = UserDefaults.standard.string(forKey: "currentProfileId"),
           let uuid = UUID(uuidString: savedId),
           profiles.contains(where: { $0.id == uuid }) {
            currentProfileId = uuid
        } else {
            currentProfileId = profiles.first?.id
        }
    }
    
    func saveProfiles() {
        if let encoded = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: "savedProfiles")
        }
        UserDefaults.standard.set(currentProfileId?.uuidString, forKey: "currentProfileId")
    }
    
    func addProfile(name: String, icon: String = "bell.slash") {
        let newProfile = Profile(name: name, appTokens: [], categoryTokens: [], icon: icon)
        profiles.append(newProfile)
        currentProfileId = newProfile.id
        saveProfiles()
    }
    
    func addProfile(newProfile: Profile) {
        profiles.append(newProfile)
        currentProfileId = newProfile.id
        saveProfiles()
    }
    
    func updateCurrentProfile(appTokens: Set<ApplicationToken>, categoryTokens: Set<ActivityCategoryToken>) {
        if let index = profiles.firstIndex(where: { $0.id == currentProfileId }) {
            profiles[index].appTokens = appTokens
            profiles[index].categoryTokens = categoryTokens
            saveProfiles()
        }
    }
    
    func setCurrentProfile(id: UUID) {
        if profiles.contains(where: { $0.id == id }) {
            currentProfileId = id
            NSLog("New Current Profile: \(id)")
            saveProfiles()
        }
    }
    
    func deleteProfile(withId id: UUID) {
//        guard !profiles.first(where: { $0.id == id })?.isDefault ?? false else {
//            // Don't delete the default profile
//            return
//        }
        
        profiles.removeAll { $0.id == id }
        
        if currentProfileId == id {
            currentProfileId = profiles.first?.id
        }
        
        saveProfiles()
    }

    func deleteAllNonDefaultProfiles() {
        profiles.removeAll { !$0.isDefault }
        
        if !profiles.contains(where: { $0.id == currentProfileId }) {
            currentProfileId = profiles.first?.id
        }
        
        saveProfiles()
    }
    
    func updateCurrentProfile(name: String, iconName: String) {
        if let index = profiles.firstIndex(where: { $0.id == currentProfileId }) {
            profiles[index].name = name
            profiles[index].icon = iconName
            saveProfiles()
        }
    }

    func deleteCurrentProfile() {
        profiles.removeAll { $0.id == currentProfileId }
        if let firstProfile = profiles.first {
            currentProfileId = firstProfile.id
        }
        saveProfiles()
    }
    
    func updateProfile(
        id: UUID,
        name: String? = nil,
        appTokens: Set<ApplicationToken>? = nil,
        categoryTokens: Set<ActivityCategoryToken>? = nil,
        icon: String? = nil
    ) {
        if let index = profiles.firstIndex(where: { $0.id == id }) {
            if let name = name {
                profiles[index].name = name
            }
            if let appTokens = appTokens {
                profiles[index].appTokens = appTokens
            }
            if let categoryTokens = categoryTokens {
                profiles[index].categoryTokens = categoryTokens
            }
            if let icon = icon {
                profiles[index].icon = icon
            }
            
            if currentProfileId == id {
                currentProfileId = profiles[index].id
            }
            
            saveProfiles()
        }
    }
    
    private func ensureDefaultProfile() {
        if profiles.isEmpty {
            // Initialize three default profiles on first launch
            let personalProfile = Profile(name: "Personal", appTokens: [], categoryTokens: [], icon: "person.fill")
            let workProfile     = Profile(name: "Work",     appTokens: [], categoryTokens: [], icon: "briefcase.fill")
            let schoolProfile   = Profile(name: "School",   appTokens: [], categoryTokens: [], icon: "graduationcap.fill")
            profiles = [personalProfile, workProfile, schoolProfile]
            currentProfileId = personalProfile.id
            saveProfiles()
        } else if currentProfileId == nil {
            if let defaultProfile = profiles.first(where: { $0.name == "Locked" }) {
                currentProfileId = defaultProfile.id
            } else {
                currentProfileId = profiles.first?.id
            }
            saveProfiles()
        }
    }
}

struct Profile: Identifiable, Codable {
    let id: UUID
    var name: String
    var appTokens: Set<ApplicationToken>
    var categoryTokens: Set<ActivityCategoryToken>
    var icon: String // New property for icon

    var isDefault: Bool {
        name == "Locked"
    }

    // New initializer to support default icon
    init(name: String, appTokens: Set<ApplicationToken>, categoryTokens: Set<ActivityCategoryToken>, icon: String = "bell.slash") {
        self.id = UUID()
        self.name = name
        self.appTokens = appTokens
        self.categoryTokens = categoryTokens
        self.icon = icon
    }
}
