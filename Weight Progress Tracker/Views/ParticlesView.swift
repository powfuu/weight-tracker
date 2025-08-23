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
    @State private var animationTime: Double = 0
    @State private var isAnimating: Bool = false
    
    var particleCount: Int = 20
    
    // Gradientes modernos con tonos negros/grises oscuros
    private let gradients: [LinearGradient] = [
        LinearGradient(
            colors: [.teal.opacity(0.8), .blue.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        LinearGradient(
            colors: [.blue.opacity(0.9), .teal.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        LinearGradient(
            colors: [.teal.opacity(0.7), .blue.opacity(0.4)],
            startPoint: .top,
            endPoint: .bottom
        ),
        LinearGradient(
            colors: [Color(.darkGray).opacity(0.6), .black.opacity(0.5)],
            startPoint: .leading,
            endPoint: .trailing
        ),
        LinearGradient(
            colors: [Color(.systemBlue).opacity(0.8), .teal.opacity(0.3)],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    ]
    
    init(particleCount: Int = 20) {
        self.particleCount = particleCount
    }
    
    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                let currentTime = timeline.date.timeIntervalSinceReferenceDate
                
                ZStack {
                    ForEach(particles.indices, id: \.self) { index in
                        let particle = animatedParticle(at: index, time: currentTime, in: geometry.size)
                        
                        particleShape(for: particle)
                            .position(particle.position)
                            .opacity(particle.opacity * (0.8 + 0.3 * sin(particle.pulsePhase + currentTime * 2)))
                            .rotationEffect(.degrees(particle.rotation + currentTime * particle.rotationSpeed * 10))
                            .scaleEffect(0.8 + 0.3 * sin(particle.pulsePhase + currentTime * 1.5))
                    }
                    
                    // Líneas conectoras sutiles
                    ForEach(0..<min(particles.count, 8), id: \.self) { index in
                        if index < particles.count - 1 {
                            let particle1 = animatedParticle(at: index, time: currentTime, in: geometry.size)
                            let particle2 = animatedParticle(at: index + 1, time: currentTime, in: geometry.size)
                            
                            Path { path in
                                path.move(to: particle1.position)
                                path.addLine(to: particle2.position)
                            }
                            .stroke(
                                LinearGradient(
                                    colors: [.teal.opacity(0.15), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 0.5
                            )
                            .opacity(0.4 + 0.2 * sin(currentTime))
                        }
                    }
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
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
                .blur(radius: particle.size / 10)
                
        case .diamond:
            Diamond()
                .fill(particle.gradient)
                .frame(width: particle.size, height: particle.size)
                .blur(radius: particle.size / 12)
                
        case .line:
            Capsule()
                .fill(particle.gradient)
                .frame(width: particle.size * 2, height: particle.size / 3)
                .blur(radius: particle.size / 14)
                
        case .triangle:
            Triangle()
                .fill(particle.gradient)
                .frame(width: particle.size, height: particle.size)
                .blur(radius: particle.size / 12)
        }
    }
    
    private func generateParticles(in size: CGSize) {
        particles = []
        
        for i in 0..<particleCount {
            let randomX = CGFloat.random(in: 0...size.width)
            let randomY = CGFloat.random(in: 0...size.height)
            let randomSize = CGFloat.random(in: 8...24)
            let randomOpacity = Double.random(in: 0.3...0.7)
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
    
    private func animatedParticle(at index: Int, time: TimeInterval, in size: CGSize) -> ModernParticle {
        guard index < particles.count else { return particles[0] }
        
        var particle = particles[index]
        let timeOffset = time + Double(index) * 0.5
        
        // Movimiento fluido con ondas
        let waveX = sin(timeOffset * 0.5) * 30
        let waveY = cos(timeOffset * 0.3) * 20
        
        // Calcular nueva posición basada en el tiempo
        let baseY = particle.position.y - (particle.speed * CGFloat(time * 10))
        let cycleHeight = size.height + particle.size * 4
        let normalizedY = baseY.truncatingRemainder(dividingBy: cycleHeight)
        
        particle.position.y = normalizedY < 0 ? cycleHeight + normalizedY : normalizedY
        particle.position.x = particles[index].position.x + CGFloat(waveX * 0.02) + CGFloat(waveY * 0.01)
        
        // Mantener partículas dentro de los límites horizontales
        if particle.position.x < -particle.size {
            particle.position.x = size.width + particle.size
        } else if particle.position.x > size.width + particle.size {
            particle.position.x = -particle.size
        }
        
        return particle
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