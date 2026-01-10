//
//  SettingsView.swift
//  Locked
//
//  Created by Assistant on 2026-01-10.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var snoozeManager: SnoozeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Snooze Duration", selection: $snoozeManager.snoozeDuration) {
                        Text("5 minutes").tag(300.0)
                        Text("10 minutes").tag(600.0)
                        Text("15 minutes").tag(900.0)
                    }
                    
                    Stepper("Max Snoozes Per Day: \(snoozeManager.maxSnoozesPerDay)", 
                            value: $snoozeManager.maxSnoozesPerDay, 
                            in: 1...5)
                    
                    HStack {
                        Text("Snoozes Used Today")
                        Spacer()
                        Text("\(snoozeManager.snoozesUsedToday) / \(snoozeManager.maxSnoozesPerDay)")
                            .foregroundColor(.secondary)
                    }
                    
                    #if DEBUG
                    Button("Reset Count (Debug Only)") {
                        snoozeManager.resetSnoozesUsed()
                    }
                    .foregroundColor(.orange)
                    #endif
                } header: {
                    Text("Snooze Settings")
                } footer: {
                    Text("Customize how snooze works when apps are locked. The counter resets automatically at midnight each day.")
                }
                
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Snooze temporarily unlocks your apps for quick access. Use it wisely!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "app.badge.checkmark")
                                .foregroundColor(.green)
                            Text("Keep Running in Background")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("This app works best when kept in the background. Please don't force-quit the app, as this may prevent app locking from working properly.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Important")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SnoozeManager())
}
