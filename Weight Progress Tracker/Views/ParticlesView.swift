//
//  ParticlesView.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import SwiftUI

enum ParticleType: CaseIterable {
    case circle, diamond, line, triangle
}

struct ModernParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var speed: CGFloat
    var rotation: Double
    var rotationSpeed: Double
    var type: ParticleType
    var gradient: LinearGradient
    var pulsePhase: Double
}

struct ParticlesView: View {
    @State private var particles: [ModernParticle] = []
    @State private var timer: Timer? = nil
    @State private var animationTime: Double = 0
    
    var particleCount: Int = 20
    
    // Gradientes modernos con colores de la app
    private let gradients: [LinearGradient] = [
        LinearGradient(
            colors: [.teal.opacity(0.8), .teal.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        LinearGradient(
            colors: [.cyan.opacity(0.6), .teal.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        ),
        LinearGradient(
            colors: [.blue.opacity(0.5), .teal.opacity(0.4)],
            startPoint: .leading,
            endPoint: .trailing
        ),
        LinearGradient(
            colors: [.mint.opacity(0.7), .teal.opacity(0.2)],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    ]
    
    init(particleCount: Int = 20) {
        self.particleCount = particleCount
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    particleShape(for: particle)
                        .position(particle.position)
                        .opacity(particle.opacity * (0.7 + 0.3 * sin(particle.pulsePhase + animationTime * 2)))
                        .rotationEffect(.degrees(particle.rotation))
                        .scaleEffect(0.8 + 0.2 * sin(particle.pulsePhase + animationTime * 1.5))
                }
                
                // Líneas conectoras sutiles
                ForEach(0..<min(particles.count, 8), id: \.self) { index in
                    if index < particles.count - 1 {
                        Path { path in
                            path.move(to: particles[index].position)
                            path.addLine(to: particles[index + 1].position)
                        }
                        .stroke(
                            LinearGradient(
                                colors: [.teal.opacity(0.1), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 0.5
                        )
                        .opacity(0.3 + 0.2 * sin(animationTime))
                    }
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
    
    @ViewBuilder
    private func particleShape(for particle: ModernParticle) -> some View {
        switch particle.type {
        case .circle:
            Circle()
                .fill(particle.gradient)
                .frame(width: particle.size, height: particle.size)
                .blur(radius: particle.size / 8)
                
        case .diamond:
            Diamond()
                .fill(particle.gradient)
                .frame(width: particle.size, height: particle.size)
                .blur(radius: particle.size / 10)
                
        case .line:
            Capsule()
                .fill(particle.gradient)
                .frame(width: particle.size * 2, height: particle.size / 3)
                .blur(radius: particle.size / 12)
                
        case .triangle:
            Triangle()
                .fill(particle.gradient)
                .frame(width: particle.size, height: particle.size)
                .blur(radius: particle.size / 10)
        }
    }
    
    private func generateParticles(in size: CGSize) {
        particles = []
        
        for i in 0..<particleCount {
            let randomX = CGFloat.random(in: 0...size.width)
            let randomY = CGFloat.random(in: 0...size.height)
            let randomSize = CGFloat.random(in: 6...20)
            let randomOpacity = Double.random(in: 0.2...0.6)
            let randomSpeed = CGFloat.random(in: 0.3...1.2)
            let randomRotation = Double.random(in: 0...360)
            let randomRotationSpeed = Double.random(in: -2...2)
            let randomType = ParticleType.allCases.randomElement() ?? .circle
            let randomGradient = gradients.randomElement() ?? gradients[0]
            let randomPulsePhase = Double.random(in: 0...Double.pi * 2)
            
            let particle = ModernParticle(
                position: CGPoint(x: randomX, y: randomY),
                size: randomSize,
                opacity: randomOpacity,
                speed: randomSpeed,
                rotation: randomRotation,
                rotationSpeed: randomRotationSpeed,
                type: randomType,
                gradient: randomGradient,
                pulsePhase: randomPulsePhase
            )
            
            particles.append(particle)
        }
    }
    
    private func startAnimation(in size: CGSize) {
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            animationTime += 0.016
            
            for i in particles.indices {
                var particle = particles[i]
                
                // Movimiento fluido con ondas
                let waveX = sin(animationTime * 0.5 + Double(i) * 0.5) * 30
                let waveY = cos(animationTime * 0.3 + Double(i) * 0.3) * 20
                
                particle.position.y -= particle.speed
                particle.position.x += CGFloat(waveX * 0.02)
                particle.position.x += CGFloat(waveY * 0.01)
                
                // Rotación suave
                particle.rotation += particle.rotationSpeed
                
                // Reiniciar partícula cuando sale de pantalla
                if particle.position.y < -particle.size * 2 {
                    particle.position.y = size.height + particle.size
                    particle.position.x = CGFloat.random(in: -50...size.width + 50)
                    particle.gradient = gradients.randomElement() ?? gradients[0]
                }
                
                // Mantener partículas dentro de los límites horizontales con rebote suave
                if particle.position.x < -particle.size {
                    particle.position.x = size.width + particle.size
                } else if particle.position.x > size.width + particle.size {
                    particle.position.x = -particle.size
                }
                
                particles[i] = particle
            }
        }
    }
}

// Formas geométricas personalizadas
struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.move(to: CGPoint(x: center.x, y: center.y - radius))
        path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
        path.addLine(to: CGPoint(x: center.x - radius, y: center.y))
        path.closeSubpath()
        
        return path
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.move(to: CGPoint(x: center.x, y: center.y - radius))
        path.addLine(to: CGPoint(x: center.x + radius * 0.866, y: center.y + radius * 0.5))
        path.addLine(to: CGPoint(x: center.x - radius * 0.866, y: center.y + radius * 0.5))
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        ParticlesView()
    }
}