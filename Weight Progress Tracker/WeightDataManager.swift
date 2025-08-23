//  WeightDataManager.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import Foundation
import CoreData
import Combine

class WeightDataManager: ObservableObject {
    static let shared = WeightDataManager()
    
    private let persistenceController: PersistenceController
    private var viewContext: NSManagedObjectContext {
        persistenceController.container.viewContext
    }
    
    @Published var weightEntries: [WeightEntry] = []
    @Published var userSettings: UserSettings?
    @Published var activeGoal: WeightGoal? // Temporalmente comentado hasta que Core Data genere las clases
    
    init(persistenceController: PersistenceController = PersistenceController.shared) {
        self.persistenceController = persistenceController
        loadUserSettings()
        loadActiveGoal()
        loadRecentWeightEntries()
    }
    
    // MARK: - Weight Entry Operations
    
    func addWeightEntry(weight: Double, unit: String = WeightUnit.kilograms.rawValue, timestamp: Date = Date()) {
        let weightEntry = WeightEntry(context: viewContext)
        weightEntry.id = UUID()
        weightEntry.weight = unit == WeightUnit.kilograms.rawValue ? weight : convertlbToKg(weight)
        weightEntry.unit = unit
        weightEntry.timestamp = timestamp
        weightEntry.createdAt = Date()
        weightEntry.updatedAt = Date()
        
        saveContext()
        loadRecentWeightEntries()
        
        // Notificar que los datos de peso han sido actualizados
        NotificationHelper.shared.notifyWeightDataUpdated()
        
        // Registrar entrada de peso para el sistema de reseñas ASO
        ReviewRequestManager.trackWeightEntry()
    }
    
    func updateWeightEntry(_ entry: WeightEntry, weight: Double, unit: String) {
        entry.weight = unit == WeightUnit.kilograms.rawValue ? weight : convertlbToKg(weight)
        entry.unit = unit
        entry.updatedAt = Date()
        
        saveContext()
        loadRecentWeightEntries()
        
        // Notificar que los datos de peso han sido actualizados
        NotificationHelper.shared.notifyWeightDataUpdated()
    }
    
    func deleteWeightEntry(_ entry: WeightEntry) {
        viewContext.delete(entry)
        saveContext()
        loadRecentWeightEntries()
    }
    
