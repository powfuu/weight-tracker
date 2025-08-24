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
        // Usar títulos por defecto para evitar crashes durante la inicialización
        switch self {
        case .firstEntry: return "First Entry"
        case .weekStreak: return "Week Streak"
        case .monthStreak: return "Month Streak"
        case .weightLoss5kg: return "5kg Weight Loss"
        case .weightLoss10kg: return "10kg Weight Loss"
        case .consistentLogger: return "Consistent Logger"
        case .goalAchiever: return "Goal Achiever"
        case .dataExplorer: return "Data Explorer"
        }
    }
    
    var localizedTitle: String {
        switch self {
        case .firstEntry: return LocalizationManager.shared.localizedString(for: LocalizationKeys.achievementFirstEntry)
        case .weekStreak: return LocalizationManager.shared.localizedString(for: LocalizationKeys.achievementWeekStreak)
        case .monthStreak: return LocalizationManager.shared.localizedString(for: LocalizationKeys.achievementMonthStreak)
        case .weightLoss5kg: return LocalizationManager.shared.localizedString(for: LocalizationKeys.achievementWeightLoss5kg)
        case .weightLoss10kg: return LocalizationManager.shared.localizedString(for: LocalizationKeys.achievementWeightLoss10kg)
        case .consistentLogger: return LocalizationManager.shared.localizedString(for: LocalizationKeys.achievementConsistentLogger)
        case .goalAchiever: return LocalizationManager.shared.localizedString(for: LocalizationKeys.achievementGoalAchiever)
        case .dataExplorer: return LocalizationManager.shared.localizedString(for: LocalizationKeys.achievementDataExplorer)
        }
    }
    
    var description: String {
        // Usar descripciones por defecto para evitar crashes durante la inicialización
        switch self {
        case .firstEntry: return "Congratulations on your first weight entry!"
        case .weekStreak: return "You've logged your weight for 7 consecutive days!"
        case .monthStreak: return "Amazing! 30 days of consistent logging!"
        case .weightLoss5kg: return "You've lost 5kg! Keep up the great work!"
        case .weightLoss10kg: return "Incredible! You've lost 10kg!"
        case .consistentLogger: return "You're a consistent logger!"
        case .goalAchiever: return "You've achieved your weight goal!"
        case .dataExplorer: return "You've explored all the app features!"
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .firstEntry: return LocalizationManager.shared.localizedString(for: LocalizationKeys.achievementFirstEntryDesc)
        case .weekStreak: return LocalizationManager.shared.localizedString(for: LocalizationKeys.achievementWeekStreakDesc)
        case .monthStreak: return LocalizationManager.shared.localizedString(for: LocalizationKeys.achievementMonthStreakDesc)
        case .weightLoss5kg: return LocalizationManager.shared.localizedString(for: LocalizationKeys.achievementWeightLoss5kgDesc)
        case .weightLoss10kg: return LocalizationManager.shared.localizedString(for: LocalizationKeys.achievementWeightLoss10kgDesc)
        case .consistentLogger: return LocalizationManager.shared.localizedString(for: LocalizationKeys.achievementConsistentLoggerDesc)
        case .goalAchiever: return LocalizationManager.shared.localizedString(for: LocalizationKeys.achievementGoalAchieverDesc)
        case .dataExplorer: return LocalizationManager.shared.localizedString(for: LocalizationKeys.achievementDataExplorerDesc)
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
        // Usar mensajes por defecto para evitar crashes durante la inicialización
        if currentStreak == 0 {
            return "Start your streak today!"
        } else if currentStreak < 7 {
            return "You're on a \(currentStreak) day streak! Keep going!"
        } else if currentStreak < 30 {
            return "Incredible! \(currentStreak) days in a row!"
        } else {
            return "Unstoppable! \(currentStreak) days streak!"
        }
    }
    
    var localizedMotivationalMessage: String {
        if currentStreak == 0 {
            return LocalizationManager.shared.localizedString(for: LocalizationKeys.streakStartToday)
        } else if currentStreak < 7 {
            let template = LocalizationManager.shared.localizedString(for: LocalizationKeys.streakGoodWay)
            return String(format: template, currentStreak)
        } else if currentStreak < 30 {
            let template = LocalizationManager.shared.localizedString(for: LocalizationKeys.streakIncredible)
            return String(format: template, currentStreak)
        } else {
            let template = LocalizationManager.shared.localizedString(for: LocalizationKeys.streakUnstoppable)
            return String(format: template, currentStreak)
        }
    }
}

