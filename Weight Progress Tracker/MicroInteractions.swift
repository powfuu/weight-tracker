//
//  MicroInteractions.swift
//  Weight Progress Tracker
//
//  Created by Assistant on 17/1/25.
//

import SwiftUI

// MARK: - Interactive Button with Haptics
struct InteractiveButton<Content: View>: View {
    let action: () -> Void
    let hapticStyle: Int // Simplified haptic style
    let content: Content
    
    @State private var isPressed = false
    
    init(
        hapticStyle: Int = 1, // 0: light, 1: medium, 2: heavy
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.hapticStyle = hapticStyle
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: {
            // Simple haptic feedback without UIKit dependency
            // Note: For full haptic support, UIKit import would be needed
            
            // Execute action
            action()
        }) {
            content
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(AnimationConstants.quickSpring, value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Pill Button
struct PillButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let backgroundColor: Color
    let foregroundColor: Color
    
    @State private var isPressed = false
    
    init(
        title: String,
        icon: String? = nil,
        backgroundColor: Color = .teal,
        foregroundColor: Color = .white,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.action = action
    }
    
    var body: some View {
        InteractiveButton(hapticStyle: 0, action: action) { // 0 = light
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(backgroundColor)
            )
        }
    }
}

// MARK: - Staggered Animation View Modifier
struct StaggeredAnimation: ViewModifier {
    let delay: Double
    let duration: Double
    let offset: CGFloat
    
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : offset)
            .animation(
                .easeOut(duration: duration).delay(delay),
                value: isVisible
            )
            .onAppear {
                isVisible = true
            }
    }
}

extension View {
    func staggeredAnimation(
        delay: Double = 0,
        duration: Double = 0.6,
        offset: CGFloat = 20
    ) -> some View {
        modifier(StaggeredAnimation(delay: delay, duration: duration, offset: offset))
    }
}

// MARK: - Breathing Animation
struct BreathingAnimation: ViewModifier {
    let minScale: CGFloat
    let maxScale: CGFloat
    let duration: Double
    
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? maxScale : minScale)
            .animation(
                .easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

extension View {
    func breathingAnimation(
        minScale: CGFloat = 0.98,
        maxScale: CGFloat = 1.02,
        duration: Double = 2.0
    ) -> some View {
        modifier(BreathingAnimation(minScale: minScale, maxScale: maxScale, duration: duration))
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 30) {
        // Interactive Button Example
        InteractiveButton(hapticStyle: 1, action: { // 1 = medium
            print("Button tapped!")
        }) {
            Text("Tap me!")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.teal)
                .cornerRadius(12)
        }
        
        // Pill Button Example
        PillButton(
            title: "Ver detalles",
            icon: "arrow.right",
            backgroundColor: .teal.opacity(0.2),
            foregroundColor: .teal
        ) {
            print("Pill button tapped!")
        }
        
        // Staggered Animation Example
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.teal.opacity(0.3))
                    .frame(height: 50)
                    .staggeredAnimation(delay: Double(index) * 0.1)
            }
        }
        
        // Breathing Animation Example
        Circle()
            .fill(Color.teal)
            .frame(width: 60, height: 60)
            .breathingAnimation()
    }
    .padding()
}