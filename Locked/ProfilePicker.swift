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
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var editingProfile: Profile?
    
    var body: some View {
        let isIPad = horizontalSizeClass == .regular
        
        VStack(spacing: isIPad ? 24 : 20) {
            VStack(spacing: 6) {
                Text("Profiles")
                    .font(.system(size: isIPad ? 28 : 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Tap to select • Long press to edit")
                    .font(.system(size: isIPad ? 15 : 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.top, isIPad ? 32 : 24)
            
            // Static HStack without ScrollView
            HStack(spacing: isIPad ? 28 : 20) {
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
            .padding(.horizontal, isIPad ? 40 : 20)
            .padding(.bottom, isIPad ? 40 : 32)
        }
        .frame(maxWidth: isIPad ? 900 : .infinity)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: isIPad ? 40 : 30, style: .continuous)
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
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        let isIPad = horizontalSizeClass == .regular
        
        VStack(spacing: isIPad ? 12 : 10) {
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
                    .frame(width: isIPad ? 90 : 70, height: isIPad ? 90 : 70)
                    .shadow(color: isSelected ? .blue.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
                
                Image(systemName: icon)
                    .font(.system(size: isIPad ? 40 : 32, weight: .semibold))
                    .foregroundColor(.white)
                    .symbolEffect(.bounce, value: isSelected)
            }
            
            Text(name)
                .font(.system(size: isIPad ? 16 : 14, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            if let apps = appsBlocked, let isAllowMode = isAllowListMode {
                HStack(spacing: 4) {
                    Image(systemName: isAllowMode ? "checkmark.shield.fill" : "lock.shield.fill")
                        .font(.system(size: isIPad ? 11 : 9))
                    Text("\(apps)")
                        .font(.system(size: isIPad ? 13 : 11, weight: .medium, design: .rounded))
                }
                .foregroundColor(isAllowMode ? .green : .orange)
                .padding(.horizontal, isIPad ? 10 : 8)
                .padding(.vertical, isIPad ? 5 : 4)
                .background(
                    Capsule()
                        .fill((isAllowMode ? Color.green : Color.orange).opacity(0.15))
                )
            }
        }
        .frame(width: isIPad ? 130 : 100)
        .padding(.vertical, isIPad ? 20 : 16)
        .background(
            RoundedRectangle(cornerRadius: isIPad ? 22 : 18, style: .continuous)
                .fill(isSelected ? .thinMaterial : .ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: isIPad ? 22 : 18, style: .continuous)
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
