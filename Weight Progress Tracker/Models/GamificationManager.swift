//
//  GamificationManager.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import Foundation
import SwiftUI
import CoreData
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Achievement Types
enum AchievementType: String, CaseIterable, Codable {
    case firstEntry = "first_entry"
    case weekStreak = "week_streak"
    case monthStreak = "month_streak"
    case weightLoss5kg = "weight_loss_5kg"
    case weightLoss10kg = "weight_loss_10kg"
    case consistentLogger = "consistent_logger"
    case goalAchiever = "goal_achiever"
    case dataExplorer = "data_explorer"
    
    var title: String {
        switch self {
        case .firstEntry: return "Primer Paso"
        case .weekStreak: return "Semana Completa"
        case .monthStreak: return "Mes Consistente"
        case .weightLoss5kg: return "5\(WeightUnit.kilograms.rawValue) Menos"
        case .weightLoss10kg: return "10\(WeightUnit.kilograms.rawValue) Menos"
        case .consistentLogger: return "Registrador Constante"
        case .goalAchiever: return "Alcanzador de Metas"
        case .dataExplorer: return "Explorador de Datos"
        }
    }
    
    var description: String {
        switch self {
        case .firstEntry: return "Registraste tu primer peso"
        case .weekStreak: return "7 días consecutivos registrando peso"
        case .monthStreak: return "30 días consecutivos registrando peso"
        case .weightLoss5kg: return "Perdiste 5\(WeightUnit.kilograms.rawValue) desde tu primer registro"
        case .weightLoss10kg: return "Perdiste 10\(WeightUnit.kilograms.rawValue) desde tu primer registro"
        case .consistentLogger: return "50 registros de peso completados"
        case .goalAchiever: return "Alcanzaste tu meta de peso"
        case .dataExplorer: return "Exploraste todas las vistas de gráficos"
        }
    }
    
    var icon: String {
        switch self {
        case .firstEntry: return "star.fill"
        case .weekStreak: return "calendar.badge.checkmark"
        case .monthStreak: return "calendar.badge.plus"
        case .weightLoss5kg: return "arrow.down.circle.fill"
        case .weightLoss10kg: return "arrow.down.square.fill"
        case .consistentLogger: return "chart.line.uptrend.xyaxis"
        case .goalAchiever: return "target"
        case .dataExplorer: return "chart.bar.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .firstEntry: return .yellow
        case .weekStreak: return .cyan
        case .monthStreak: return .purple
        case .weightLoss5kg: return .green
        case .weightLoss10kg: return .blue
        case .consistentLogger: return .orange
        case .goalAchiever: return .red
        case .dataExplorer: return .mint
        }
    }
}

// MARK: - Achievement Model
struct Achievement: Identifiable, Codable {
    var id = UUID()
    let type: AchievementType
    let unlockedDate: Date
    let isNew: Bool
    
    init(type: AchievementType, unlockedDate: Date = Date(), isNew: Bool = true) {
        self.type = type
        self.unlockedDate = unlockedDate
        self.isNew = isNew
    }
}

// MARK: - Streak Model
struct StreakData {
    let currentStreak: Int
    let longestStreak: Int
    let lastEntryDate: Date?
    
    var isActiveToday: Bool {
        guard let lastEntry = lastEntryDate else { return false }
        return Calendar.current.isDateInToday(lastEntry)
    }
    
    var motivationalMessage: String {
        if currentStreak == 0 {
            return "¡Comienza tu racha hoy!"
        } else if currentStreak < 7 {
            return "¡Vas por buen camino! Día \(currentStreak)"
        } else if currentStreak < 30 {
            return "¡Increíble! \(currentStreak) días consecutivos"
        } else {
            return "¡Eres imparable! \(currentStreak) días"
        }
    }
}

// MARK: - Gamification Manager
class GamificationManager: ObservableObject {
    static let shared = GamificationManager()
    
    @Published var achievements: [Achievement] = []
    @Published var currentStreak: StreakData = StreakData(currentStreak: 0, longestStreak: 0, lastEntryDate: nil)
    @Published var newAchievements: [Achievement] = []
    @Published var showingAchievementAlert = false
    
    private let userDefaults = UserDefaults.standard
    private let achievementsKey = "user_achievements"
    private let streakKey = "user_streak_data"
    private let viewsExploredKey = "views_explored"
    
    init() {
        loadAchievements()
    }
    
    // MARK: - Achievement Management
    func checkForNewAchievements(weightManager: WeightDataManager) async {
        let entries = weightManager.weightEntries
        
        // First entry achievement
        if !hasAchievement(.firstEntry) && !entries.isEmpty {
            unlockAchievement(.firstEntry)
        }
        
        // Consistent logger achievement
        if !hasAchievement(.consistentLogger) && entries.count >= 50 {
            unlockAchievement(.consistentLogger)
        }
        
        // Weight loss achievements
        if entries.count >= 2 {
            let firstWeight = entries.last?.weight ?? 0
            let currentWeight = entries.first?.weight ?? 0
            let weightLoss = firstWeight - currentWeight
            
            if !hasAchievement(.weightLoss5kg) && weightLoss >= 5.0 {
                unlockAchievement(.weightLoss5kg)
            }
            
            if !hasAchievement(.weightLoss10kg) && weightLoss >= 10.0 {
                unlockAchievement(.weightLoss10kg)
            }
        }
        
        // Goal achievement
        if !hasAchievement(.goalAchiever) {
            if let goal = await weightManager.getActiveGoal(),
               let latestEntry = entries.first,
               abs(latestEntry.weight - goal.targetWeight) <= 0.5 {
                unlockAchievement(.goalAchiever)
            }
        }
        
        // Streak achievements
        updateStreak(entries: entries)
        if !hasAchievement(.weekStreak) && currentStreak.currentStreak >= 7 {
            unlockAchievement(.weekStreak)
        }
        
        if !hasAchievement(.monthStreak) && currentStreak.currentStreak >= 30 {
            unlockAchievement(.monthStreak)
        }
    }
    
