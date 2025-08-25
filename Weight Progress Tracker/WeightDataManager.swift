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
    
    private let localizationManager = LocalizationManager.shared
    
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
    
    func addWeightEntry(weight: Double, unit: String = WeightUnit.kilograms.rawValue, timestamp: Date = Date()) async -> Result<Void, Error> {
        return await withCheckedContinuation { continuation in
            viewContext.perform {
                do {
                    let weightEntry = WeightEntry(context: self.viewContext)
                    weightEntry.id = UUID()
                    // Guardar el peso en la unidad original del usuario, sin conversión
                    weightEntry.weight = weight
                    weightEntry.unit = unit
                    weightEntry.timestamp = timestamp
                    weightEntry.createdAt = Date()
                    weightEntry.updatedAt = Date()
                    
                    // Intentar guardar el contexto
                    try self.viewContext.save()
                    
                    // Actualizar en el hilo principal
                    DispatchQueue.main.async {
                        self.loadRecentWeightEntries()
                        
                        // Notificar que los datos de peso han sido actualizados
                        NotificationHelper.shared.notifyWeightDataUpdated()
                        
                        // Registrar entrada de peso para el sistema de reseñas ASO
                        ReviewRequestManager.trackWeightEntry()
                    }
                    
                    continuation.resume(returning: .success(()))
                } catch {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
    
    func updateWeightEntry(_ entry: WeightEntry, weight: Double, unit: String) {
        // Guardar el peso en la unidad original del usuario, sin conversión
        entry.weight = weight
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
        case .threeDays:
            startDate = calendar.date(byAdding: .day, value: -3, to: endDate) ?? endDate
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .fifteenDays:
            startDate = calendar.date(byAdding: .day, value: -15, to: endDate) ?? endDate
        case .month:
            startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        case .threeMonths:
            startDate = calendar.date(byAdding: .day, value: -90, to: endDate) ?? endDate
        case .sixMonths:
            startDate = calendar.date(byAdding: .day, value: -180, to: endDate) ?? endDate
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
        
        // Verificar si se está cambiando la unidad preferida
        let oldUnit = settings.preferredUnit
        let isChangingUnit = preferredUnit != nil && preferredUnit != oldUnit
        
        if let unit = preferredUnit { 
            settings.preferredUnit = unit 
            
            // Convertir todos los pesos existentes a la nueva unidad
            if isChangingUnit {
                convertExistingWeightEntries(from: oldUnit, to: unit)
            }
        }
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
    
    @MainActor
    func createGoal(targetWeight: Double, targetDate: Date? = nil) async -> Bool {
        return await withCheckedContinuation { continuation in
            viewContext.perform {
                do {
                    // Desactivar objetivo anterior si existe
                    if let currentGoal = self.activeGoal {
                        currentGoal.isActive = false
                    }
                    
                    // Obtener el peso inicial de forma segura dentro del contexto
                    let request: NSFetchRequest<WeightEntry> = WeightEntry.fetchRequest()
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \WeightEntry.timestamp, ascending: false)]
                    request.fetchLimit = 1
                    
                    let latestWeight: Double
                    do {
                        let entries = try self.viewContext.fetch(request)
                        latestWeight = entries.first?.weight ?? 0.0
                    } catch {
                        latestWeight = 0.0
                    }
                    
                    let goal = WeightGoal(context: self.viewContext)
                    goal.id = UUID()
                    goal.targetWeight = targetWeight
                    goal.targetDate = targetDate
                    goal.startDate = Date()
                    goal.startWeight = latestWeight
                    goal.isActive = true
                    goal.createdAt = Date()
                    goal.updatedAt = Date()
                    
                    try self.viewContext.save()
                    
                    // Capturar el objectID para usar en el hilo principal
                    let goalObjectID = goal.objectID
                    
                    DispatchQueue.main.async {
                        // Obtener el objetivo desde el hilo principal usando el objectID
                        do {
                            let mainContextGoal = try self.viewContext.existingObject(with: goalObjectID) as? WeightGoal
                            self.activeGoal = mainContextGoal
                            self.loadActiveGoal()
                            if let goal = mainContextGoal {
                                NotificationHelper.shared.notifyGoalUpdated(goal: goal)
                            }
                        } catch {
                            // Error silencioso en producción
                        }
                    }
                    
                    continuation.resume(returning: true)
                } catch {
                    // Error creando meta
                    DispatchQueue.main.async {
                        NotificationHelper.shared.notifyGoalCreationFailed(error: error)
                    }
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    @MainActor
    func updateGoal(_ goal: WeightGoal, targetWeight: Double? = nil, targetDate: Date? = nil) async -> Bool {
        return await withCheckedContinuation { continuation in
            viewContext.perform {
                do {
                    // Verificar que el objetivo no esté eliminado
                    guard !goal.isDeleted else {
                        continuation.resume(returning: false)
                        return
                    }
                    
                    if let target = targetWeight { goal.targetWeight = target }
                    if let date = targetDate { goal.targetDate = date }
                    goal.updatedAt = Date()
                    
                    try self.viewContext.save()
                    
                    // Capturar el objectID para usar en el hilo principal
                    let goalObjectID = goal.objectID
                    
                    DispatchQueue.main.async {
                        self.loadActiveGoal()
                        // Obtener el objetivo desde el hilo principal usando el objectID
                        do {
                            let mainContextGoal = try self.viewContext.existingObject(with: goalObjectID) as? WeightGoal
                            if let goal = mainContextGoal {
                                NotificationHelper.shared.notifyGoalUpdated(goal: goal)
                            }
                        } catch {
                            // Error silencioso en producción
                        }
                    }
                    
                    continuation.resume(returning: true)
                } catch {
                    // Error actualizando meta
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    func markGoalNotificationSent(_ goal: WeightGoal) async {
        await withCheckedContinuation { continuation in
            viewContext.perform {
                goal.notificationSent = true
                self.saveContext()
                continuation.resume()
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
                    
                    // Capturar el objectID para usar en el hilo principal
                    let goalObjectID = goal.objectID
                    
                    // Notificar que el objetivo fue completado
                    DispatchQueue.main.async {
                        // Obtener el objetivo desde el hilo principal usando el objectID
                        do {
                            let mainContextGoal = try self.viewContext.existingObject(with: goalObjectID) as? WeightGoal
                            if let goal = mainContextGoal {
                                NotificationHelper.shared.notifyWeightGoalCompleted(goal: goal)
                            }
                            NotificationHelper.shared.notifyGoalUpdated(goal: nil) // nil indica que no hay objetivo activo
                        } catch {
                            // Error silencioso en producción
                            NotificationHelper.shared.notifyGoalUpdated(goal: nil)
                        }
                    }

                    continuation.resume()
                } catch {
                    // Error completando meta
                    continuation.resume()
                }
            }
        }
    }

    
    @MainActor
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
        
        let startWeight = goal.startWeight
        let targetWeight = goal.targetWeight
        
        guard startWeight != targetWeight else { return 1.0 }
        
        // Determinar si es objetivo de perder o ganar peso
        let isLosingWeight = targetWeight < startWeight
        let totalWeightChange = abs(targetWeight - startWeight)
        
        // Calcular progreso según la dirección del objetivo
        var currentProgress: Double = 0
        
        if isLosingWeight {
            // Objetivo de perder peso: progreso = peso perdido / peso total a perder
            let weightLost = max(startWeight - currentWeight, 0)
            currentProgress = weightLost / totalWeightChange
        } else {
            // Objetivo de ganar peso: progreso = peso ganado / peso total a ganar
            let weightGained = max(currentWeight - startWeight, 0)
            currentProgress = weightGained / totalWeightChange
        }
        
        // Limitar el progreso entre 0 y 1 (0% y 100%)
        return max(min(currentProgress, 1.0), 0.0)
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
            if viewContext.hasChanges {
                try viewContext.save()
            }
        } catch {
            // Log del error para debugging
            print("Error guardando contexto de Core Data: \(error.localizedDescription)")
            
            // Intentar rollback para mantener consistencia
            viewContext.rollback()
            
            // Notificar el error si es necesario
            DispatchQueue.main.async {
                NotificationHelper.shared.notifyDataSaveError(error: error)
            }
        }
    }
    
    func convertlbToKg(_ lb: Double) -> Double {
        return lb * 0.453592
    }
    
    func convertKgTolb(_ kg: Double) -> Double {
        return kg * 2.20462
    }
    
    // MARK: - Unit Conversion for Existing Data
    
    private func convertExistingWeightEntries(from oldUnit: String?, to newUnit: String) {
        guard let oldUnit = oldUnit, oldUnit != newUnit else { return }
        
        let request: NSFetchRequest<WeightEntry> = WeightEntry.fetchRequest()
        
        do {
            let allEntries = try viewContext.fetch(request)
            
            for entry in allEntries {
                // Solo convertir si la entrada está en la unidad antigua
                if entry.unit == oldUnit {
                    let convertedWeight: Double
                    
                    if oldUnit == WeightUnit.kilograms.rawValue && newUnit == WeightUnit.pounds.rawValue {
                        // Convertir de kg a lb
                        convertedWeight = convertKgTolb(entry.weight)
                    } else if oldUnit == WeightUnit.pounds.rawValue && newUnit == WeightUnit.kilograms.rawValue {
                        // Convertir de lb a kg
                        convertedWeight = convertlbToKg(entry.weight)
                    } else {
                        // No hay conversión necesaria
                        continue
                    }
                    
                    entry.weight = convertedWeight
                    entry.unit = newUnit
                    entry.updatedAt = Date()
                }
            }
            
            // Guardar todos los cambios
            saveContext()
            
            // Recargar las entradas para reflejar los cambios
            loadRecentWeightEntries()
            
        } catch {
            // Error al obtener o convertir las entradas de peso
            print("Error converting existing weight entries: \(error)")
        }
    }
    
    func getDisplayWeight(_ weight: Double, in unit: String) -> Double {
        // Ahora que los pesos se guardan en su unidad original,
        // simplemente devolvemos el peso tal como está almacenado
        return weight
    }
    
    func getLocalizedUnitSymbol() -> String {
        let unit = userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
        if unit == WeightUnit.pounds.rawValue {
            return LocalizationManager.shared.localizedString(for: LocalizationKeys.lbSymbol)
        } else {
            return LocalizationManager.shared.localizedString(for: LocalizationKeys.kgSymbol)
        }
    }
    
    func formatWeight(_ weight: Double) -> String {
        let unit = userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
        let displayWeight = getDisplayWeight(weight, in: unit)
        let formattedWeight = LocalizationManager.shared.formatWeight(displayWeight)
        return "\(formattedWeight) \(getLocalizedUnitSymbol())"
    }
    
    func formatWeightValue(_ weight: Double) -> Double {
        let unit = userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
        return getDisplayWeight(weight, in: unit)
    }
    
    // MARK: - Goal Progress Calculation
    
    func calculateGoalProgress(for goal: WeightGoal, currentWeight: Double) -> Double {
        guard goal.startWeight != goal.targetWeight else { return 1.0 }
        
        let startWeight = goal.startWeight
        let targetWeight = goal.targetWeight
        
        // Determinar si es objetivo de perder o ganar peso
        let isLosingWeight = targetWeight < startWeight
        let totalWeightChange = abs(targetWeight - startWeight)
        
        // Calcular progreso según la dirección del objetivo
        var currentProgress: Double = 0
        
        if isLosingWeight {
            // Objetivo de perder peso: progreso = peso perdido / peso total a perder
            let weightLost = max(startWeight - currentWeight, 0)
            currentProgress = weightLost / totalWeightChange
        } else {
            // Objetivo de ganar peso: progreso = peso ganado / peso total a ganar
            let weightGained = max(currentWeight - startWeight, 0)
            currentProgress = weightGained / totalWeightChange
        }
        
        return max(min(currentProgress, 1.0), 0.0)
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
        case .threeDays: startDate = calendar.date(byAdding: .day, value: -3, to: endDate) ?? endDate
        case .week: startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .fifteenDays: startDate = calendar.date(byAdding: .day, value: -15, to: endDate) ?? endDate
        case .month: startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        case .threeMonths: startDate = calendar.date(byAdding: .day, value: -90, to: endDate) ?? endDate
        case .sixMonths: startDate = calendar.date(byAdding: .day, value: -180, to: endDate) ?? endDate
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
              let currentWeight = getLatestWeightEntry()?.weight else {
            return 0.0
        }
        
        let startWeight = goal.startWeight
        let targetWeight = goal.targetWeight
        
        // Determinar si es objetivo de perder o ganar peso
        let isLosingWeight = targetWeight < startWeight
        let totalWeightChange = abs(targetWeight - startWeight)
        
        // Calcular progreso según la dirección del objetivo
        var currentProgress: Double = 0
        
        if totalWeightChange > 0 {
            if isLosingWeight {
                // Objetivo de perder peso: progreso = peso perdido / peso total a perder
                let weightLost = max(startWeight - currentWeight, 0)
                currentProgress = weightLost / totalWeightChange
            } else {
                // Objetivo de ganar peso: progreso = peso ganado / peso total a ganar
                let weightGained = max(currentWeight - startWeight, 0)
                currentProgress = weightGained / totalWeightChange
            }
            // Limitar el progreso entre 0 y 1 (0% y 100%)
            currentProgress = max(min(currentProgress, 1.0), 0.0)
        } else {
            // Si no hay cambio de peso objetivo, considerar como completado
            currentProgress = 1.0
        }
        
        return currentProgress
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
            return LocalizationManager.shared.localizedString(for: LocalizationKeys.noRecordsTime)
        }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(timestamp)
        
        let hours = Int(timeInterval / 3600)
        let days = Int(timeInterval / 86400)
        
        if days > 0 {
            if days == 1 {
                return LocalizationManager.shared.localizedString(for: LocalizationKeys.dayAgo)
            } else {
                return String(format: LocalizationManager.shared.localizedString(for: LocalizationKeys.daysAgo), days)
            }
        } else if hours > 0 {
            return String(format: LocalizationManager.shared.localizedString(for: LocalizationKeys.hoursAgo), hours)
        } else {
            return LocalizationManager.shared.localizedString(for: LocalizationKeys.lessThanHour)
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
            return localizationManager.localizedString(for: LocalizationKeys.insufficientDataInsights)
        }
        
        let weights = entries.map { $0.weight }
        guard let firstWeight = weights.first, let lastWeight = weights.last else {
            return localizationManager.localizedString(for: LocalizationKeys.insufficientData)
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
        case .threeDays:
            if abs(weightChange) < 0.1 {
                return localizationManager.localizedString(for: LocalizationKeys.weightStableWeek)
            } else if weightChange < 0 {
                return isLosingWeight ? String(format: localizationManager.localizedString(for: LocalizationKeys.excellentProgress), String(format: "%.1f", displayWeightChange), unit) : String(format: localizationManager.localizedString(for: LocalizationKeys.lostWeightWeek), String(format: "%.1f", displayWeightChange), unit)
            } else {
                return isLosingWeight ? String(format: localizationManager.localizedString(for: LocalizationKeys.keepFocusGoal), String(format: "%.1f", displayWeightChange), unit) : String(format: localizationManager.localizedString(for: LocalizationKeys.gainedWeightWeek), String(format: "%.1f", displayWeightChange), unit)
            }
            
        case .week:
            if abs(weightChange) < 0.2 {
                return localizationManager.localizedString(for: LocalizationKeys.weightStableWeek)
            } else if weightChange < 0 {
                return isLosingWeight ? String(format: localizationManager.localizedString(for: LocalizationKeys.excellentProgress), String(format: "%.1f", displayWeightChange), unit) : String(format: localizationManager.localizedString(for: LocalizationKeys.lostWeightWeek), String(format: "%.1f", displayWeightChange), unit)
            } else {
                return isLosingWeight ? String(format: localizationManager.localizedString(for: LocalizationKeys.keepFocusGoal), String(format: "%.1f", displayWeightChange), unit) : String(format: localizationManager.localizedString(for: LocalizationKeys.gainedWeightWeek), String(format: "%.1f", displayWeightChange), unit)
            }
            
        case .fifteenDays:
            let dailyAverage = abs(weightChange) / 15.0
            let displayDailyAverage = getDisplayWeight(dailyAverage, in: unit)
            if abs(weightChange) < 0.3 {
                return String(format: localizationManager.localizedString(for: LocalizationKeys.averageWeightMonth), String(format: "%.1f", displayAvgWeight), unit)
            } else if weightChange < 0 {
                return String(format: localizationManager.localizedString(for: LocalizationKeys.lostWeightMonth), String(format: "%.1f", displayWeightChange), unit, String(format: "%.1f", displayDailyAverage), unit)
            } else {
                return String(format: localizationManager.localizedString(for: LocalizationKeys.gainedWeightMonth), String(format: "%.1f", displayWeightChange), unit, String(format: "%.1f", displayDailyAverage), unit)
            }
            
        case .month:
            let weeklyAverage = abs(weightChange) / 4.0
            let displayWeeklyAverage = getDisplayWeight(weeklyAverage, in: unit)
            if abs(weightChange) < 0.5 {
                return String(format: localizationManager.localizedString(for: LocalizationKeys.averageWeightMonth), String(format: "%.1f", displayAvgWeight), unit)
            } else if weightChange < 0 {
                return String(format: localizationManager.localizedString(for: LocalizationKeys.lostWeightMonth), String(format: "%.1f", displayWeightChange), unit, String(format: "%.1f", displayWeeklyAverage), unit)
            } else {
                return String(format: localizationManager.localizedString(for: LocalizationKeys.gainedWeightMonth), String(format: "%.1f", displayWeightChange), unit, String(format: "%.1f", displayWeeklyAverage), unit)
            }
            
        case .threeMonths:
            let monthlyAverage = abs(weightChange) / 3.0
            let displayMonthlyAverage = getDisplayWeight(monthlyAverage, in: unit)
            if weightChange < 0 {
                return String(format: localizationManager.localizedString(for: LocalizationKeys.lostWeightQuarter), String(format: "%.1f", displayWeightChange), unit, String(format: "%.1f", displayMonthlyAverage), unit)
            } else {
                return String(format: localizationManager.localizedString(for: LocalizationKeys.gainedWeightQuarter), String(format: "%.1f", displayWeightChange), unit, String(format: "%.1f", displayMonthlyAverage), unit)
            }
            
        case .sixMonths:
            let monthlyAverage = abs(weightChange) / 6.0
            let displayMonthlyAverage = getDisplayWeight(monthlyAverage, in: unit)
            if weightChange < 0 {
                return String(format: localizationManager.localizedString(for: LocalizationKeys.lostWeightQuarter), String(format: "%.1f", displayWeightChange), unit, String(format: "%.1f", displayMonthlyAverage), unit)
            } else {
                return String(format: localizationManager.localizedString(for: LocalizationKeys.gainedWeightQuarter), String(format: "%.1f", displayWeightChange), unit, String(format: "%.1f", displayMonthlyAverage), unit)
            }
            
        case .year:
            let monthlyAverage = abs(weightChange) / 12.0
            let displayMonthlyAverage = getDisplayWeight(monthlyAverage, in: unit)
            if weightChange < 0 {
                return String(format: localizationManager.localizedString(for: LocalizationKeys.lostWeightYear), String(format: "%.1f", displayWeightChange), unit, String(format: "%.1f", displayMonthlyAverage), unit)
            } else {
                return String(format: localizationManager.localizedString(for: LocalizationKeys.gainedWeightYear), String(format: "%.1f", displayWeightChange), unit, String(format: "%.1f", displayMonthlyAverage), unit)
            }
        }
    }
    
    func getQuickActions() -> [QuickAction] {
        var actions: [QuickAction] = []
        
        // Acción para importar datos de Salud (si está disponible)
        actions.append(QuickAction(
            id: "import-health",
            title: localizationManager.localizedString(for: LocalizationKeys.importHealth),
            subtitle: localizationManager.localizedString(for: LocalizationKeys.importHealthSubtitle),
            icon: "heart.fill",
            action: .importHealth
        ))
        
        // Acción para exportar datos
        actions.append(QuickAction(
            id: "export-csv",
            title: localizationManager.localizedString(for: LocalizationKeys.exportCSV),
            subtitle: localizationManager.localizedString(for: LocalizationKeys.exportCSVSubtitle),
            icon: "square.and.arrow.up",
            action: .exportCSV
        ))
        
        // Acción para editar meta
        if activeGoal != nil {
            actions.append(QuickAction(
                id: "edit-goal",
                title: localizationManager.localizedString(for: LocalizationKeys.editGoalAction),
            subtitle: localizationManager.localizedString(for: LocalizationKeys.editGoalSubtitle),
                icon: "target",
                action: .editGoal
            ))
        } else {
            actions.append(QuickAction(
                id: "create-goal",
                title: localizationManager.localizedString(for: LocalizationKeys.createGoalAction),
            subtitle: localizationManager.localizedString(for: LocalizationKeys.createGoalSubtitle),
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
