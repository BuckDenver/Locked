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
        GeometryReader { geometry in
            VStack(spacing: 12) {
                // Header
                VStack(spacing: 4) {
                    Text("Profiles")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)

                    Text("Tap to select • Long press to edit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                }
                .padding(.top, 16)
                
                // Profile Cards Container
                HStack(spacing: calculateSpacing(for: geometry.size.width)) {
                    ForEach(profileManager.profiles) { profile in
                        ProfileCard(
                            profile: profile,
                            isSelected: profile.id == profileManager.currentProfileId,
                            cardWidth: calculateCardWidth(for: geometry.size.width)
                        )
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
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("ProfileSectionBackground").opacity(0.95),
                    Color("ProfileSectionBackground")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .sheet(item: $editingProfile) { profile in
            ProfileFormView(profile: profile, profileManager: profileManager) {
                editingProfile = nil
            }
        }
    }
    
    private func calculateCardWidth(for width: CGFloat) -> CGFloat {
        let totalPadding: CGFloat = 40 // Left and right padding
        let numberOfProfiles = CGFloat(profileManager.profiles.count)
        let totalSpacing = (numberOfProfiles - 1) * calculateSpacing(for: width)
        let availableWidth = width - totalPadding - totalSpacing
        return availableWidth / numberOfProfiles
    }
    
    private func calculateSpacing(for width: CGFloat) -> CGFloat {
        // Adjust spacing based on screen width
        if width < 375 {
            return 8 // Smaller phones
        } else if width < 430 {
            return 12 // Regular phones
        } else {
            return 16 // Plus/Max phones
        }
    }
}

struct ProfileCard: View {
    let profile: Profile
    let isSelected: Bool
    let cardWidth: CGFloat
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue.opacity(0.3) : Color.secondary.opacity(0.2))
                    .frame(width: min(44, cardWidth * 0.4), height: min(44, cardWidth * 0.4))
                
                Image(systemName: profile.icon)
                    .font(.system(size: min(22, cardWidth * 0.2)))
                    .foregroundColor(isSelected ? .blue : .primary)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            }
            
            // Profile name
            Text(profile.name)
                .font(.system(size: min(14, cardWidth * 0.14)))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            // Stats section
            VStack(spacing: 2) {
                if profile.isAllowListMode {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: min(9, cardWidth * 0.09)))
                        Text("Allow: \(profile.appTokens.count)")
                            .font(.system(size: min(10, cardWidth * 0.1)))
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.green)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                } else {
                    VStack(spacing: 2) {
                        if profile.appTokens.count > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "app.badge.fill")
                                    .font(.system(size: min(9, cardWidth * 0.09)))
                                Text("\(profile.appTokens.count) apps")
                                    .font(.system(size: min(10, cardWidth * 0.1)))
                                    .fontWeight(.medium)
                            }
                        }
                        
                        if profile.categoryTokens.count > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: min(9, cardWidth * 0.09)))
                                Text("\(profile.categoryTokens.count) cats")
                                    .font(.system(size: min(10, cardWidth * 0.1)))
                                    .fontWeight(.medium)
                            }
                        }
                        
                        if profile.appTokens.count == 0 && profile.categoryTokens.count == 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "minus.circle")
                                    .font(.system(size: min(9, cardWidth * 0.09)))
                                Text("None")
                                    .font(.system(size: min(10, cardWidth * 0.1)))
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.orange)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                }
            }
            .frame(minHeight: 24)
        }
        .padding(.horizontal, max(8, cardWidth * 0.08))
        .padding(.vertical, 10)
        .frame(width: cardWidth)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(isSelected ? 0.08 : 0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue.opacity(0.8) : Color.primary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                )
        )
        .shadow(color: isSelected ? Color.blue.opacity(0.4) : Color.primary.opacity(0.1), radius: isSelected ? 6 : 3, x: 0, y: 2)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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
            
            if let apps = appsBlocked, let isAllowMode = isAllowListMode {
                if isAllowMode {
                    Text("Allow: \(apps)")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                } else if let categories = categoriesBlocked {
                    Text("Block: \(apps) | C: \(categories)")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                }
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
            isSelected: isSelected,
            isAllowListMode: profile.isAllowListMode
        )
    }
}