    func markViewAsExplored(_ viewName: String) {
        var exploredViews = userDefaults.stringArray(forKey: viewsExploredKey) ?? []
        if !exploredViews.contains(viewName) {
            exploredViews.append(viewName)
            userDefaults.set(exploredViews, forKey: viewsExploredKey)
            
            // Check if all main views have been explored
            let requiredViews = ["MainView", "ChartsView", "GoalsView", "SettingsView"]
            if !hasAchievement(.dataExplorer) && requiredViews.allSatisfy({ exploredViews.contains($0) }) {
                unlockAchievement(.dataExplorer)
            }
        }
    }
    
    private func unlockAchievement(_ type: AchievementType) {
        let achievement = Achievement(type: type)
        achievements.append(achievement)
        newAchievements.append(achievement)
        saveAchievements()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            #if canImport(UIKit)
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            #endif
            self.showingAchievementAlert = true
        }
    }
    
    private func hasAchievement(_ type: AchievementType) -> Bool {
        return achievements.contains { $0.type == type }
    }
    
    func markAchievementsAsViewed() {
        newAchievements.removeAll()
        showingAchievementAlert = false
    }
    
    // MARK: - Streak Management
    private func updateStreak(entries: [WeightEntry]) {
        guard !entries.isEmpty else {
            currentStreak = StreakData(currentStreak: 0, longestStreak: currentStreak.longestStreak, lastEntryDate: nil)
            return
        }
        
        let sortedEntries = entries.sorted { ($0.timestamp ?? Date.distantPast) > ($1.timestamp ?? Date.distantPast) }
        let calendar = Calendar.current
        var streak = 0
        var longestStreak = 0
        var currentStreakCount = 0
        
        // Calculate current streak
        var checkDate = Date()
        for entry in sortedEntries {
            if calendar.isDate(entry.timestamp ?? Date(), inSameDayAs: checkDate) {
                currentStreakCount += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else if calendar.isDate(entry.timestamp ?? Date(), inSameDayAs: calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate) {
                currentStreakCount += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: entry.timestamp ?? Date()) ?? entry.timestamp ?? Date()
            } else {
                break
            }
        }
        
        // Calculate longest streak
        var tempStreak = 0
        var previousDate: Date?
        
        for entry in sortedEntries.reversed() {
            if let prevDate = previousDate {
                let daysDifference = calendar.dateComponents([.day], from: prevDate, to: entry.timestamp ?? Date()).day ?? 0
                if daysDifference == 1 {
                    tempStreak += 1
                } else {
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            } else {
                tempStreak = 1
            }
            previousDate = entry.timestamp ?? Date()
        }
        longestStreak = max(longestStreak, tempStreak)
        
        currentStreak = StreakData(
            currentStreak: currentStreakCount,
            longestStreak: max(longestStreak, currentStreak.longestStreak),
            lastEntryDate: sortedEntries.first?.timestamp
        )
        
        saveStreakData()
    }
    
    // MARK: - Persistence
    private func loadAchievements() {
        if let data = userDefaults.data(forKey: achievementsKey),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = decoded
        }
        
        if let data = userDefaults.data(forKey: streakKey),
           let decoded = try? JSONDecoder().decode(StreakData.self, from: data) {
            currentStreak = decoded
        }
    }
    
    private func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            userDefaults.set(encoded, forKey: achievementsKey)
        }
    }
    
    private func saveStreakData() {
        if let encoded = try? JSONEncoder().encode(currentStreak) {
            userDefaults.set(encoded, forKey: streakKey)
        }
    }
    
    // MARK: - Statistics
    func getMotivationalStats() -> [MotivationalStat] {
        return [
            MotivationalStat(
                title: "Racha Actual",
                value: "\(currentStreak.currentStreak)",
                subtitle: "días consecutivos",
                icon: "flame.fill",
                color: currentStreak.currentStreak > 0 ? .orange : .gray
            ),
            MotivationalStat(
                title: "Mejor Racha",
                value: "\(currentStreak.longestStreak)",
                subtitle: "días máximos",
                icon: "trophy.fill",
                color: .yellow
            ),
            MotivationalStat(
                title: "Logros",
                value: "\(achievements.count)",
                subtitle: "de \(AchievementType.allCases.count)",
                icon: "star.fill",
                color: .teal
            )
        ]
    }
}

// MARK: - Motivational Stat Model
struct MotivationalStat {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
}

// MARK: - StreakData Codable Extension
extension StreakData: Codable {
    enum CodingKeys: String, CodingKey {
        case currentStreak, longestStreak, lastEntryDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentStreak = try container.decode(Int.self, forKey: .currentStreak)
        longestStreak = try container.decode(Int.self, forKey: .longestStreak)
        lastEntryDate = try container.decodeIfPresent(Date.self, forKey: .lastEntryDate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(currentStreak, forKey: .currentStreak)
        try container.encode(longestStreak, forKey: .longestStreak)
        try container.encodeIfPresent(lastEntryDate, forKey: .lastEntryDate)
    }
}