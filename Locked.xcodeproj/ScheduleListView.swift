//
//  ScheduleListView.swift
//  Locked
//
//  Created by Brandon Scott on 2025-01-09.
//

import SwiftUI

struct ScheduleListView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var profileManager: ProfileManager
    @State private var showingAddSchedule = false
    
    var body: some View {
        List {
            if scheduleManager.schedules.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 64))
                        .foregroundColor(.gray)
                    
                    Text("No Schedules")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Create a schedule to automatically lock apps at specific times")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        showingAddSchedule = true
                    }) {
                        Label("Create Schedule", systemImage: "plus.circle.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(scheduleManager.schedules) { schedule in
                    NavigationLink(destination: ScheduleDetailView(schedule: schedule)) {
                        ScheduleRowView(schedule: schedule)
                    }
                }
                .onDelete(perform: deleteSchedules)
            }
        }
        .navigationTitle("Schedules")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddSchedule = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSchedule) {
            NavigationView {
                ScheduleFormView(schedule: nil)
            }
        }
    }
    
    private func deleteSchedules(at offsets: IndexSet) {
        for index in offsets {
            let schedule = scheduleManager.schedules[index]
            scheduleManager.deleteSchedule(withId: schedule.id)
        }
    }
}

struct ScheduleRowView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var profileManager: ProfileManager
    let schedule: Schedule
    
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
                .map { $0.shortName }
                .joined(separator: ", ")
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile icon
            if let profile = profile {
                Image(systemName: profile.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.name)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Text(schedule.startTime.displayString)
                        .font(.subheadline)
                    
                    Text("–")
                        .font(.subheadline)
                    
                    Text(schedule.endTime.displayString)
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
                
                Text(daysText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let profile = profile {
                    Text(profile.name)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            // Active indicator
            if schedule.isActive() {
                Text("Active")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(8)
            }
            
            // Toggle
            Toggle("", isOn: Binding(
                get: { schedule.isEnabled },
                set: { _ in
                    scheduleManager.toggleSchedule(withId: schedule.id)
                }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        ScheduleListView()
            .environmentObject(ScheduleManager())
            .environmentObject(ProfileManager())
    }
}
