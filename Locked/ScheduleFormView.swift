//
//  ScheduleFormView.swift
//  Locked
//
//  Created by Brandon Scott on 2025-01-09.
//

import SwiftUI

struct ScheduleFormView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @EnvironmentObject private var profileManager: ProfileManager
    @Environment(\.dismiss) private var dismiss
    
    let schedule: Schedule?
    
    @State private var name: String
    @State private var selectedProfileId: UUID
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var repeatDays: Set<Weekday>
    @State private var isEnabled: Bool
    
    init(schedule: Schedule?) {
        self.schedule = schedule
        
        if let schedule = schedule {
            _name = State(initialValue: schedule.name)
            _selectedProfileId = State(initialValue: schedule.profileId)
            _isEnabled = State(initialValue: schedule.isEnabled)
            
            var startComponents = DateComponents()
            startComponents.hour = schedule.startTime.hour
            startComponents.minute = schedule.startTime.minute
            let start = Calendar.current.date(from: startComponents) ?? Date()
            _startTime = State(initialValue: start)
            
            var endComponents = DateComponents()
            endComponents.hour = schedule.endTime.hour
            endComponents.minute = schedule.endTime.minute
            let end = Calendar.current.date(from: endComponents) ?? Date()
            _endTime = State(initialValue: end)
            
            _repeatDays = State(initialValue: schedule.repeatDays)
        } else {
            _name = State(initialValue: "Lock Schedule")
            _selectedProfileId = State(initialValue: UUID())
            _isEnabled = State(initialValue: true)
            _startTime = State(initialValue: Date())
            _endTime = State(initialValue: Date().addingTimeInterval(3600))
            _repeatDays = State(initialValue: Set(Weekday.allCases))
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Schedule Details")) {
                TextField("Name", text: $name)
                
                Picker("Profile", selection: $selectedProfileId) {
                    ForEach(profileManager.profiles) { profile in
                        HStack {
                            Image(systemName: profile.icon)
                            Text(profile.name)
                        }
                        .tag(profile.id)
                    }
                }
                
                Toggle("Enabled", isOn: $isEnabled)
            }
            
            Section(header: Text("Time")) {
                DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                
                DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
            }
            
            Section(header: Text("Repeat")) {
                ForEach(Weekday.allCases) { day in
                    Toggle(day.fullName, isOn: Binding(
                        get: { repeatDays.contains(day) },
                        set: { isSelected in
                            if isSelected {
                                repeatDays.insert(day)
                            } else {
                                repeatDays.remove(day)
                            }
                        }
                    ))
                }
                
                HStack {
                    Button("Select All") {
                        repeatDays = Set(Weekday.allCases)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Weekdays") {
                        repeatDays = [.monday, .tuesday, .wednesday, .thursday, .friday]
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Weekend") {
                        repeatDays = [.saturday, .sunday]
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle(schedule == nil ? "New Schedule" : "Edit Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveSchedule()
                }
                .disabled(name.isEmpty || repeatDays.isEmpty)
            }
        }
        .onAppear {
            // Set default profile if needed
            if selectedProfileId == UUID() {
                selectedProfileId = profileManager.currentProfile.id
            }
        }
    }
    
    private func saveSchedule() {
        let startTimeComponents = TimeComponents(from: startTime)
        let endTimeComponents = TimeComponents(from: endTime)
        
        let newSchedule = Schedule(
            id: schedule?.id ?? UUID(),
            isEnabled: isEnabled,
            profileId: selectedProfileId,
            startTime: startTimeComponents,
            endTime: endTimeComponents,
            repeatDays: repeatDays,
            name: name
        )
        
        if schedule == nil {
            scheduleManager.addSchedule(newSchedule)
        } else {
            scheduleManager.updateSchedule(newSchedule)
        }
        
        dismiss()
    }
}

#Preview {
    NavigationView {
        ScheduleFormView(schedule: nil)
            .environmentObject(ScheduleManager())
            .environmentObject(ProfileManager())
    }
}
