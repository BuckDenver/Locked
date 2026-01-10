//
//  ScheduleDetailView.swift
//  Locked
//
//  Created by Brandon Scott on 2025-01-09.
//

import SwiftUI

struct ScheduleDetailView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var profileManager: ProfileManager
    @Environment(\.dismiss) private var dismiss
    
    let schedule: Schedule
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    private var profile: Profile? {
        profileManager.profiles.first(where: { $0.id == schedule.profileId })
    }
    
    private var daysText: String {
        if schedule.repeatDays.count == 7 {
            return "Every day"
        } else if schedule.repeatDays.count == 5 && !schedule.repeatDays.contains(.saturday) && !schedule.repeatDays.contains(.sunday) {
            return "Weekdays"
        } else if schedule.repeatDays.count == 2 && schedule.repeatDays.contains(.saturday) && schedule.repeatDays.contains(.sunday) {
            return "Weekends"
        } else {
            return schedule.repeatDays.sorted(by: { $0.rawValue < $1.rawValue })
                .map { $0.fullName }
                .joined(separator: ", ")
        }
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Status")
                        .foregroundColor(.secondary)
                    Spacer()
                    if schedule.isActive() {
                        Label("Active Now", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Label("Inactive", systemImage: "moon.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                Toggle("Enabled", isOn: Binding(
                    get: { schedule.isEnabled },
                    set: { _ in
                        scheduleManager.toggleSchedule(withId: schedule.id)
                    }
                ))
            }
            
            Section(header: Text("Details")) {
                HStack {
                    Text("Name")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(schedule.name)
                }
                
                if let profile = profile {
                    HStack {
                        Text("Profile")
                            .foregroundColor(.secondary)
                        Spacer()
                        Label(profile.name, systemImage: profile.icon)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Section(header: Text("Time")) {
                HStack {
                    Text("Start")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(schedule.startTime.displayString)
                }
                
                HStack {
                    Text("End")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(schedule.endTime.displayString)
                }
                
                HStack {
                    Text("Duration")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(durationText)
                }
            }
            
            Section(header: Text("Repeat")) {
                HStack {
                    Text("Days")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(daysText)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            if let nextStart = schedule.nextStartDate() {
                Section(header: Text("Next Activation")) {
                    HStack {
                        Text("Starts")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(nextStart, style: .relative)
                    }
                    
                    HStack {
                        Text("At")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(nextStart, style: .date)
                        Text(nextStart, style: .time)
                    }
                }
            }
            
            Section {
                Button(role: .destructive, action: {
                    showingDeleteAlert = true
                }) {
                    HStack {
                        Spacer()
                        Text("Delete Schedule")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(schedule.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                ScheduleFormView(schedule: schedule)
            }
        }
        .alert("Delete Schedule", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                scheduleManager.deleteSchedule(withId: schedule.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this schedule?")
        }
    }
    
    private var durationText: String {
        let startMinutes = schedule.startTime.hour * 60 + schedule.startTime.minute
        let endMinutes = schedule.endTime.hour * 60 + schedule.endTime.minute
        
        var duration = endMinutes - startMinutes
        if duration < 0 {
            duration += 24 * 60 // Add a day if it spans midnight
        }
        
        let hours = duration / 60
        let minutes = duration % 60
        
        if hours == 0 {
            return "\(minutes) min"
        } else if minutes == 0 {
            return "\(hours) hr"
        } else {
            return "\(hours) hr \(minutes) min"
        }
    }
}

#Preview {
    let manager = ProfileManager()
    let schedule = Schedule(
        isEnabled: true,
        profileId: manager.currentProfile.id,
        startTime: TimeComponents(hour: 8, minute: 0),
        endTime: TimeComponents(hour: 20, minute: 0),
        repeatDays: Set(Weekday.allCases),
        name: "Work Hours"
    )
    
    return NavigationView {
        ScheduleDetailView(schedule: schedule)
            .environmentObject(ScheduleManager())
            .environmentObject(manager)
    }
}
