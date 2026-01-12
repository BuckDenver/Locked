//
//  TimerManager.swift
//  Locked
//
//  Created by Brandon Scott on 2025-01-12.
//

import SwiftUI
import Combine

@MainActor
class TimerManager: ObservableObject {
    @Published var isTimerActive: Bool = false
    @Published var remainingTimeString: String = "00:00:00"
    
    private var timer: Timer?
    private var endTime: Date?
    var onTimerExpired: (() -> Void)?
    
    init() {
        checkForActiveTimer()
        startTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func checkForActiveTimer() {
        if let savedEndTime = UserDefaults.standard.object(forKey: "timerLockEndTime") as? Date {
            if savedEndTime > Date() {
                endTime = savedEndTime
                isTimerActive = true
            } else {
                // Timer expired - don't clear it yet, let the view handle it
                // Just set it as inactive
                isTimerActive = false
                onTimerExpired?()
            }
        }
    }
    
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateRemainingTime()
            }
        }
    }
    
    private func updateRemainingTime() {
        guard let endTime = endTime else {
            isTimerActive = false
            remainingTimeString = "00:00:00"
            return
        }
        
        let now = Date()
        if now >= endTime {
            // Timer expired - trigger unlock callback
            clearTimer()
            onTimerExpired?()
            return
        }
        
        let timeInterval = endTime.timeIntervalSince(now)
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        
        remainingTimeString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        isTimerActive = true
    }
    
    func setTimer(endTime: Date) {
        self.endTime = endTime
        UserDefaults.standard.set(endTime, forKey: "timerLockEndTime")
        isTimerActive = true
        updateRemainingTime()
    }
    
    func clearTimer() {
        endTime = nil
        isTimerActive = false
        remainingTimeString = "00:00:00"
        UserDefaults.standard.removeObject(forKey: "timerLockEndTime")
    }
}
