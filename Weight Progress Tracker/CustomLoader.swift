//
//  CustomLoader.swift
//  Weight Progress Tracker
//
//  Created by Assistant on 17/1/25.
//

import SwiftUI

struct CustomLoader: View {
    @State private var isAnimating = false
    @State private var scaleEffect: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 24) {
            // Ícono de balanza animado
            ZStack {
                // Círculo de fondo
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.teal.opacity(0.2), .cyan.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(scaleEffect)
                
                // Ícono de balanza
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.teal, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(rotationAngle))
                
                // Anillo de progreso
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [.teal, .cyan, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
            }
            
            // Texto de carga
            VStack(spacing: 8) {
                Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.loadingProgress))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.preparingData))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .opacity(isAnimating ? 1.0 : 0.6)
            }
            
            // Puntos de carga
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(.teal)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Animación principal del anillo
        withAnimation(
            .linear(duration: 2.0)
            .repeatForever(autoreverses: false)
        ) {
            isAnimating = true
        }
        
        // Animación de escala del fondo
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            scaleEffect = 1.1
        }
        
        // Animación sutil de rotación del ícono
        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
        ) {
            rotationAngle = 5
        }
    }
}

// Vista de loader para pantalla completa
struct FullScreenLoader: View {
    var body: some View {
        ZStack {
            // Fondo con blur
            Color.black
                .ignoresSafeArea()
            
            // Loader centrado
            CustomLoader()
        }
    }
}

// Vista de loader compacto para uso en tarjetas
struct CompactLoader: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Ícono animado pequeño
            ZStack {
                Circle()
                    .fill(.teal.opacity(0.2))
                    .frame(width: 24, height: 24)
                
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.teal)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(.teal, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 28, height: 28)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
            }
            
            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.loadingSimple))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .onAppear {
            withAnimation(
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        CustomLoader()
        
        Divider()
        
        CompactLoader()
    }
    .padding()
}