// MARK: - Gamification Manager
class GamificationManager: ObservableObject {
    static let shared = GamificationManager()
    
    @Published var achievements: [Achievement] = []
    @Published var currentStreak: StreakData = StreakData(currentStreak: 1, longestStreak: 1, lastEntryDate: nil)
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
        // checkForNewAchievements iniciado
        let entries = weightManager.weightEntries
        
        // First entry achievement
        if !hasAchievement(.firstEntry) && !entries.isEmpty {
            // Desbloqueando firstEntry
            unlockAchievement(.firstEntry)
        }
        
        // Consistent logger achievement
        if !hasAchievement(.consistentLogger) && entries.count >= 50 {
            // Desbloqueando consistentLogger
            unlockAchievement(.consistentLogger)
        }
        
        // Weight loss achievements
        if entries.count >= 2 {
            let firstWeight = entries.last?.weight ?? 0
            let currentWeight = entries.first?.weight ?? 0
            let weightLoss = firstWeight - currentWeight
            
            if !hasAchievement(.weightLoss5kg) && weightLoss >= 5.0 {
                // Desbloqueando weightLoss5kg
                unlockAchievement(.weightLoss5kg)
            }
            
            if !hasAchievement(.weightLoss10kg) && weightLoss >= 10.0 {
                // Desbloqueando weightLoss10kg
                unlockAchievement(.weightLoss10kg)
            }
        }
        
        // Goal achievement - usar activeGoal en cache en lugar de await para evitar deadlock
        if !hasAchievement(.goalAchiever) {
            if let goal = weightManager.activeGoal,
               let latestEntry = entries.first,
               abs(latestEntry.weight - goal.targetWeight) <= 0.5 {
                // Desbloqueando goalAchiever
                unlockAchievement(.goalAchiever)
            }
        }
        
        // Streak achievements
        // Actualizando streak
        updateStreak(entries: entries)
        if !hasAchievement(.weekStreak) && currentStreak.currentStreak >= 7 {
            // Desbloqueando weekStreak
            unlockAchievement(.weekStreak)
        }
        
        if !hasAchievement(.monthStreak) && currentStreak.currentStreak >= 30 {
            // Desbloqueando monthStreak
            unlockAchievement(.monthStreak)
        }
        
        // checkForNewAchievements completado
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
        
