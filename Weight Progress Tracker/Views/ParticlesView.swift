//
//  ParticlesView.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import SwiftUI

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var speed: CGFloat
    var color: Color
}

struct ParticlesView: View {
    @State private var particles: [Particle] = []
    @State private var timer: Timer? = nil
    
    var particleCount: Int = 25
    var colors: [Color] = [
        .teal,
        .green,
        .purple,
        .blue
    ]
    
    init(particleCount: Int = 30, colors: [Color]? = nil) {
        self.particleCount = particleCount
        if let customColors = colors, !customColors.isEmpty {
            self.colors = customColors
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .blur(radius: particle.size / 4)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
                startAnimation(in: geometry.size)
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
    private func generateParticles(in size: CGSize) {
        particles = []
        
        for _ in 0..<particleCount {
            let randomX = CGFloat.random(in: 0...size.width)
            let randomY = CGFloat.random(in: 0...size.height)
            let randomSize = CGFloat.random(in: 3...12)
            let randomOpacity = Double.random(in: 0.3...0.7)
            let randomSpeed = CGFloat.random(in: 0.2...1.0)
            let randomColor = colors.randomElement() ?? .teal
            
            let particle = Particle(
                position: CGPoint(x: randomX, y: randomY),
                size: randomSize,
                opacity: randomOpacity,
                speed: randomSpeed,
                color: randomColor
            )
            
            particles.append(particle)
        }
    }
    
    private func startAnimation(in size: CGSize) {
        // Optimización: Reducir frecuencia de actualización de 50fps a 30fps
        timer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { _ in
            // Optimización: Usar indices seguros y evitar cálculos innecesarios
            let currentTime = Date().timeIntervalSince1970
            
            for i in particles.indices {
                var particle = particles[i]
                
                // Optimización: Calcular xOffset una sola vez
                let xOffset = sin(CGFloat(currentTime) * 2 + CGFloat(i)) * 0.3
                particle.position.y -= particle.speed
                particle.position.x += xOffset
                
                // Si la partícula sale de la pantalla, reiniciarla en la parte inferior
                if particle.position.y < -particle.size {
                    particle.position.y = size.height + particle.size
                    particle.position.x = CGFloat.random(in: 0...size.width)
                }
                
                particles[i] = particle
            }
        }
    }
}

#Preview {
    ZStack {
        Color.primary.opacity(0.05)
            .ignoresSafeArea()
        
        ParticlesView()
    }
}