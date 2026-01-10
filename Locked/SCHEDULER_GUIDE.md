# Scheduler Feature Implementation Guide

## Overview
I've added a comprehensive scheduler feature to your Locked app that allows users to automatically lock apps based on time schedules. For example, users can set up a schedule to lock apps from 8am to 8pm on weekdays.

## New Files Created

### 1. **Schedule.swift**
Contains the core data models:
- `Schedule`: Main model storing schedule information (times, days, profile)
- `TimeComponents`: Represents hours and minutes
- `Weekday`: Enum for days of the week

Key features:
- `isActive(at:)` - Checks if a schedule should be active at a given time
- `nextStartDate()` - Calculates when the schedule will next activate
- Handles schedules that span midnight (e.g., 10pm to 2am)

### 2. **ScheduleManager.swift**
Observable object that manages all schedules and triggers locks/unlocks:
- Monitors time every minute
- Automatically locks apps when schedules become active
- Unlocks apps when schedules end
- Sends notifications when locking/unlocking
- Persists schedules to UserDefaults

### 3. **ScheduleListView.swift**
Main view for displaying all schedules:
- Shows all created schedules
- Indicates which schedules are currently active
- Allows toggling schedules on/off
- Swipe to delete schedules
- Empty state with helpful message

### 4. **ScheduleFormView.swift**
Form for creating and editing schedules:
- Set schedule name
- Choose which profile to lock
- Set start and end times
- Select which days to repeat (with quick buttons for weekdays/weekends)
- Toggle enabled/disabled

### 5. **ScheduleDetailView.swift**
Detailed view for a single schedule:
- Shows all schedule information
- Displays current status (Active/Inactive)
- Shows next activation time
- Quick toggle for enable/disable
- Edit and delete options

## Files Modified

### **LockedApp.swift**
- Added `@StateObject private var scheduleManager = ScheduleManager()`
- Added `.environmentObject(scheduleManager)` to LockedView
- Configured ScheduleManager with dependencies on appear
- Requests notification permissions on launch

### **LockedView.swift**
- Added `@EnvironmentObject private var scheduleManager: ScheduleManager`
- Added navigation link to ScheduleListView in toolbar (clock icon)

## How It Works

1. **Schedule Creation**: Users create schedules specifying:
   - Start and end times
   - Which days to repeat
   - Which profile to use (with its locked apps)
   - Schedule name

2. **Time Monitoring**: 
   - ScheduleManager checks every minute if any schedule should be active
   - When a schedule becomes active, it automatically locks apps
   - When no schedules are active, it unlocks apps

3. **Smart Detection**:
   - Handles schedules that span midnight
   - Supports multiple schedules (uses first active one)
   - Tracks whether current lock was triggered by schedule vs manual/NFC

4. **Notifications**:
   - Sends notification when schedule activates
   - Sends notification when schedule ends
   - User can see these even when app is in background

## Usage Example

To create a work schedule that locks social media apps from 8am to 8pm on weekdays:

1. Create a "Work" profile with social media apps selected
2. Tap the clock icon in LockedView
3. Tap "+" to create a new schedule
4. Configure:
   - Name: "Work Hours"
   - Profile: Work
   - Start: 8:00 AM
   - End: 8:00 PM
   - Days: Tap "Weekdays" button
5. Tap "Save"

The schedule will now automatically lock those apps every weekday from 8am to 8pm!

## Key Features

- ✅ Time-based automatic locking
- ✅ Flexible repeat schedules (any combination of days)
- ✅ Multiple schedules support
- ✅ Notifications when schedules activate/deactivate
- ✅ Easy enable/disable toggle without deleting
- ✅ Works with existing profiles
- ✅ Handles schedules that span midnight
- ✅ Shows "Active Now" indicator
- ✅ Calculates next activation time

## Testing

To test the scheduler:

1. Create a schedule that starts in a few minutes
2. Wait for the minute to arrive
3. Apps should automatically lock and you'll see a notification
4. The lock screen will show the locked state
5. At the end time, apps unlock automatically

## Notes

- Schedules work even when the app is in the background
- The timer checks every minute, so activation might be up to 60 seconds delayed
- Only one schedule can be active at a time (if multiple overlap, first one is used)
- Schedules respect the "locked by schedule" flag to avoid interfering with manual/NFC locks
- All schedule data persists across app launches

## Future Enhancements

Potential improvements you could add:
- Background task for more reliable scheduling
- Calendar integration
- Schedule templates
- Conflict detection between overlapping schedules
- Statistics showing schedule adherence
- Temporary schedule overrides
