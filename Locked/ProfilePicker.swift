//
//  ProfilePicker.swift
//  Locked
//
//  Created by Brandon Scott on 2025-06-11.
//

import SwiftUI
import FamilyControls

struct ProfilesPicker: View {
    @ObservedObject var profileManager: ProfileManager
    @State private var editingProfile: Profile?
    
    var body: some View {
        VStack {
            Text("Profiles")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)

            Text("Long Press A Profile To Edit")
                .font(.subheadline)
                .foregroundColor(Color(.darkGray))
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            HStack(spacing: 30) {
                ForEach(profileManager.profiles) { profile in
                    ProfileCell(profile: profile, isSelected: profile.id == profileManager.currentProfileId)
                        .onTapGesture {
                            profileManager.setCurrentProfile(id: profile.id)
                        }
                        .onLongPressGesture {
                            editingProfile = profile
                        }
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color("ProfileSectionBackground"))
        .sheet(item: $editingProfile) { profile in
            ProfileFormView(profile: profile, profileManager: profileManager) {
                editingProfile = nil
            }
        }
    }
}

struct ProfileCellBase: View {
    let name: String
    let icon: String
    let appsBlocked: Int?
    let categoriesBlocked: Int?
    let isSelected: Bool
    var isDashed: Bool = false
    var hasDivider: Bool = true

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
            if hasDivider {
                Divider().padding(2)
            }
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            if let apps = appsBlocked, let categories = categoriesBlocked {
                Text("A: \(apps) | C: \(categories)")
                    .font(.system(size: 10))
            }
        }
        .frame(width: 90, height: 90)
        .padding(2)
        .background(isSelected ? Color.blue.opacity(0.3) : Color.secondary.opacity(0.2))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isSelected ? Color.blue : (isDashed ? Color.secondary : Color.clear),
                    style: StrokeStyle(lineWidth: 2, dash: isDashed ? [5] : [])
                )
        )
    }
}

struct ProfileCell: View {
    let profile: Profile
    let isSelected: Bool

    var body: some View {
        ProfileCellBase(
            name: profile.name,
            icon: profile.icon,
            appsBlocked: profile.appTokens.count,
            categoriesBlocked: profile.categoryTokens.count,
            isSelected: isSelected
        )
    }
}
