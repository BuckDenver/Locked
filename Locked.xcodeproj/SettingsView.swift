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
                        Text("1 minute").tag(60.0)
                        Text("2 minutes").tag(120.0)
                        Text("5 minutes").tag(300.0)
                        Text("10 minutes").tag(600.0)
                        Text("15 minutes").tag(900.0)
                        Text("30 minutes").tag(1800.0)
                    }
                    
                    Stepper("Max Snoozes Per Day: \(snoozeManager.maxSnoozesPerDay)", 
                            value: $snoozeManager.maxSnoozesPerDay, 
                            in: 1...20)
                    
                    HStack {
                        Text("Snoozes Used Today")
                        Spacer()
                        Text("\(snoozeManager.snoozesUsedToday) / \(snoozeManager.maxSnoozesPerDay)")
                            .foregroundColor(.secondary)
                    }
                    
                    if snoozeManager.snoozesUsedToday > 0 {
                        Button("Reset Today's Count") {
                            snoozeManager.resetSnoozesUsed()
                        }
                        .foregroundColor(.orange)
                    }
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
