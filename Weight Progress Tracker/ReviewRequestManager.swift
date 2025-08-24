//
//  ReviewRequestManager.swift
//  Weight Progress Tracker
//
//  Created by ASO Optimization
//

import Foundation
import StoreKit
import Combine
#if canImport(UIKit)

#endif

/// Gestor para solicitar reseñas de la app en momentos estratégicos
/// Implementa la estrategia de ASO para maximizar las reseñas positivas
class ReviewRequestManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = ReviewRequestManager()
    
    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    // Claves para UserDefaults
    private enum Keys {
        static let firstLaunchDate = "first_launch_date"
        static let totalWeightEntries = "total_weight_entries"
        static let goalsCompleted = "goals_completed"
        static let lastReviewRequestDate = "last_review_request_date"
        static let reviewRequestCount = "review_request_count"
        static let hasUserRatedApp = "has_user_rated_app"
    }
    
    // MARK: - Initialization
    private init() {
        setupFirstLaunchIfNeeded()
    }
    
    // MARK: - Public Methods
    
    /// Registra el primer lanzamiento de la app
    private func setupFirstLaunchIfNeeded() {
        if userDefaults.object(forKey: Keys.firstLaunchDate) == nil {
            userDefaults.set(Date(), forKey: Keys.firstLaunchDate)
        }
    }
    
    /// Incrementa el contador de entradas de peso
    func incrementWeightEntries() {
        let currentCount = userDefaults.integer(forKey: Keys.totalWeightEntries)
        userDefaults.set(currentCount + 1, forKey: Keys.totalWeightEntries)
        
        // Verificar si es momento de solicitar reseña
        checkForReviewRequest()
    }
    
    /// Registra que se completó un objetivo
    func goalCompleted() {
        let currentCount = userDefaults.integer(forKey: Keys.goalsCompleted)
        userDefaults.set(currentCount + 1, forKey: Keys.goalsCompleted)
        
        // Verificar si es momento de solicitar reseña
        checkForReviewRequest()
    }
    
    /// Marca que el usuario ya calificó la app
    func userRatedApp() {
        userDefaults.set(true, forKey: Keys.hasUserRatedApp)
    }
    
    /// Verifica si es momento de solicitar una reseña
    private func checkForReviewRequest() {
        // No solicitar si el usuario ya calificó la app
        guard !userDefaults.bool(forKey: Keys.hasUserRatedApp) else { return }
        
        // No solicitar más de 3 veces por año
        let requestCount = userDefaults.integer(forKey: Keys.reviewRequestCount)
        guard requestCount < 3 else { return }
        
        // Verificar que hayan pasado al menos 30 días desde la última solicitud
        if let lastRequestDate = userDefaults.object(forKey: Keys.lastReviewRequestDate) as? Date {
            let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastRequestDate, to: Date()).day ?? 0
            guard daysSinceLastRequest >= 30 else { return }
        }
        
        // Verificar condiciones estratégicas
        if shouldRequestReview() {
            requestReview()
        }
    }
    
    /// Determina si se deben cumplir las condiciones para solicitar reseña
    private func shouldRequestReview() -> Bool {
        let weightEntries = userDefaults.integer(forKey: Keys.totalWeightEntries)
        let goalsCompleted = userDefaults.integer(forKey: Keys.goalsCompleted)
        
        guard let firstLaunchDate = userDefaults.object(forKey: Keys.firstLaunchDate) as? Date else {
            return false
        }
        
        let daysSinceFirstLaunch = Calendar.current.dateComponents([.day], from: firstLaunchDate, to: Date()).day ?? 0
        
        // Condición 1: Después de 7 días de uso Y al menos 5 registros
        if daysSinceFirstLaunch >= 7 && weightEntries >= 5 {
            return true
        }
        
        // Condición 2: Después de completar el primer objetivo
        if goalsCompleted >= 1 {
            return true
        }
        
        // Condición 3: Después de 30 registros de peso (usuario comprometido)
        if weightEntries >= 30 {
            return true
        }
        
        // Condición 4: Usuario muy activo (60+ registros)
        if weightEntries >= 60 {
            return true
        }
        
        return false
    }
    
    /// Solicita la reseña al usuario
    private func requestReview() {
        DispatchQueue.main.async {
            // Usar la API nativa de StoreKit
            #if canImport(UIKit)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
            #else
            // Para macOS, usar la API sin windowScene
            SKStoreReviewController.requestReview()
            #endif
            
            // Actualizar contadores
            self.userDefaults.set(Date(), forKey: Keys.lastReviewRequestDate)
            let currentCount = self.userDefaults.integer(forKey: Keys.reviewRequestCount)
            self.userDefaults.set(currentCount + 1, forKey: Keys.reviewRequestCount)
            
            // Log para debugging
            // Solicitud de reseña mostrada al usuario
        }
    }
    
    // MARK: - Analytics Methods
    
    /// Obtiene estadísticas de uso para análisis
    func getUsageStats() -> [String: Any] {
        let weightEntries = userDefaults.integer(forKey: Keys.totalWeightEntries)
        let goalsCompleted = userDefaults.integer(forKey: Keys.goalsCompleted)
        let requestCount = userDefaults.integer(forKey: Keys.reviewRequestCount)
        let hasRated = userDefaults.bool(forKey: Keys.hasUserRatedApp)
        
        var daysSinceFirstLaunch = 0
        if let firstLaunchDate = userDefaults.object(forKey: Keys.firstLaunchDate) as? Date {
            daysSinceFirstLaunch = Calendar.current.dateComponents([.day], from: firstLaunchDate, to: Date()).day ?? 0
        }
        
        return [
            "days_since_first_launch": daysSinceFirstLaunch,
            "total_weight_entries": weightEntries,
            "goals_completed": goalsCompleted,
            "review_request_count": requestCount,
            "has_user_rated": hasRated
        ]
    }
    
    func resetAllData() {
        userDefaults.removeObject(forKey: Keys.firstLaunchDate)
        userDefaults.removeObject(forKey: Keys.totalWeightEntries)
        userDefaults.removeObject(forKey: Keys.goalsCompleted)
        userDefaults.removeObject(forKey: Keys.lastReviewRequestDate)
        userDefaults.removeObject(forKey: Keys.reviewRequestCount)
        userDefaults.removeObject(forKey: Keys.hasUserRatedApp)
        
        setupFirstLaunchIfNeeded()
    }
}

// MARK: - Extensions

extension ReviewRequestManager {
    
    static func trackWeightEntry() {
        shared.incrementWeightEntries()
    }
    
    static func trackGoalCompletion() {
        shared.goalCompleted()
    }
    
    static func markUserRated() {
        shared.userRatedApp()
    }
}