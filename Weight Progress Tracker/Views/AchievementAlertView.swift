//
//  AchievementAlertView.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import SwiftUI

struct AchievementAlertView: View {
    let achievement: Achievement
    let onDismiss: () -> Void
    
    @State private var animationProgress: Double = 0
    @State private var confettiAnimation = false
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissAlert()
                }
            
            // Achievement card
            VStack(spacing: 24) {
                // Confetti effect
                confettiView
                
                // Achievement content
                achievementContent
                
                // Action button
                actionButton
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 40)
            .scaleEffect(animationProgress)
            .opacity(animationProgress)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                animationProgress = 1.0
            }
            
            // Trigger confetti animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                confettiAnimation = true
            }
        }
    }
    
    private var confettiView: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                ConfettiParticle(
                    color: [achievement.type.color, .teal].randomElement() ?? .blue,
                    delay: Double(index) * 0.05,
                    isAnimating: confettiAnimation
                )
            }
        }
        .frame(height: 80)
    }
    
    private var achievementContent: some View {
        VStack(spacing: 20) {
            // Icon with glow effect
            ZStack {
                Circle()
                    .fill(achievement.type.color.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .blur(radius: 10)
                
                Circle()
                    .fill(achievement.type.color.opacity(0.3))
                    .frame(width: 80, height: 80)
                
                Image(systemName: achievement.type.icon)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(achievement.type.color)
            }

            
            // Text content
            VStack(spacing: 12) {
                Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.achievementUnlocked))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(achievement.type.color)
                
                Text(achievement.type.localizedTitle)
                    .font(.title)
                    .fontWeight(.semibold)
                    .primaryGradientText()
                    .multilineTextAlignment(.center)
                
                Text(achievement.type.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }
    
    private var actionButton: some View {
        Button {
            dismissAlert()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.headline)
                
                Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.greatExclamation))
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [achievement.type.color, achievement.type.color.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .pressableScale()
    }
    
    private func dismissAlert() {
        HapticFeedback.light()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            animationProgress = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

struct ConfettiParticle: View {
    let color: Color
    let delay: Double
    let isAnimating: Bool
    
    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 8, height: 8)
            .offset(x: xOffset, y: yOffset)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onChange(of: isAnimating) { _ in
                if isAnimating {
                    startAnimation()
                }
            }
    }
    
    private func startAnimation() {
        let randomX = CGFloat.random(in: -100...100)
        let randomRotation = Double.random(in: 0...360)
        
        withAnimation(
            .easeOut(duration: 1.0)
            .delay(delay)
        ) {
            yOffset = 100
            xOffset = randomX
            rotation = randomRotation
            opacity = 0
        }
    }
}

// MARK: - Achievement Alert Modifier
struct AchievementAlertModifier: ViewModifier {
    @ObservedObject var gamificationManager: GamificationManager
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if gamificationManager.showingAchievementAlert,
                       let latestAchievement = gamificationManager.newAchievements.first {
                        AchievementAlertView(achievement: latestAchievement) {
                            gamificationManager.markAchievementsAsViewed()
                        }
                        .zIndex(1000)
                    }
                }
            )
    }
}

extension View {
    func achievementAlert(gamificationManager: GamificationManager) -> some View {
        modifier(AchievementAlertModifier(gamificationManager: gamificationManager))
    }
}