        // Asegurar que todas las actualizaciones de @Published se hagan en el hilo principal
        DispatchQueue.main.async {
            self.achievements.append(achievement)
            self.newAchievements.append(achievement)
            self.saveAchievements()
            
            // Registrar logros importantes para el sistema de reseñas
            switch type {
            case .firstEntry, .weekStreak, .monthStreak, .weightLoss5kg, .weightLoss10kg, .goalAchiever:
                ReviewRequestManager.trackGoalCompletion()
            default:
                break
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                #if canImport(UIKit)
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
                #endif
                self.showingAchievementAlert = true
            }
        }
    }
    
    private func hasAchievement(_ type: AchievementType) -> Bool {
        return achievements.contains { $0.type == type }
    }
    
    func markAchievementsAsViewed() {
        DispatchQueue.main.async {
            self.newAchievements.removeAll()
            self.showingAchievementAlert = false
        }
    }
    
    // MARK: - Streak Management
    private func updateStreak(entries: [WeightEntry]) {
        guard !entries.isEmpty else {
            DispatchQueue.main.async {
                self.currentStreak = StreakData(currentStreak: 0, longestStreak: self.currentStreak.longestStreak, lastEntryDate: nil)
            }
            return
        }
        
        let calendar = Calendar.current
        
        // Agrupar entradas por día (solo fechas únicas)
        let uniqueDays = Set(entries.compactMap { entry -> Date? in
            guard let timestamp = entry.timestamp else { return nil }
            return calendar.startOfDay(for: timestamp)
        }).sorted(by: >)
        
        guard !uniqueDays.isEmpty else {
            DispatchQueue.main.async {
                self.currentStreak = StreakData(currentStreak: 0, longestStreak: self.currentStreak.longestStreak, lastEntryDate: nil)
            }
            return
        }
        
        // Calcular racha actual (días consecutivos desde hoy hacia atrás)
        var currentStreakCount = 0
        let today = calendar.startOfDay(for: Date())
        var checkDate = today
        
        // Verificar si hay registro hoy o ayer para mantener la racha
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let hasRecentEntry = uniqueDays.contains(today) || uniqueDays.contains(yesterday)
        
        if hasRecentEntry {
            // Si no hay registro hoy pero sí ayer, empezar desde ayer
            if !uniqueDays.contains(today) && uniqueDays.contains(yesterday) {
                checkDate = yesterday
            }
            
            // Contar días consecutivos hacia atrás
            while uniqueDays.contains(checkDate) {
                currentStreakCount += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            }
        }
        
        // Calcular racha más larga histórica
        var longestStreak = 0
        var tempStreak = 0
        var previousDay: Date?
        
        for day in uniqueDays.reversed() {
            if let prevDay = previousDay {
                let daysDifference = calendar.dateComponents([.day], from: prevDay, to: day).day ?? 0
                if daysDifference == 1 {
                    tempStreak += 1
                } else {
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            } else {
                tempStreak = 1
            }
            previousDay = day
        }
        longestStreak = max(longestStreak, tempStreak)
        
        DispatchQueue.main.async {
            self.currentStreak = StreakData(
                currentStreak: currentStreakCount,
                longestStreak: max(longestStreak, self.currentStreak.longestStreak),
                lastEntryDate: entries.sorted { ($0.timestamp ?? Date.distantPast) > ($1.timestamp ?? Date.distantPast) }.first?.timestamp
            )
            
            self.saveStreakData()
        }
    }
    
    // MARK: - Persistence
    private func loadAchievements() {
        if let data = userDefaults.data(forKey: achievementsKey),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            DispatchQueue.main.async {
                self.achievements = decoded
            }
        }
        
        if let data = userDefaults.data(forKey: streakKey),
           let decoded = try? JSONDecoder().decode(StreakData.self, from: data) {
            DispatchQueue.main.async {
                self.currentStreak = decoded
            }
        } else {
            // First time app runs, initialize with 1 day streak
            DispatchQueue.main.async {
                self.currentStreak = StreakData(currentStreak: 1, longestStreak: 1, lastEntryDate: nil)
                self.saveStreakData()
            }
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
                title: LocalizationManager.shared.localizedString(for: LocalizationKeys.currentStreakTitle),
            value: "\(currentStreak.currentStreak)",
            subtitle: LocalizationManager.shared.localizedString(for: LocalizationKeys.consecutiveDaysSubtitle),
                icon: "flame.fill",
                color: currentStreak.currentStreak > 0 ? .orange : .gray
            ),
            MotivationalStat(
                title: LocalizationManager.shared.localizedString(for: LocalizationKeys.bestStreakTitle),
            value: "\(currentStreak.longestStreak)",
            subtitle: LocalizationManager.shared.localizedString(for: LocalizationKeys.maxDaysSubtitle),
                icon: "trophy.fill",
                color: .yellow
            ),
            MotivationalStat(
                title: LocalizationManager.shared.localizedString(for: LocalizationKeys.achievementsTitle),
            value: "\(achievements.count)",
            subtitle: String(format: LocalizationManager.shared.localizedString(for: LocalizationKeys.achievementsOfTotal), AchievementType.allCases.count),
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