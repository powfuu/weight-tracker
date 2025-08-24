//
//  NotificationManager.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import Foundation
import UserNotifications
import Combine

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let localizationManager = LocalizationManager.shared
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            
            await updateAuthorizationStatus()
            return granted
        } catch {
            // Error requesting notification authorization
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        Task {
            await updateAuthorizationStatus()
        }
    }
    
    private func updateAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        
        await MainActor.run {
            self.authorizationStatus = settings.authorizationStatus
            self.isAuthorized = settings.authorizationStatus == .authorized
        }
    }
    
    // MARK: - Daily Reminders
    
    func scheduleDailyReminder(at time: Date) async {
        guard isAuthorized else {
            // Notifications not authorized
            return
        }
        
        // Cancelar recordatorio anterior
        await cancelDailyReminder()
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        let content = UNMutableNotificationContent()
        content.title = localizationManager.localizedString(for: LocalizationKeys.timeToWeighIn)
        content.body = localizationManager.localizedString(for: LocalizationKeys.timeToWeighInDesc)
        content.sound = .default
        content.categoryIdentifier = "DAILY_REMINDER"
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "daily_weight_reminder",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            // Recordatorio diario programado
        } catch {
            // Error programando recordatorio diario
        }
    }
    
    func cancelDailyReminder() async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["daily_weight_reminder"])
        // Recordatorio diario cancelado
    }
    
    // MARK: - Goal Notifications
    
    func scheduleGoalMilestoneNotification(progress: Double, targetWeight: Double) async {
        guard isAuthorized else { return }
        
        let milestones = [0.25, 0.5, 0.75, 1.0]
        
        // Obtener notificaciones pendientes y entregadas para evitar duplicados
        let deliveredNotifications = await notificationCenter.deliveredNotifications()
        let pendingNotifications = await notificationCenter.pendingNotificationRequests()
        
        for milestone in milestones {
            if progress >= milestone {
                let identifier = "goal_milestone_\(Int(milestone * 100))"
                
                // Verificar si ya se envió o está programada esta notificación
                let alreadyDelivered = deliveredNotifications.contains { $0.request.identifier == identifier }
                let alreadyPending = pendingNotifications.contains { $0.identifier == identifier }
                
                if !alreadyDelivered && !alreadyPending {
                    await sendGoalMilestoneNotification(milestone: milestone, targetWeight: targetWeight, identifier: identifier)
                    
                    // Notificar al sistema sobre el hito alcanzado
                    if let activeGoal = await WeightDataManager.shared.getActiveGoal() {
                        await MainActor.run {
                            NotificationHelper.shared.notifyGoalMilestoneReached(progress: milestone, goal: activeGoal)
                        }
                    }
                }
            }
        }
    }
    
    private func sendGoalMilestoneNotification(milestone: Double, targetWeight: Double, identifier: String) async {
        let content = UNMutableNotificationContent()
        
        let preferredUnit = WeightDataManager.shared.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
        let milestonePercentage = Int(milestone * 100)
        
        switch milestone {
        case 0.25:
            content.title = localizationManager.localizedString(for: LocalizationKeys.goal25Completed)
            content.body = String(format: localizationManager.localizedString(for: LocalizationKeys.goal25CompletedDesc), String(format: "%.1f", WeightDataManager.shared.getDisplayWeight(targetWeight, in: preferredUnit)), preferredUnit)
        case 0.5:
            content.title = localizationManager.localizedString(for: LocalizationKeys.goal50Completed)
            content.body = localizationManager.localizedString(for: LocalizationKeys.goal50CompletedDesc)
        case 0.75:
            content.title = localizationManager.localizedString(for: LocalizationKeys.goal75Completed)
            content.body = localizationManager.localizedString(for: LocalizationKeys.goal75CompletedDesc)
        case 1.0:
            content.title = localizationManager.localizedString(for: LocalizationKeys.goalCompleted)
            content.body = String(format: localizationManager.localizedString(for: LocalizationKeys.goalCompletedDesc), String(format: "%.1f", WeightDataManager.shared.getDisplayWeight(targetWeight, in: preferredUnit)), preferredUnit)
        default:
            return
        }
        
        content.sound = .default
        content.categoryIdentifier = "GOAL_MILESTONE"
        content.badge = NSNumber(value: 1)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // Enviar inmediatamente
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            // Notificar al sistema sobre el error
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .init("notificationError"),
                    object: nil,
                    userInfo: ["error": error, "type": "milestone"]
                )
            }
        }
    }
    
    func sendGoalCompletedNotification(for goal: WeightGoal) async {
        let content = UNMutableNotificationContent()
        
        // Configurar título y cuerpo localizados para objetivo completado
        content.title = localizationManager.localizedString(for: LocalizationKeys.goalCompleted)
        content.body = localizationManager.localizedString(for: LocalizationKeys.goalCompletedDesc)
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "goal_completed_\(goal.id?.uuidString ?? UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("Error sending goal completed notification: \(error)")
        }
    }
    
    // MARK: - Motivational Notifications
    
    func scheduleMotivationalNotification(for streak: Int) async {
        guard isAuthorized else { return }
        
        let motivationalMessages = getMotivationalMessage(for: streak)
        
        let content = UNMutableNotificationContent()
        content.title = motivationalMessages.title
        content.body = motivationalMessages.body
        content.sound = .default
        content.categoryIdentifier = "MOTIVATIONAL"
        
        let request = UNNotificationRequest(
            identifier: "motivational_\(streak)",
            content: content,
            trigger: nil
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            // Error enviando notificación motivacional
        }
    }
    
    private func getMotivationalMessage(for streak: Int) -> (title: String, body: String) {
        switch streak {
        case 3:
            return (localizationManager.localizedString(for: LocalizationKeys.streak3Days), localizationManager.localizedString(for: LocalizationKeys.streak3DaysDesc))
        case 7:
            return (localizationManager.localizedString(for: LocalizationKeys.streak7Days), localizationManager.localizedString(for: LocalizationKeys.streak7DaysDesc))
        case 14:
            return (localizationManager.localizedString(for: LocalizationKeys.streak14Days), localizationManager.localizedString(for: LocalizationKeys.streak14DaysDesc))
        case 30:
            return (localizationManager.localizedString(for: LocalizationKeys.streak30Days), localizationManager.localizedString(for: LocalizationKeys.streak30DaysDesc))
        case 60:
            return (localizationManager.localizedString(for: LocalizationKeys.streak60Days), localizationManager.localizedString(for: LocalizationKeys.streak60DaysDesc))
        case 90:
            return (localizationManager.localizedString(for: LocalizationKeys.streak90Days), localizationManager.localizedString(for: LocalizationKeys.streak90DaysDesc))
        default:
            return (localizationManager.localizedString(for: LocalizationKeys.keepGoing), localizationManager.localizedString(for: LocalizationKeys.keepGoingDesc))
        }
    }
    
    // MARK: - Reminder Notifications
    
    func scheduleWeeklyProgressReminder() async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = localizationManager.localizedString(for: LocalizationKeys.weeklyProgressTitle)
        content.body = localizationManager.localizedString(for: LocalizationKeys.weeklyProgressDesc)
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_PROGRESS"
        
        // Programar para los domingos a las 6 PM
        var components = DateComponents()
        components.weekday = 1 // Domingo
        components.hour = 18
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "weekly_progress_reminder",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            // Error programando recordatorio semanal
        }
    }
    
    func cancelWeeklyProgressReminder() async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["weekly_progress_reminder"])
    }
    
    // MARK: - Notification Categories
    
    func setupNotificationCategories() {
        let dailyReminderCategory = UNNotificationCategory(
            identifier: "DAILY_REMINDER",
            actions: [
                UNNotificationAction(
                    identifier: "QUICK_LOG",
                    title: localizationManager.localizedString(for: LocalizationKeys.logWeight),
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "SNOOZE",
                    title: localizationManager.localizedString(for: LocalizationKeys.remindIn1Hour),
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let goalMilestoneCategory = UNNotificationCategory(
            identifier: "GOAL_MILESTONE",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_PROGRESS",
                    title: localizationManager.localizedString(for: LocalizationKeys.viewProgress),
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let motivationalCategory = UNNotificationCategory(
            identifier: "MOTIVATIONAL",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_STATS",
                    title: localizationManager.localizedString(for: LocalizationKeys.viewStats),
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let weeklyProgressCategory = UNNotificationCategory(
            identifier: "WEEKLY_PROGRESS",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_CHARTS",
                    title: localizationManager.localizedString(for: LocalizationKeys.viewCharts),
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([
            dailyReminderCategory,
            goalMilestoneCategory,
            motivationalCategory,
            weeklyProgressCategory
        ])
    }
    
    // MARK: - Utility Methods
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    func getDeliveredNotifications() async -> [UNNotification] {
        return await notificationCenter.deliveredNotifications()
    }
    
    func removeAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func removeAllDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Mostrar notificación incluso cuando la app está en primer plano
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        let _ = response.notification.request.identifier
        
        // Asegurar que las acciones se ejecuten en el hilo principal
        DispatchQueue.main.async {
            switch actionIdentifier {
            case "QUICK_LOG":
                // Abrir la app en la pantalla de registro rápido
                NotificationCenter.default.post(name: .openQuickLog, object: nil)
                
            case "SNOOZE":
                // Programar recordatorio en 1 hora
                Task {
                    await self.scheduleSnoozeReminder()
                }
                
            case "VIEW_PROGRESS":
                // Abrir la app en la pantalla de progreso
                NotificationCenter.default.post(name: .openProgress, object: nil)
                
            case "VIEW_STATS":
                // Abrir la app en la pantalla de estadísticas
                NotificationCenter.default.post(name: .openStats, object: nil)
                
            case "VIEW_CHARTS":
                // Abrir la app en la pantalla de gráficos
                NotificationCenter.default.post(name: .openCharts, object: nil)
                
            case UNNotificationDefaultActionIdentifier:
                // Usuario tocó la notificación (acción por defecto)
                // Abrir la aplicación en la pantalla principal
                NotificationCenter.default.post(name: .openMainView, object: nil)
                
            default:
                break
            }
        }
        
        completionHandler()
    }
    
    private func scheduleSnoozeReminder() async {
        let content = UNMutableNotificationContent()
        content.title = localizationManager.localizedString(for: LocalizationKeys.weightReminder)
        content.body = localizationManager.localizedString(for: LocalizationKeys.weightReminderDesc)
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 3600, // 1 hora
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "snooze_reminder_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            // Error programando recordatorio de snooze
        }
    }
}