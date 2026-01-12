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
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("Profiles")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Tap to select • Long press to edit")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 24)
            
            // Static HStack without ScrollView
            HStack(spacing: 20) {
                ForEach(profileManager.profiles) { profile in
                    ProfileCell(profile: profile, isSelected: profile.id == profileManager.currentProfileId)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                profileManager.setCurrentProfile(id: profile.id)
                            }
                        }
                        .onLongPressGesture {
                            editingProfile = profile
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
                .ignoresSafeArea(edges: .bottom)
        )
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
    let isAllowListMode: Bool?
    var isDashed: Bool = false
    var hasDivider: Bool = true

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isSelected ? 
                                [Color.blue.opacity(0.6), Color.purple.opacity(0.6)] : 
                                [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .shadow(color: isSelected ? .blue.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
                
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white)
                    .symbolEffect(.bounce, value: isSelected)
            }
            
            Text(name)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            if let apps = appsBlocked, let isAllowMode = isAllowListMode {
                HStack(spacing: 4) {
                    Image(systemName: isAllowMode ? "checkmark.shield.fill" : "lock.shield.fill")
                        .font(.system(size: 9))
                    Text("\(apps)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundColor(isAllowMode ? .green : .orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill((isAllowMode ? Color.green : Color.orange).opacity(0.15))
                )
            }
        }
        .frame(width: 100)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isSelected ? .thinMaterial : .ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            isSelected ? 
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) : 
                                LinearGradient(
                                    colors: [.gray.opacity(0.3), .gray.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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
            isSelected: isSelected,
            isAllowListMode: profile.isAllowListMode
        )
    }
}
