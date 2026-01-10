//
//  UsageStatsView.swift
//  Locked
//
//  Created by Assistant on 2026-01-10.
//

import SwiftUI
import Charts

struct UsageStatsView: View {
    @StateObject private var statsManager = UsageStatsManager()
    @State private var showGoalSheet = false
    
    var totalUsageHours: Double {
        statsManager.todayUsage.reduce(0) { $0 + $1.duration } / 3600
    }
    
    var isOverGoal: Bool {
        totalUsageHours > statsManager.dailyGoalHours
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with goal
                VStack(spacing: 12) {
                    Text("Today's Screen Time")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Big number display
                    Text(String(format: "%.1fh", totalUsageHours))
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(isOverGoal ? .red : .green)
                    
                    // Goal info
                    HStack(spacing: 8) {
                        Text("Goal: \(String(format: "%.1fh", statsManager.dailyGoalHours))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showGoalSheet = true
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Status message
                    if isOverGoal {
                        let overBy = totalUsageHours - statsManager.dailyGoalHours
                        Text("Over goal by \(String(format: "%.1fh", overBy))")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        let remaining = statsManager.dailyGoalHours - totalUsageHours
                        Text("\(String(format: "%.1fh", remaining)) remaining")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 20)
                
                Divider()
                    .padding(.horizontal)
                
                // Pie chart
                if !statsManager.todayUsage.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Most Used Apps")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart(statsManager.todayUsage.prefix(5)) { item in
                            SectorMark(
                                angle: .value("Usage", item.duration),
                                innerRadius: .ratio(0.5),
                                angularInset: 2
                            )
                            .foregroundStyle(by: .value("App", item.appName))
                            .cornerRadius(4)
                        }
                        .frame(height: 300)
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // List of apps with usage time
                    VStack(alignment: .leading, spacing: 12) {
                        Text("App Usage Breakdown")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(statsManager.todayUsage.prefix(10)) { item in
                            HStack {
                                // App icon placeholder
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(String(item.appName.prefix(1)))
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.appName)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Text(formatDuration(item.duration))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // Percentage
                                if totalUsageHours > 0 {
                                    let percentage = (item.duration / (totalUsageHours * 3600)) * 100
                                    Text(String(format: "%.0f%%", percentage))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    }
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        
                        Text("No Usage Data Yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Start using your device to see statistics")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 60)
                }
                
                Spacer()
            }
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showGoalSheet) {
            GoalSettingSheet(statsManager: statsManager)
        }
        .onAppear {
            statsManager.refreshData()
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct GoalSettingSheet: View {
    @ObservedObject var statsManager: UsageStatsManager
    @Environment(\.dismiss) private var dismiss
    @State private var goalHours: Double
    
    init(statsManager: UsageStatsManager) {
        self.statsManager = statsManager
        _goalHours = State(initialValue: statsManager.dailyGoalHours)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "target")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                Text("Daily Screen Time Goal")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Set how many hours per day you'd like to use your device")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                VStack(spacing: 12) {
                    Text(String(format: "%.1f hours", goalHours))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Slider(value: $goalHours, in: 0.5...12, step: 0.5)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                Button(action: {
                    statsManager.setDailyGoal(goalHours)
                    dismiss()
                }) {
                    Text("Save Goal")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("Set Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        UsageStatsView()
    }
}