    func getWeightEntries(for period: TimePeriod) -> [WeightEntry] {
        let request: NSFetchRequest<WeightEntry> = WeightEntry.fetchRequest()
        let calendar = Calendar.current
        let endDate = Date()
        
        let startDate: Date
        switch period {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .month:
            startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        case .quarter:
            startDate = calendar.date(byAdding: .day, value: -90, to: endDate) ?? endDate
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        }
        
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WeightEntry.timestamp, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            // Error obteniendo entradas de peso
            return []
        }
    }
    
    func getLatestWeightEntry() -> WeightEntry? {
        let request: NSFetchRequest<WeightEntry> = WeightEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WeightEntry.timestamp, ascending: false)]
        request.fetchLimit = 1
        
        do {
            return try viewContext.fetch(request).first
        } catch {
            // Error obteniendo última entrada de peso
            return nil
        }
    }
    
    func getWeeklyProgress() -> (current: Double?, previous: Double?, change: Double?) {
        let calendar = Calendar.current
        let now = Date()
        
        // Peso actual (última entrada)
        let currentWeight = getLatestWeightEntry()?.weight
        
        // Peso de hace una semana
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let request: NSFetchRequest<WeightEntry> = WeightEntry.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp <= %@", weekAgo as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WeightEntry.timestamp, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let previousWeight = try viewContext.fetch(request).first?.weight
            
            if let current = currentWeight, let previous = previousWeight {
                return (current, previous, current - previous)
            }
            
            return (currentWeight, previousWeight, nil)
        } catch {
            // Error calculando progreso semanal
            return (currentWeight, nil, nil)
        }
    }
    
    // MARK: - User Settings Operations
    
    func loadUserSettings() {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        
        do {
            let settings = try viewContext.fetch(request)
            if let existingSettings = settings.first {
                self.userSettings = existingSettings
            } else {
                createDefaultUserSettings()
            }
        } catch {
            // Error cargando configuración de usuario
            createDefaultUserSettings()
        }
    }
    
    func createDefaultUserSettings() {
        let settings = UserSettings(context: viewContext)
        settings.id = UUID()
        settings.preferredUnit = WeightUnit.kilograms.rawValue
        settings.targetWeight = 70.0

        settings.notificationsEnabled = true
        settings.reminderTime = Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: Date())
        settings.selectedTheme = "system"
        settings.createdAt = Date()
        settings.updatedAt = Date()
        
        self.userSettings = settings
        saveContext()
        
        // Programar notificaciones diarias automáticamente
        if let reminderTime = settings.reminderTime {
            Task {
                await NotificationManager.shared.scheduleDailyReminder(at: reminderTime)
            }
        }
    }
    
    func updateUserSettings(preferredUnit: String? = nil, targetWeight: Double? = nil, notificationsEnabled: Bool? = nil, reminderTime: Date? = nil, selectedTheme: String? = nil) {
        guard let settings = userSettings else { return }
        
        if let unit = preferredUnit { settings.preferredUnit = unit }
        if let target = targetWeight { settings.targetWeight = target }

        if let notifications = notificationsEnabled { settings.notificationsEnabled = notifications }
        if let reminder = reminderTime { settings.reminderTime = reminder }
        if let theme = selectedTheme { settings.selectedTheme = theme }
        
        settings.updatedAt = Date()
        saveContext()
        
        // Notificar que las configuraciones han sido actualizadas
        NotificationHelper.shared.notifySettingsUpdated()
    }
    
    @MainActor
    func getActiveGoal() async -> WeightGoal? {
        // Si quieres hacer fetch fresco cada vez:
        let request: NSFetchRequest<WeightGoal> = WeightGoal.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WeightGoal.createdAt, ascending: false)]
        request.fetchLimit = 1

        return await withCheckedContinuation { continuation in
            viewContext.perform {
                do {
                    let goal = try self.viewContext.fetch(request).first
                    self.activeGoal = goal
                    continuation.resume(returning: goal)
                } catch {
                    // Error obteniendo meta activa
                    continuation.resume(returning: self.activeGoal) // fallback a cache
                }
            }
        }
    }

    @MainActor
    func getLatestWeight() async -> WeightEntry? {
        return await withCheckedContinuation { continuation in
            viewContext.perform {
                let entry = self.getLatestWeightEntry()
                continuation.resume(returning: entry)
            }
        }
    }
    
    // MARK: - Weight Goal Operations
    
    func loadActiveGoal() {
        let request: NSFetchRequest<WeightGoal> = WeightGoal.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WeightGoal.createdAt, ascending: false)]
        request.fetchLimit = 1
        
        do {
            self.activeGoal = try viewContext.fetch(request).first
        } catch {
            // Error cargando meta activa
        }
    }
    
    func createGoal(targetWeight: Double, targetDate: Date? = nil) {
        viewContext.perform {
            do {
                // Desactivar objetivo anterior si existe
                if let currentGoal = self.activeGoal {
                    currentGoal.isActive = false
                }
                
                let goal = WeightGoal(context: self.viewContext)
                goal.id = UUID()
                goal.targetWeight = targetWeight
                goal.targetDate = targetDate
                goal.startDate = Date()
                goal.startWeight = self.getLatestWeightEntry()?.weight ?? 0.0
                goal.isActive = true
                goal.createdAt = Date()
                goal.updatedAt = Date()
                
                try self.viewContext.save()
                
                DispatchQueue.main.async {
                    self.activeGoal = goal
                    self.loadActiveGoal()
                    NotificationHelper.shared.notifyGoalUpdated(goal: goal)
                }
            } catch {
                // Error creando meta
                DispatchQueue.main.async {
                    NotificationHelper.shared.notifyGoalCreationFailed(error: error)
                }
            }
        }
    }
    
    func updateGoal(_ goal: WeightGoal, targetWeight: Double? = nil, targetDate: Date? = nil) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            viewContext.perform {
                do {
                    if let target = targetWeight { goal.targetWeight = target }
                    if let date = targetDate { goal.targetDate = date }
                    goal.updatedAt = Date()
                    
                    try self.viewContext.save()
                    continuation.resume()
                } catch {
                    // Error actualizando meta
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    @MainActor
    func completeGoal(_ goal: WeightGoal) async {
        await withCheckedContinuation { continuation in
            viewContext.perform {
                do {
                    // Marcar como completado/inactivo
                    goal.isActive = false
                    // goal.completedAt = Date() // ⬅️ Descomenta si tu modelo tiene este campo
                    goal.updatedAt = Date()

                    // Si era el activo, limpiar referencia
                    if self.activeGoal?.objectID == goal.objectID {
                        self.activeGoal = nil
                    }

                    try self.viewContext.save()

                    // Refrescar caches
                    self.loadActiveGoal()
                    self.loadRecentWeightEntries()
                    
                    // Registrar objetivo completado para el sistema de reseñas ASO
                    ReviewRequestManager.trackGoalCompletion()

                    continuation.resume()
                } catch {
                    // Error completando meta
                    continuation.resume()
                }
            }
        }
    }

    
    func deleteGoal(_ goal: WeightGoal) async -> Bool {
        return await withCheckedContinuation { continuation in
            viewContext.perform {
                do {
                    // Verificar si el objetivo existe antes de eliminarlo
                    guard !goal.isDeleted else {
                        continuation.resume(returning: false)
                        return
                    }
                    
                    // Si era el objetivo activo, limpiarlo usando objectID para comparación segura
                    if let activeGoal = self.activeGoal, activeGoal.objectID == goal.objectID {
                        self.activeGoal = nil
                    }
                    
                    self.viewContext.delete(goal)
                    try self.viewContext.save()
                    
                    // Actualizar caches después de eliminar
                    DispatchQueue.main.async {
                        self.loadActiveGoal()
                        self.loadRecentWeightEntries()
                    }
                    
                    continuation.resume(returning: true)
                } catch {
                    // Error eliminando meta
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    func getGoalProgress() -> Double? {
        guard let goal = activeGoal,
              let currentWeight = getLatestWeightEntry()?.weight else { return nil }
        
        let totalChange = goal.targetWeight - goal.startWeight
        let currentChange = currentWeight - goal.startWeight
        
        if totalChange == 0 { return 1.0 }
        
        return min(max(currentChange / totalChange, 0.0), 1.0)
    }
    
    func getEstimatedTimeToGoal() -> Date? {
        guard let goal = activeGoal,
              let currentWeight = getLatestWeightEntry()?.weight else { return nil }
        
        let weeklyEntries = getWeightEntries(for: .week)
        guard weeklyEntries.count >= 2 else { return nil }
        
        let weightChange = currentWeight - (weeklyEntries.first?.weight ?? currentWeight)
        let remainingWeight = goal.targetWeight - currentWeight
        
        if weightChange == 0 { return nil }
        
        let weeksToGoal = remainingWeight / weightChange
        return Calendar.current.date(byAdding: .weekOfYear, value: Int(weeksToGoal), to: Date())
    }
    
    // MARK: - Helper Methods
    
    func loadRecentWeightEntries() {
        let request: NSFetchRequest<WeightEntry> = WeightEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WeightEntry.timestamp, ascending: false)]
        request.fetchLimit = 30
        
        do {
            self.weightEntries = try viewContext.fetch(request)
        } catch {
            // Error cargando entradas de peso
            self.weightEntries = []
        }
    }
    
    func saveContext() {
        do {
            try viewContext.save()
        } catch {
            // Error guardando contexto
        }
    }
    
    func convertlbToKg(_ lb: Double) -> Double {
        return lb * 0.453592
    }
    
    func convertKgTolb(_ kg: Double) -> Double {
        return kg * 2.20462
    }
    
    func getDisplayWeight(_ weight: Double, in unit: String) -> Double {
        if unit == WeightUnit.pounds.rawValue {
            return convertKgTolb(weight)
        }
        return weight
    }
    
    func formatWeight(_ weight: Double) -> String {
        let unit = userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
        let displayWeight = getDisplayWeight(weight, in: unit)
        return String(format: "%.1f %@", displayWeight, unit)
    }
    
    func formatWeightValue(_ weight: Double) -> Double {
        let unit = userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
        return getDisplayWeight(weight, in: unit)
    }
    
    // MARK: - Goal Progress Calculation
    
    func calculateGoalProgress(for goal: WeightGoal, currentWeight: Double) -> Double {
        guard goal.startWeight != goal.targetWeight else { return 1.0 }
        
        let totalChange = goal.targetWeight - goal.startWeight
        let currentChange = currentWeight - goal.startWeight
        
        return min(max(currentChange / totalChange, 0.0), 1.0)
    }
    

    
    // MARK: - Sample Data Creation
    
    func createSampleDataIfNeeded() {
        // Solo crear datos de ejemplo si no hay entradas existentes
        guard weightEntries.isEmpty else { return }
        
        let calendar = Calendar.current
        let today = Date()
        
        // Crear entradas de peso de ejemplo para los últimos 30 días
        let sampleWeights = [75.0, 74.8, 74.5, 74.2, 74.0, 73.8, 73.5, 73.2, 73.0, 72.8,
                           72.5, 72.3, 72.0, 71.8, 71.5, 71.3, 71.0, 70.8, 70.5, 70.3,
                           70.0, 69.8, 69.5, 69.3, 69.0, 68.8, 68.5, 68.3, 68.0, 67.8]
        
        for (index, weight) in sampleWeights.enumerated() {
            let daysAgo = 29 - index
            let entryDate = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            
            let weightEntry = WeightEntry(context: viewContext)
            weightEntry.id = UUID()
            weightEntry.weight = weight
            weightEntry.unit = WeightUnit.kilograms.rawValue
            weightEntry.timestamp = entryDate
            weightEntry.createdAt = entryDate
            weightEntry.updatedAt = entryDate
        }
        
        // Crear un objetivo de ejemplo si no existe uno activo
        if activeGoal == nil {
            let goal = WeightGoal(context: viewContext)
            goal.id = UUID()
            goal.targetWeight = 65.0
            goal.startWeight = 75.0
            goal.startDate = calendar.date(byAdding: .day, value: -30, to: today) ?? today
            goal.targetDate = calendar.date(byAdding: .day, value: 60, to: today) ?? today
            goal.isActive = true
            goal.createdAt = Date()
            goal.updatedAt = Date()
            
            self.activeGoal = goal
        }
        
        saveContext()
        loadRecentWeightEntries()
        loadActiveGoal()
    }
    
    // MARK: - Data Deletion
    
    func getEntriesForPeriod(_ period: TimePeriod) -> [WeightEntry] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate: Date
        switch period {
        case .week: startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .month: startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        case .quarter: startDate = calendar.date(byAdding: .day, value: -90, to: endDate) ?? endDate
        case .year: startDate = calendar.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        }

        return weightEntries
            .filter { e in
                let d = e.timestamp ?? .distantPast
                return d >= startDate && d <= endDate
            }
            .sorted { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }
    }

    
    // Temporarily commented out due to Core Data class generation issues
    func deleteAllData() async -> Bool {
        return await withCheckedContinuation { continuation in
            viewContext.perform {
                do {
                    // Eliminar todas las entradas de peso
                    let weightRequest: NSFetchRequest<NSFetchRequestResult> = WeightEntry.fetchRequest()
                    let weightDeleteRequest = NSBatchDeleteRequest(fetchRequest: weightRequest)
                    try self.viewContext.execute(weightDeleteRequest)
                    
                    // Eliminar todos los objetivos
                    let goalRequest: NSFetchRequest<NSFetchRequestResult> = WeightGoal.fetchRequest()
                    let goalDeleteRequest = NSBatchDeleteRequest(fetchRequest: goalRequest)
                    try self.viewContext.execute(goalDeleteRequest)
                    
                    // Mantener configuraciones de usuario pero resetear algunos valores
                    let settingsRequest: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
                    if let settings = try self.viewContext.fetch(settingsRequest).first {
                        settings.targetWeight = 0
            
                        settings.notificationsEnabled = false
                    }
                    
                    try self.viewContext.save()
                    
                    // Recargar datos después de eliminar
                    self.loadRecentWeightEntries()
                    
                    // Notificar que los datos han sido actualizados
                    DispatchQueue.main.async {
                        NotificationHelper.shared.notifyWeightDataUpdated()
                    }
                    
                    continuation.resume(returning: true)
                } catch {
                    // Error eliminando todos los datos
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    // MARK: - Statistics Methods
    
    func getWeightStatistics(for period: TimePeriod) -> (avg: Double, min: Double, max: Double)? {
        let entries = getWeightEntries(for: period)
        guard !entries.isEmpty else { return nil }
        
        let weights = entries.map { $0.weight }
        let avg = weights.reduce(0, +) / Double(weights.count)
        let min = weights.min() ?? 0
        let max = weights.max() ?? 0
        
        let unit = userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
        let displayAvg = getDisplayWeight(avg, in: unit)
        let displayMin = getDisplayWeight(min, in: unit)
        let displayMax = getDisplayWeight(max, in: unit)
        
        return (avg: displayAvg, min: displayMin, max: displayMax)
    }
    
    func getWeightChange() -> Double? {
        let entries = weightEntries.sorted { $0.timestamp ?? Date() < $1.timestamp ?? Date() }
        guard entries.count >= 2 else { return nil }
        
        let latest = entries.last?.weight ?? 0
        let previousIndex = entries.count - 2
        guard previousIndex >= 0 && previousIndex < entries.count else { return nil }
        let previous = entries[previousIndex].weight
        
        return latest - previous
    }
    
    func getGoalProgressPercentage() -> Double {
        guard let goal = activeGoal,
              let currentWeight = getLatestWeightEntry()?.weight,
              let startWeight = getStartWeight() else {
            return 0.0
        }
        
        let totalWeightToLose = abs(startWeight - goal.targetWeight)
        let weightLostSoFar = abs(startWeight - currentWeight)
        
        guard totalWeightToLose > 0 else { return 1.0 }
        
        return min(weightLostSoFar / totalWeightToLose, 1.0)
    }
    
    private func getStartWeight() -> Double? {
        let request: NSFetchRequest<WeightEntry> = WeightEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WeightEntry.timestamp, ascending: true)]
        request.fetchLimit = 1
        
        do {
            return try viewContext.fetch(request).first?.weight
        } catch {
            // Error obteniendo peso inicial
            return nil
        }
    }
    
    func isGoalToLoseWeight() -> Bool {
        guard let goal = activeGoal,
              let currentWeight = getLatestWeightEntry()?.weight else {
            return true // Default assumption
        }
        
        return goal.targetWeight < currentWeight
    }
    
    func getTimeSinceLastEntry() -> String {
        guard let lastEntry = getLatestWeightEntry(),
              let timestamp = lastEntry.timestamp else {
            return LocalizationKeys.noRecordsTime.localized
        }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(timestamp)
        
        let hours = Int(timeInterval / 3600)
        let days = Int(timeInterval / 86400)
        
        if days > 0 {
            if days == 1 {
                return LocalizationKeys.dayAgo.localized
            } else {
                return String(format: LocalizationKeys.daysAgo.localized, days)
            }
        } else if hours > 0 {
            return String(format: LocalizationKeys.hoursAgo.localized, hours)
        } else {
            return LocalizationKeys.lessThanHour.localized
        }
    }
    
    // MARK: - Streak and Insights Methods
    
    func getCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Obtener todas las entradas ordenadas por fecha descendente
        let request: NSFetchRequest<WeightEntry> = WeightEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WeightEntry.timestamp, ascending: false)]
        
        do {
            let entries = try viewContext.fetch(request)
            guard !entries.isEmpty else { return 0 }
            
            // Agrupar entradas por día (solo fechas únicas)
            let uniqueDays = Set(entries.compactMap { entry -> Date? in
                guard let timestamp = entry.timestamp else { return nil }
                return calendar.startOfDay(for: timestamp)
            })
            
            guard !uniqueDays.isEmpty else { return 0 }
            
            // Calcular racha actual (días consecutivos desde hoy hacia atrás)
            var currentStreakCount = 0
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
            
            return currentStreakCount
        } catch {
            // Error calculando racha
            return 0
        }
    }
    
    func getPeriodInsight(for period: TimePeriod) -> String {
        let entries = getWeightEntries(for: period)
        guard !entries.isEmpty else {
            return LocalizationKeys.insufficientDataInsights.localized
        }
        
        let weights = entries.map { $0.weight }
        guard let firstWeight = weights.first, let lastWeight = weights.last else {
            return LocalizationKeys.insufficientData.localized
        }
        
        let weightChange = lastWeight - firstWeight
        let avgWeight = weights.reduce(0, +) / Double(weights.count)
        let isLosingWeight = isGoalToLoseWeight()
        let unit = userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
        
        // Convertir valores para mostrar según la unidad preferida
        let displayWeightChange = getDisplayWeight(abs(weightChange), in: unit)
        let displayAvgWeight = getDisplayWeight(avgWeight, in: unit)
        
        // Generar insight basado en el período y el progreso
        switch period {
        case .week:
            if abs(weightChange) < 0.2 {
                return LocalizationKeys.weightStableWeek.localized
            } else if weightChange < 0 {
                return isLosingWeight ? String(format: LocalizationKeys.excellentProgress.localized, String(format: "%.1f", displayWeightChange), unit) : String(format: LocalizationKeys.lostWeightWeek.localized, String(format: "%.1f", displayWeightChange), unit)
            } else {
                return isLosingWeight ? String(format: LocalizationKeys.keepFocusGoal.localized, String(format: "%.1f", displayWeightChange), unit) : String(format: LocalizationKeys.gainedWeightWeek.localized, String(format: "%.1f", displayWeightChange), unit)
            }
            
        case .month:
            let weeklyAverage = abs(weightChange) / 4.0
            let displayWeeklyAverage = getDisplayWeight(weeklyAverage, in: unit)
            if abs(weightChange) < 0.5 {
                return String(format: LocalizationKeys.averageWeightMonth.localized, String(format: "%.1f", displayAvgWeight), unit)
            } else if weightChange < 0 {
                return String(format: LocalizationKeys.lostWeightMonth.localized, String(format: "%.1f", displayWeightChange), unit, String(format: "%.1f", displayWeeklyAverage), unit)
            } else {
                return String(format: LocalizationKeys.gainedWeightMonth.localized, String(format: "%.1f", displayWeightChange), unit, String(format: "%.1f", displayWeeklyAverage), unit)
            }
            
        case .quarter:
            let monthlyAverage = abs(weightChange) / 3.0
            let displayMonthlyAverage = getDisplayWeight(monthlyAverage, in: unit)
            if weightChange < 0 {
                return String(format: LocalizationKeys.lostWeightQuarter.localized, String(format: "%.1f", displayWeightChange), unit, String(format: "%.1f", displayMonthlyAverage), unit)
            } else {
                return String(format: LocalizationKeys.gainedWeightQuarter.localized, String(format: "%.1f", displayWeightChange), unit, String(format: "%.1f", displayMonthlyAverage), unit)
            }
            
        case .year:
            let monthlyAverage = abs(weightChange) / 12.0
            let displayMonthlyAverage = getDisplayWeight(monthlyAverage, in: unit)
            if weightChange < 0 {
                return String(format: LocalizationKeys.lostWeightYear.localized, String(format: "%.1f", displayWeightChange), unit, String(format: "%.1f", displayMonthlyAverage), unit)
            } else {
                return String(format: LocalizationKeys.gainedWeightYear.localized, String(format: "%.1f", displayWeightChange), unit, String(format: "%.1f", displayMonthlyAverage), unit)
            }
        }
    }
    
    func getQuickActions() -> [QuickAction] {
        var actions: [QuickAction] = []
        
        // Acción para importar datos de Salud (si está disponible)
        actions.append(QuickAction(
            id: "import-health",
            title: LocalizationKeys.importHealth.localized,
            subtitle: LocalizationKeys.importHealthSubtitle.localized,
            icon: "heart.fill",
            action: .importHealth
        ))
        
        // Acción para exportar datos
        actions.append(QuickAction(
            id: "export-csv",
            title: LocalizationKeys.exportCSV.localized,
            subtitle: LocalizationKeys.exportCSVSubtitle.localized,
            icon: "square.and.arrow.up",
            action: .exportCSV
        ))
        
        // Acción para editar meta
        if activeGoal != nil {
            actions.append(QuickAction(
                id: "edit-goal",
                title: LocalizationKeys.editGoalAction.localized,
                subtitle: LocalizationKeys.editGoalSubtitle.localized,
                icon: "target",
                action: .editGoal
            ))
        } else {
            actions.append(QuickAction(
                id: "create-goal",
                title: LocalizationKeys.createGoalAction.localized,
                subtitle: LocalizationKeys.createGoalSubtitle.localized,
                icon: "target",
                action: .createGoal
            ))
        }
        
        return actions
    }
}

// MARK: - Quick Action Models

struct QuickAction: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let action: QuickActionType
}

enum QuickActionType {
    case importHealth
    case exportCSV
    case editGoal
    case createGoal
}
