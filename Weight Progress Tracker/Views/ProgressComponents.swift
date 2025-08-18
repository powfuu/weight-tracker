//
//  ProgressComponents.swift
//  Weight Progress Tracker
//
//  Created by Weight Progress Tracker on 2024.
//

import SwiftUI

// MARK: - StatsRow Component
struct StatsRow: View {
    let avg: Double
    let min: Double
    let max: Double
    let unit: String
    
    var body: some View {
        HStack(spacing: 10) {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(stat("Prom", avg, unit))
            
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(stat("Mín", min, unit))
            
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(stat("Máx", max, unit))
        }
        .frame(height: 34)
    }
    
    private func stat(_ title: String, _ value: Double, _ unit: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text(String(format: "%.1f %@", value, unit))
                .font(.caption)
                .bold()
        }
        .padding(.horizontal, 10)
    }
}

// MARK: - ProgressRingAction Component
struct ProgressRingAction: View {
    let progress: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(style: .init(lineWidth: 10, lineCap: .round))
                    .fill(
                        AngularGradient(
                            colors: [.teal, .cyan, .teal],
                            center: .center
                        )
                    )
                    .opacity(0.25)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(style: .init(lineWidth: 10, lineCap: .round))
                    .fill(
                        AngularGradient(
                            colors: [.teal, .mint],
                            center: .center
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: progress)
                
                // Plus icon
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            .frame(width: 56, height: 56)
        }
        .pressableScale()
    }
}

// MARK: - Weight Change Indicator
struct WeightChangeIndicator: View {
    let change: Double
    let isGoalToLose: Bool
    
    private var changeColor: Color {
        if change == 0 { return .secondary }
        
        if isGoalToLose {
            return change < 0 ? .green : .red
        } else {
            return change > 0 ? .green : .red
        }
    }
    
    private var changeIcon: String {
        if change == 0 { return "minus" }
        return change > 0 ? "arrow.up" : "arrow.down"
    }
    
    private var displayChange: String {
        let weightManager = WeightDataManager.shared
        let unit = weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
        let displayWeight = weightManager.getDisplayWeight(abs(change), in: unit)
        return String(format: "%.1f %@", displayWeight, unit)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: changeIcon)
                .font(.caption)
                .foregroundColor(changeColor)
            
            Text(displayChange)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(changeColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(changeColor.opacity(0.1))
        )
    }
}

// MARK: - Progress Ring View
struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    
    init(progress: Double, lineWidth: CGFloat = 8, size: CGFloat = 60) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.teal.opacity(0.2), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    AngularGradient(
                        colors: [.teal, .mint],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: progress)
            
            // Progress percentage
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.teal)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Enhanced Period Selector
struct PeriodSelector: View {
    @Binding var selectedPeriod: TimePeriod
    let onPeriodChange: (TimePeriod) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button(action: {
                    HapticFeedback.light()
                    selectedPeriod = period
                    onPeriodChange(period)
                }) {
                    Text(period.shortDisplayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(selectedPeriod == period ? .white : .teal)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedPeriod == period ? Color.teal : Color.teal.opacity(0.1))
                        )
                }
                .animation(.easeInOut(duration: 0.2), value: selectedPeriod)
            }
        }
        .frame(height: 36)
    }
}

// MARK: - TimePeriod Extension
extension TimePeriod {
    var shortDisplayName: String {
        switch self {
        case .week:
            return "7D"
        case .month:
            return "1M"
        case .quarter:
            return "3M"
        case .year:
            return "1A"
        }
    }
}