//
//  NotificationCenter+Extensions.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import Foundation

extension Notification.Name {
    // Notificaciones para navegación rápida
    static let openQuickLog = Notification.Name("openQuickLog")
    static let openCharts = Notification.Name("openCharts")
    static let openGoals = Notification.Name("openGoals")
    static let openSettings = Notification.Name("openSettings")
    static let openProgress = Notification.Name("openProgress")
    static let openStats = Notification.Name("openStats")
    static let openMainView = Notification.Name("openMainView")
    
    // Notificaciones para actualizaciones de datos
    static let weightDataUpdated = Notification.Name("weightDataUpdated")
    static let goalUpdated = Notification.Name("goalUpdated")
    static let goalCreationFailed = Notification.Name("goalCreationFailed")
    static let settingsUpdated = Notification.Name("settingsUpdated")
    static let languageChanged = Notification.Name("languageChanged")
    static let dataSaveError = Notification.Name("dataSaveError")
    


    
    // Notificaciones para logros y milestones
    static let goalMilestoneReached = Notification.Name("goalMilestoneReached")
    static let streakAchieved = Notification.Name("streakAchieved")
    static let weightGoalCompleted = Notification.Name("weightGoalCompleted")
}

// MARK: - Notification Helper

class NotificationHelper {
    static let shared = NotificationHelper()
    
    private init() {}
    
    // MARK: - Quick Actions
    
    func triggerQuickLog() {
        NotificationCenter.default.post(name: .openQuickLog, object: nil)
    }
    
    func triggerOpenCharts() {
        NotificationCenter.default.post(name: .openCharts, object: nil)
    }
    
    func triggerOpenGoals() {
        NotificationCenter.default.post(name: .openGoals, object: nil)
    }
    
    func triggerOpenSettings() {
        NotificationCenter.default.post(name: .openSettings, object: nil)
    }
    
    func triggerOpenMainView() {
        NotificationCenter.default.post(name: .openMainView, object: nil)
    }
    
    // MARK: - Data Updates
    
    func notifyWeightDataUpdated() {
        NotificationCenter.default.post(name: .weightDataUpdated, object: nil)
    }
    
    func notifyGoalUpdated(goal: WeightGoal?) {
        NotificationCenter.default.post(
            name: .goalUpdated,
            object: nil,
            userInfo: ["goal": goal as Any]
        )
    }
    
    func notifyGoalCreationFailed(error: Error) {
        NotificationCenter.default.post(
            name: .goalCreationFailed,
            object: nil,
            userInfo: ["error": error]
        )
    }
    
    func notifySettingsUpdated() {
        NotificationCenter.default.post(name: .settingsUpdated, object: nil)
    }
    
    func notifyDataSaveError(error: Error) {
        NotificationCenter.default.post(
            name: .dataSaveError,
            object: nil,
            userInfo: ["error": error]
        )
    }
    
    // MARK: - HealthKit (eliminado)
    // Funcionalidad de HealthKit removida
    
    // MARK: - Achievements
    
    func notifyGoalMilestoneReached(progress: Double, goal: WeightGoal) {
        NotificationCenter.default.post(
            name: .goalMilestoneReached,
            object: nil,
            userInfo: [
                "progress": progress,
                "goal": goal
            ]
        )
    }
    
    func notifyStreakAchieved(days: Int) {
        NotificationCenter.default.post(
            name: .streakAchieved,
            object: nil,
            userInfo: ["days": days]
        )
    }
    
    func notifyWeightGoalCompleted(goal: WeightGoal) {
        NotificationCenter.default.post(
            name: .weightGoalCompleted,
            object: nil,
            userInfo: ["goal": goal]
        )
    }
}

// MARK: - Notification Observer Protocol

protocol NotificationObserver {
    func setupNotificationObservers()
    func removeNotificationObservers()
}

extension NotificationObserver {
    func removeNotificationObservers() {
        // Para structs, necesitamos remover observadores específicos
        // Esta implementación por defecto está vacía y debe ser sobrescrita
    }
}