//
//  UserSettings+Extensions.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 19/8/25.
//

import Foundation
import CoreData

extension UserSettings {
    
    // MARK: - Language Management
    
    /// Obtiene el idioma preferido del usuario, con fallback a inglés
    var currentLanguage: String {
        return preferredLanguage ?? "en-US"
    }
    
    /// Establece el idioma preferido del usuario
    func setLanguage(_ language: String) {
        preferredLanguage = language
        updatedAt = Date()
    }
    
    // MARK: - Onboarding Management
    
    /// Verifica si el usuario ha completado el onboarding
    func hasCompletedOnboarding() -> Bool {
        return onboardingCompleted
    }
    
    /// Marca el onboarding como completado
    func completeOnboarding() {
        onboardingCompleted = true
        updatedAt = Date()
    }
    
    /// Reinicia el estado de onboarding (útil para testing o reset)
    func resetOnboarding() {
        onboardingCompleted = false
        updatedAt = Date()
    }
    
    // MARK: - Convenience Methods
    
    /// Configura los valores iniciales para un nuevo usuario
    func setupInitialValues() {
        if id == nil {
            id = UUID()
        }
        if createdAt == nil {
            createdAt = Date()
        }
        updatedAt = Date()
        
        // Valores por defecto si no están establecidos
        if preferredUnit == nil {
            preferredUnit = "kg"
        }
        if selectedTheme == nil {
            selectedTheme = "system"
        }
        if preferredLanguage == nil {
            preferredLanguage = "en-US"
        }
    }
    
    /// Actualiza la marca de tiempo de modificación
    func touch() {
        updatedAt = Date()
    }
}

// MARK: - Static Methods

extension UserSettings {
    
    /// Obtiene o crea la configuración del usuario
    static func getOrCreate(in context: NSManagedObjectContext) -> UserSettings {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        
        do {
            let settings = try context.fetch(request)
            if let existingSettings = settings.first {
                return existingSettings
            }
        } catch {
            // Error obteniendo UserSettings
        }
        
        // Crear nueva configuración si no existe
        let newSettings = UserSettings(context: context)
        newSettings.setupInitialValues()
        
        return newSettings
    }
    
    /// Obtiene la configuración actual del usuario
    static func current(in context: NSManagedObjectContext) throws -> UserSettings {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        request.fetchLimit = 1
        
        let settings = try context.fetch(request)
        if let existingSettings = settings.first {
            return existingSettings
        }
        
        // Crear nueva configuración si no existe
        let newSettings = UserSettings(context: context)
        newSettings.setupInitialValues()
        try context.save()
        
        return newSettings
    }
}