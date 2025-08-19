//
//  ThemeManager.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import SwiftUI
import Combine

// MARK: - Theme Manager

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    // Siempre usamos tema oscuro
    @Published var currentTheme: AppTheme = .dark
    @Published var isDarkMode: Bool = true
    
    init() {
        // No necesitamos cargar tema, siempre es oscuro
    }
    
    // MARK: - Theme Management
    
    // Mantenemos este método para compatibilidad con código existente
    // pero siempre forzamos el tema oscuro
    func setTheme(_ theme: AppTheme) {
        // Ignoramos el tema proporcionado y siempre usamos oscuro
        currentTheme = .dark
        isDarkMode = true
        
        // Animación suave al cambiar tema (por compatibilidad)
        withAnimation(.easeInOut(duration: 0.3)) {
            objectWillChange.send()
        }
    }
    
    // MARK: - Color Scheme
    
    // Siempre devolvemos el esquema oscuro
    var colorScheme: ColorScheme? {
        return .dark
    }
}

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    // Mantenemos todos los casos para compatibilidad con código existente
    case light, dark, system
    
    var id: String { rawValue }
    
    // Siempre mostramos "Oscuro" independientemente del caso
    var displayName: String {
        return "Oscuro"
    }
    
    // Siempre usamos el icono de luna
    var icon: String {
        return "moon.fill"
    }
    
    // Alias para no romper código que use `.iconName`
    var iconName: String { icon }
    
    /// Mapea a `ColorScheme` para `preferredColorScheme`
    var colorScheme: ColorScheme? {
        // Siempre devolvemos dark independientemente del caso
        return .dark
    }
}

// MARK: - Theme Colors

// Estructura ThemeColors eliminada - ahora se usan valores hexadecimales directos

// MARK: - Theme-Aware Modifiers

struct ThemeAwareBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
            }
    }
}

struct ThemeAwareCardBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let cornerRadius: CGFloat
    let hasGlow: Bool
    
    init(cornerRadius: CGFloat = 20, hasGlow: Bool = true) {
        self.cornerRadius = cornerRadius
        self.hasGlow = hasGlow
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Fondo principal con gradiente
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color(.systemGray6))
                    
                    // Efecto glassmorphism
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color(.systemGray5).opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    
                    // Efecto de brillo sutil
                    if hasGlow {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [Color.teal.opacity(0.1), Color.green.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .opacity(0.6)
                    }
                }
            )
            .shadow(
                color: Color.purple.opacity(0.4),
                radius: 12,
                x: 0,
                y: 6
            )
            .shadow(
                color: Color.purple.opacity(0.1),
                radius: 2,
                x: 0,
                y: 1
            )
    }
}

struct ThemeAwareGlassmorphism: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let cornerRadius: CGFloat
    let intensity: Double
    let hasBlur: Bool
    
    init(cornerRadius: CGFloat = 20, intensity: Double = 1.0, hasBlur: Bool = true) {
        self.cornerRadius = cornerRadius
        self.intensity = intensity
        self.hasBlur = hasBlur
    }
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [Color(.systemGray6).opacity(0.6), Color(.systemGray5).opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ).opacity(intensity)
                    )
                    .background {
                        if hasBlur {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(Color(.systemGray6).opacity(0.3))
                                .blur(radius: 10 * 0.3)
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                Color(.systemGray5).opacity(intensity),
                                lineWidth: 1.5
                            )
                    }
                    .shadow(
                        color: Color.black.opacity(0.5 * intensity),
                        radius: 12,
                        x: 0,
                        y: 8
                    )
                    .shadow(
                        color: Color.teal.opacity(0.3 * intensity),
                        radius: 20,
                        x: 0,
                        y: 0
                    )
            }
    }
}

// MARK: - Modern Button Style

struct ModernButtonStyle: ViewModifier {
    let isPressed: Bool
    let cornerRadius: CGFloat
    
    init(isPressed: Bool = false, cornerRadius: CGFloat = 16) {
        self.isPressed = isPressed
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [Color.teal, Color.green],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(isPressed ? 0.1 : 0.2),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
            .shadow(
                color: Color.teal.opacity(0.4),
                radius: isPressed ? 4 : 8,
                x: 0,
                y: isPressed ? 2 : 4
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Text Gradient Style

struct TextGradientStyle: ViewModifier {
    let gradient: LinearGradient
    
    init(gradient: LinearGradient = LinearGradient(
        colors: [Color.teal, Color.teal.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )) {
        self.gradient = gradient
    }
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle(gradient)
    }
}

// MARK: - View Extensions

extension View {
    func themeAwareBackground() -> some View {
        self.modifier(ThemeAwareBackground())
    }
    
    func themeAwareCardBackground(cornerRadius: CGFloat = 20, hasGlow: Bool = true) -> some View {
        self.modifier(ThemeAwareCardBackground(cornerRadius: cornerRadius, hasGlow: hasGlow))
    }
    
    func themeAwareGlassmorphism(cornerRadius: CGFloat = 20, intensity: Double = 1.0, hasBlur: Bool = true) -> some View {
        modifier(ThemeAwareGlassmorphism(cornerRadius: cornerRadius, intensity: intensity, hasBlur: hasBlur))
    }
    
    func modernButtonStyle(isPressed: Bool = false, cornerRadius: CGFloat = 16) -> some View {
        self.modifier(ModernButtonStyle(isPressed: isPressed, cornerRadius: cornerRadius))
    }
    
    func textGradient(_ gradient: LinearGradient = LinearGradient(
        colors: [Color.teal, Color.teal.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )) -> some View {
        self.modifier(TextGradientStyle(gradient: gradient))
    }
    
    func primaryGradientText() -> some View {
        self.foregroundStyle(Color.primary)
    }
    
    func accentGradientText() -> some View {
        self.foregroundStyle(Color.teal)
    }
    
    // Efecto de hover moderno
    func modernHoverEffect() -> some View {
        self
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.2), value: false)
    }
    
    // Sombra moderna minimalista
    func modernShadow(color: Color = Color.teal, radius: CGFloat = 6, x: CGFloat = 0, y: CGFloat = 2) -> some View {
        self
            .shadow(color: Color(.systemGray4).opacity(0.3), radius: radius, x: x, y: y)
    }
}
