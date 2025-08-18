//
//  ContentView.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var weightManager = WeightDataManager.shared
    // healthKitManager eliminado
    @StateObject private var notificationManager = NotificationManager.shared
    
    @State private var isInitialized = false
    @State private var showingOnboarding = false
    
    var body: some View {
        Group {
            if isInitialized {
                if shouldShowOnboarding {
                    OnboardingView(isPresented: $showingOnboarding)
                } else {
                    MainView()
                }
            } else {
                SplashView()
            }
        }
        .onAppear {
            initializeApp()
        }
    }
    
    private var shouldShowOnboarding: Bool {
        // Mostrar onboarding si no hay configuración de usuario
        return weightManager.userSettings == nil
    }
    
    private func initializeApp() {
        Task {
            // Solicitar autorizaciones de los managers
            // healthKitManager.requestAuthorization() eliminado
            await notificationManager.requestAuthorization()
            
            // Crear configuración por defecto si no existe
            if weightManager.userSettings == nil {
                weightManager.createDefaultUserSettings()
            }
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isInitialized = true
                }
            }
        }
    }
}

// MARK: - Splash View

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Fondo principal minimalista
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // Efecto de partículas sutiles para un aspecto más moderno
            ParticlesView()
                .opacity(0.4)
            
            VStack(spacing: 30) {
                // Icono principal minimalista
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 80, weight: .semibold))
                    .foregroundStyle(Color.teal)
                    .scaleEffect(scale)
                    .shadow(color: Color(.systemGray4).opacity(0.3), radius: 8, x: 0, y: 4)
                
                VStack(spacing: 12) {
                    Text("Weight Progress")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)
                    
                    Text("Tu compañero de seguimiento de peso")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(.systemGray6))
            )
            .modernShadow()
            .opacity(opacity)
            .scaleEffect(scale * 0.95 + 0.05)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

// MARK: - Onboarding View Placeholder

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // Fondo minimalista
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                VStack(spacing: 20) {
                    // Icono de bienvenida
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60, weight: .semibold))
                        .foregroundStyle(Color.teal)
                        .shadow(color: Color(.systemGray4).opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    Text("¡Bienvenido a Weight Progress!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Configura tu perfil para comenzar a seguir tu progreso de manera inteligente y personalizada")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 30)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }) {
                    HStack(spacing: 12) {
                        Text("Comenzar")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .modernButtonStyle(cornerRadius: 20)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 40)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateContent = true
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
