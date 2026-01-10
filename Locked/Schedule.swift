//
//  Schedule.swift
//  Locked
//
//  Created by Brandon Scott on 2025-01-09.
//

import Foundation

struct Schedule: Identifiable, Codable, Equatable {
    let id: UUID
    var isEnabled: Bool
    var profileId: UUID
    var startTime: TimeComponents
    var endTime: TimeComponents
    var repeatDays: Set<Weekday>
    var name: String
    
    init(
        id: UUID = UUID(),
        isEnabled: Bool = true,
        profileId: UUID,
        startTime: TimeComponents,
        endTime: TimeComponents,
        repeatDays: Set<Weekday> = Set(Weekday.allCases),
        name: String = "Lock Schedule"
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.profileId = profileId
        self.startTime = startTime
        self.endTime = endTime
        self.repeatDays = repeatDays
        self.name = name
    }
    
    /// Check if this schedule should be active at the given date
    func isActive(at date: Date = Date()) -> Bool {
        guard isEnabled else { return false }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .weekday], from: date)
        
        guard let currentHour = components.hour,
              let currentMinute = components.minute,
              let weekdayInt = components.weekday else {
            return false
        }
        
        // Check if today is in repeatDays
        guard let currentWeekday = Weekday(rawValue: weekdayInt),
              repeatDays.contains(currentWeekday) else {
            return false
        }
        
        let currentMinutes = currentHour * 60 + currentMinute
        let startMinutes = startTime.hour * 60 + startTime.minute
        let endMinutes = endTime.hour * 60 + endTime.minute
        
        // Handle schedules that span midnight
        if endMinutes < startMinutes {
            return currentMinutes >= startMinutes || currentMinutes < endMinutes
        } else {
            return currentMinutes >= startMinutes && currentMinutes < endMinutes
        }
    }
    
    /// Get the next time this schedule will start
    func nextStartDate(from date: Date = Date()) -> Date? {
        let calendar = Calendar.current
        var searchDate = date
        
        // Search up to 7 days ahead
        for _ in 0..<7 {
            let components = calendar.dateComponents([.year, .month, .day, .weekday], from: searchDate)
            
            guard let weekdayInt = components.weekday,
                  let currentWeekday = Weekday(rawValue: weekdayInt),
                  repeatDays.contains(currentWeekday) else {
                searchDate = calendar.date(byAdding: .day, value: 1, to: searchDate) ?? searchDate
                continue
            }
            
            var dateComponents = components
            dateComponents.hour = startTime.hour
            dateComponents.minute = startTime.minute
            dateComponents.second = 0
            
            if let startDate = calendar.date(from: dateComponents), startDate > date {
                return startDate
            }
            
            searchDate = calendar.date(byAdding: .day, value: 1, to: searchDate) ?? searchDate
        }
        
        return nil
    }
    
    /// Get the next time this schedule will end
    func nextEndDate(from date: Date = Date()) -> Date? {
        let calendar = Calendar.current
        
        if isActive(at: date) {
            // If currently active, calculate when it will end
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = endTime.hour
            components.minute = endTime.minute
            components.second = 0
            
            if let endDate = calendar.date(from: components) {
                // If the end time already passed today and schedule spans midnight
                if endDate < date && endTime.hour * 60 + endTime.minute < startTime.hour * 60 + startTime.minute {
                    return endDate
                } else if endDate > date {
                    return endDate
                } else {
                    // End time is tomorrow
                    return calendar.date(byAdding: .day, value: 1, to: endDate)
                }
            }
        }
        
        return nil
    }
}

struct TimeComponents: Codable, Equatable, Hashable {
    var hour: Int
    var minute: Int
    
    init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }
    
    init(from date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        self.hour = components.hour ?? 0
        self.minute = components.minute ?? 0
    }
    
    var displayString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        
        return String(format: "%02d:%02d", hour, minute)
    }
}

enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var id: Int { rawValue }
    
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
    
    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
}
