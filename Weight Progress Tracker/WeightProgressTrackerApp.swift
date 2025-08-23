//
//  WeightProgressTrackerApp.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import SwiftUI
import CoreData

@main
struct WeightProgressTrackerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var hasCompletedOnboarding = false
    @State private var isLoading = true

    var body: some Scene {
        WindowGroup {
            Group {
                if isLoading {
                    // Pantalla de carga mientras verificamos el estado
                    LoadingView()
                } else if hasCompletedOnboarding {
                    MainView()
                        .slideFromTrailing()
                } else {
                    WelcomeView()
                        .slideFromLeading()
                        .onReceive(NotificationCenter.default.publisher(for: .onboardingCompleted)) { _ in
                            withAnimation(.easeInOut(duration: 0.5)) {
                                hasCompletedOnboarding = true
                            }
                        }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .dataDeleted)) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    hasCompletedOnboarding = false
                }
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .environmentObject(localizationManager)
            .environment(\.locale, localizationManager.currentLanguage.locale)
            .preferredColorScheme(.dark) // Forzamos el tema oscuro globalmente
            .background(
                Color.black
                    .ignoresSafeArea(.all)
            )
            .onAppear {
                checkOnboardingStatus()
                // El ReviewRequestManager se inicializa automáticamente como singleton
                // y configura el primer lanzamiento en su init
            }
        }
    }
    
    private func checkOnboardingStatus() {
        // Iniciando verificación del estado de onboarding
        
        // Usar Task para evitar bloqueos en el hilo principal
        Task {
            do {
                // Obteniendo UserSettings en background
                let context = persistenceController.container.newBackgroundContext()
                
                let userSettings = try await context.perform {
                    return try UserSettings.current(in: context)
                }
                
                let onboardingCompleted = userSettings.hasCompletedOnboarding()
                // Verificando si se completó el onboarding
                
                await MainActor.run {
                    self.hasCompletedOnboarding = onboardingCompleted
                    // Inicializar LocalizationManager con el idioma guardado del usuario
                    if onboardingCompleted {
                        self.localizationManager.initializeWithUserSettings()
                    } else {
                        self.localizationManager.initializeWithDefaultLanguage()
                    }
                    

                    
                    self.isLoading = false
                    // Onboarding verificado exitosamente
                }
            } catch {
                // Error verificando estado de onboarding
                await MainActor.run {
                    // En caso de error, asumimos que no se ha completado el onboarding
                    self.hasCompletedOnboarding = false
                    self.localizationManager.initializeWithDefaultLanguage()
                    

                    
                    self.isLoading = false
                    // Onboarding verificado con error
                }
            }
        }
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
    static let dataDeleted = Notification.Name("dataDeleted")
}
