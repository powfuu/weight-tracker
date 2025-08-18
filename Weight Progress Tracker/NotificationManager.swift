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
            print("Error solicitando autorización de notificaciones: \(error)")
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
            print("Notificaciones no autorizadas")
            return
        }
        
        // Cancelar recordatorio anterior
        await cancelDailyReminder()
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        let content = UNMutableNotificationContent()
        content.title = "🏃‍♂️ Momento de pesarte"
        content.body = "Registra tu peso de hoy y mantén tu progreso al día"
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
            print("Recordatorio diario programado para las \(components.hour ?? 0):\(String(format: "%02d", components.minute ?? 0))")
        } catch {
            print("Error programando recordatorio diario: \(error)")
        }
    }
    
    func cancelDailyReminder() async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["daily_weight_reminder"])
        print("Recordatorio diario cancelado")
    }
    
    // MARK: - Goal Notifications
    
    func scheduleGoalMilestoneNotification(progress: Double, targetWeight: Double) async {
        guard isAuthorized else { return }
        
        let milestones = [0.25, 0.5, 0.75, 1.0]
        
        for milestone in milestones {
            if progress >= milestone {
                let identifier = "goal_milestone_\(Int(milestone * 100))"
                
                // Verificar si ya se envió esta notificación
                let deliveredNotifications = await notificationCenter.deliveredNotifications()
                let alreadyDelivered = deliveredNotifications.contains { $0.request.identifier == identifier }
                
                if !alreadyDelivered {
                    await sendGoalMilestoneNotification(milestone: milestone, targetWeight: targetWeight, identifier: identifier)
                }
            }
        }
    }
    
    private func sendGoalMilestoneNotification(milestone: Double, targetWeight: Double, identifier: String) async {
        let content = UNMutableNotificationContent()
        
        let preferredUnit = WeightDataManager.shared.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
        
        switch milestone {
        case 0.25:
            content.title = "🎯 ¡25% completado!"
            content.body = "Vas por buen camino hacia tu objetivo de \(String(format: "%.1f", WeightDataManager.shared.getDisplayWeight(targetWeight, in: preferredUnit))) \(preferredUnit)"
        case 0.5:
            content.title = "🔥 ¡Mitad del camino!"
            content.body = "¡Increíble progreso! Ya estás a medio camino de tu objetivo"
        case 0.75:
            content.title = "⭐ ¡75% completado!"
            content.body = "¡Casi lo logras! Solo un poco más para alcanzar tu meta"
        case 1.0:
            content.title = "🏆 ¡Objetivo alcanzado!"
            content.body = "¡Felicitaciones! Has alcanzado tu peso objetivo de \(String(format: "%.1f", WeightDataManager.shared.getDisplayWeight(targetWeight, in: preferredUnit))) \(preferredUnit)"
        default:
            return
        }
        
        content.sound = .default
        content.categoryIdentifier = "GOAL_MILESTONE"
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // Enviar inmediatamente
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("Error enviando notificación de hito: \(error)")
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
            print("Error enviando notificación motivacional: \(error)")
        }
    }
    
    private func getMotivationalMessage(for streak: Int) -> (title: String, body: String) {
        switch streak {
        case 3:
            return ("🔥 ¡3 días seguidos!", "Estás creando un gran hábito. ¡Sigue así!")
        case 7:
            return ("⭐ ¡Una semana completa!", "¡Increíble constancia! Tu dedicación está dando frutos")
        case 14:
            return ("💪 ¡Dos semanas seguidas!", "Tu compromiso es admirable. ¡Vas por buen camino!")
        case 30:
            return ("🏆 ¡Un mes completo!", "¡Felicitaciones! Has desarrollado un hábito sólido")
        case 60:
            return ("🌟 ¡Dos meses seguidos!", "Tu constancia es inspiradora. ¡Eres imparable!")
        case 90:
            return ("👑 ¡Tres meses seguidos!", "¡Eres un verdadero campeón de la constancia!")
        default:
            return ("🎯 ¡Sigue así!", "Cada día cuenta en tu camino hacia el éxito")
        }
    }
    
    // MARK: - Reminder Notifications
    
    func scheduleWeeklyProgressReminder() async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📊 Revisa tu progreso semanal"
        content.body = "Echa un vistazo a cómo ha sido tu semana y celebra tus logros"
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
            print("Error programando recordatorio semanal: \(error)")
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
                    title: "Registrar peso",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "SNOOZE",
                    title: "Recordar en 1 hora",
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
                    title: "Ver progreso",
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
                    title: "Ver estadísticas",
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
                    title: "Ver gráficos",
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
        
        switch actionIdentifier {
        case "QUICK_LOG":
            // Abrir la app en la pantalla de registro rápido
            NotificationCenter.default.post(name: .openQuickLog, object: nil)
            
        case "SNOOZE":
            // Programar recordatorio en 1 hora
            Task {
                await scheduleSnoozeReminder()
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
            
        default:
            break
        }
        
        completionHandler()
    }
    
    private func scheduleSnoozeReminder() async {
        let content = UNMutableNotificationContent()
        content.title = "⏰ Recordatorio de peso"
        content.body = "Es hora de registrar tu peso"
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
            print("Error programando recordatorio de snooze: \(error)")
        }
    }
}