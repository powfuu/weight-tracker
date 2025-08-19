//
//  AnimationHelpers.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Animation Constants

struct AnimationConstants {
    // Animaciones de resorte optimizadas para una respuesta más fluida
    static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.75, blendDuration: 0)
    static let smoothSpring = Animation.spring(response: 0.45, dampingFraction: 0.8, blendDuration: 0)
    static let gentleSpring = Animation.spring(response: 0.6, dampingFraction: 0.9, blendDuration: 0)
    
    // Animaciones suaves para transiciones
    static let quickEase = Animation.easeInOut(duration: 0.2)
    static let smoothEase = Animation.easeInOut(duration: 0.35)
    static let gentleEase = Animation.easeInOut(duration: 0.5)
    
    // Animaciones con más personalidad
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)
    static let elastic = Animation.spring(response: 0.55, dampingFraction: 0.45, blendDuration: 0)
    
    // Nuevas animaciones modernas
    static let ultraSmooth = Animation.spring(response: 0.4, dampingFraction: 0.85, blendDuration: 0)
    static let snappy = Animation.spring(response: 0.25, dampingFraction: 0.8, blendDuration: 0)
    static let fluid = Animation.timingCurve(0.2, 0, 0.38, 0.9, duration: 0.4)
    static let silky = Animation.timingCurve(0.25, 0.1, 0.25, 1, duration: 0.5)
    
    // MARK: - Colors
     static let tealGradient = [Color.teal, Color.teal.opacity(0.8), Color.teal.opacity(0.6)]
     static let tealShadow = Color.teal.opacity(0.3)
     static let blueGradient = [Color.blue, Color.blue.opacity(0.8), Color.blue.opacity(0.6)]
     static let blueShadow = Color.blue.opacity(0.3)
}

// MARK: - Custom Transitions

struct SlideTransition {
    static let fromLeading = AnyTransition.asymmetric(
        insertion: .move(edge: .leading)
            .combined(with: .opacity)
            .combined(with: .scale(scale: 0.96))
            .animation(AnimationConstants.ultraSmooth),
        removal: .move(edge: .trailing)
            .combined(with: .opacity)
            .combined(with: .scale(scale: 0.96))
            .animation(AnimationConstants.snappy)
    )
    
    static let fromTrailing = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing)
            .combined(with: .opacity)
            .combined(with: .scale(scale: 0.96))
            .animation(AnimationConstants.ultraSmooth),
        removal: .move(edge: .leading)
            .combined(with: .opacity)
            .combined(with: .scale(scale: 0.96))
            .animation(AnimationConstants.snappy)
    )
    
    static let fromBottom = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom)
            .combined(with: .opacity)
            .combined(with: .scale(scale: 0.98))
            .animation(AnimationConstants.fluid),
        removal: .move(edge: .bottom)
            .combined(with: .opacity)
            .combined(with: .scale(scale: 0.98))
            .animation(AnimationConstants.silky)
    )
    
    static let fromTop = AnyTransition.asymmetric(
        insertion: .move(edge: .top)
            .combined(with: .opacity)
            .combined(with: .scale(scale: 0.98))
            .animation(AnimationConstants.fluid),
        removal: .move(edge: .top)
            .combined(with: .opacity)
            .combined(with: .scale(scale: 0.98))
            .animation(AnimationConstants.silky)
    )
}

struct ScaleTransition {
    static let gentle = AnyTransition.scale(scale: 0.88)
        .combined(with: .opacity)
        .animation(AnimationConstants.ultraSmooth)
    
    static let bouncy = AnyTransition.scale(scale: 0.75)
        .combined(with: .opacity)
        .animation(AnimationConstants.elastic)
    
    static let subtle = AnyTransition.scale(scale: 0.98)
        .combined(with: .opacity)
        .animation(AnimationConstants.silky)
    
    static let modern = AnyTransition.scale(scale: 0.92)
        .combined(with: .opacity)
        .animation(AnimationConstants.fluid)
}

// MARK: - Animated Modifiers

struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    let intensity: Double
    let duration: Double
    
    init(intensity: Double = 0.1, duration: Double = 1.0) {
        self.intensity = intensity
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1 + intensity : 1)
            .shadow(color: AnimationConstants.tealShadow, radius: isPulsing ? 8 : 4)
            .overlay(
                LinearGradient(colors: AnimationConstants.tealGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .opacity(isPulsing ? 0.2 : 0.05)
                    .blendMode(.overlay)
            )
            .animation(
                Animation.easeInOut(duration: duration)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    let duration: Double
    let angle: Double
    
    init(duration: Double = 1.5, angle: Double = 70) {
        self.duration = duration
        self.angle = angle
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.3),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(angle))
                    .offset(x: phase)
                    .clipped()
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: duration)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 300
                }
            }
    }
}

struct FloatingEffect: ViewModifier {
    @State private var isFloating = false
    let intensity: Double
    let duration: Double
    
    init(intensity: Double = 5, duration: Double = 2.0) {
        self.intensity = intensity
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -intensity : intensity)
            .animation(
                Animation.easeInOut(duration: duration)
                    .repeatForever(autoreverses: true),
                value: isFloating
            )
            .onAppear {
                isFloating = true
            }
    }
}

struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius * 2, x: 0, y: 0)
    }
}

// MARK: - Interactive Animations

struct PressableScale: ViewModifier {
    @State private var isPressed = false
    let scale: Double
    
    init(scale: Double = 0.95) {
        self.scale = scale
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .shadow(color: AnimationConstants.tealShadow, radius: isPressed ? 4 : 8, x: 0, y: isPressed ? 2 : 4)
            .animation(AnimationConstants.quickSpring, value: isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(AnimationConstants.quickSpring) {
                    isPressed = pressing
                }
            }, perform: {})
    }
}

struct HoverEffect: ViewModifier {
    @State private var isHovered = false
    let scale: Double
    let shadowRadius: CGFloat
    
    init(scale: Double = 1.05, shadowRadius: CGFloat = 10) {
        self.scale = scale
        self.shadowRadius = shadowRadius
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .shadow(
                color: AnimationConstants.tealShadow,
                radius: isHovered ? shadowRadius : shadowRadius / 2,
                x: 0,
                y: isHovered ? 6 : 3
            )
            .animation(AnimationConstants.smoothSpring, value: isHovered)
            .onHover { hovering in
                withAnimation(AnimationConstants.smoothSpring) {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - Chart Animations

struct ChartAppearAnimation: ViewModifier {
    let delay: Double
    @State private var appeared = false
    @State private var glowOpacity = false
    
    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.8, anchor: .center)
            .overlay(
                LinearGradient(colors: AnimationConstants.tealGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .opacity(glowOpacity ? 0.3 : 0)
                    .blur(radius: 10)
            )
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: appeared)
            .onAppear {
                appeared = true
                withAnimation(.easeInOut(duration: 1.2).delay(delay + 0.3).repeatForever(autoreverses: true)) {
                    glowOpacity = true
                }
            }
    }
}

struct CounterAnimation: ViewModifier {
    let value: Double
    let formatter: NumberFormatter
    @State private var animatedValue: Double = 0
    
    init(value: Double, formatter: NumberFormatter = NumberFormatter()) {
        self.value = value
        self.formatter = formatter
    }
    
    func body(content: Content) -> some View {
        Text(formatter.string(from: NSNumber(value: animatedValue)) ?? "0")
            .onAppear {
                withAnimation(AnimationConstants.smoothEase) {
                    animatedValue = value
                }
            }
            .onChange(of: value) { _ in
                withAnimation(AnimationConstants.smoothEase) {
                    animatedValue = value
                }
            }
    }
}

// MARK: - Loading Animations

struct LoadingDots: View {
    @State private var animating = false
    let color: Color
    let size: CGFloat
    
    init(color: Color = .teal, size: CGFloat = 8) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: size / 2) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .scaleEffect(animating ? 1.3 : 0.7)
                    .shadow(color: color.opacity(0.4), radius: 4)
                    .animation(
                        Animation.spring(response: 0.6, dampingFraction: 0.7)
                            .repeatForever()
                            .delay(Double(index) * 0.15),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

struct LoadingSpinner: View {
    @State private var isRotating = false
    let color: Color
    let size: CGFloat
    
    init(color: Color = .teal, size: CGFloat = 20) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.75)
            .stroke(
                AngularGradient(
                    colors: [color.opacity(0.1), color.opacity(0.3), color, color.opacity(0.8)],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )
            .frame(width: size, height: size)
            .shadow(color: color.opacity(0.3), radius: 6)
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(
                Animation.linear(duration: 0.8)
                    .repeatForever(autoreverses: false),
                value: isRotating
            )
            .onAppear {
                isRotating = true
            }
    }
}

// MARK: - Success Animations

struct SuccessCheckmark: View {
    @State private var animationProgress: Double = 0
    let color: Color
    let size: CGFloat
    
    init(color: Color = .teal, size: CGFloat = 24) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.2), color.opacity(0.05)],
                        center: .center,
                        startRadius: 0,
                        endRadius: size
                    )
                )
                .frame(width: size * 1.8, height: size * 1.8)
                .scaleEffect(animationProgress)
                .shadow(color: color.opacity(0.3), radius: 8)
            
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 2)
                .frame(width: size * 1.3, height: size * 1.3)
                .scaleEffect(animationProgress * 0.9)
            
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.8, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(animationProgress)
        }
        .onAppear {
            withAnimation(AnimationConstants.elastic.delay(0.1)) {
                animationProgress = 1
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    func pulseEffect(intensity: Double = 0.1, duration: Double = 1.0) -> some View {
        modifier(PulseEffect(intensity: intensity, duration: duration))
    }
    
    func shimmerEffect(duration: Double = 1.5, angle: Double = 70) -> some View {
        modifier(ShimmerEffect(duration: duration, angle: angle))
    }
    
    func floatingEffect(intensity: Double = 5, duration: Double = 2.0) -> some View {
        modifier(FloatingEffect(intensity: intensity, duration: duration))
    }
    
    func glowEffect(color: Color = .teal, radius: CGFloat = 6) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }
    
    func pressableScale(scale: Double = 0.95) -> some View {
        modifier(PressableScale(scale: scale))
    }
    
    func hoverEffect(scale: Double = 1.05, shadowRadius: CGFloat = 10) -> some View {
        modifier(HoverEffect(scale: scale, shadowRadius: shadowRadius))
    }
    
    func chartAppearAnimation(delay: Double = 0) -> some View {
        modifier(ChartAppearAnimation(delay: delay))
    }
    
    func animatedCounter(value: Double, formatter: NumberFormatter = NumberFormatter()) -> some View {
        modifier(CounterAnimation(value: value, formatter: formatter))
    }
    
    // Transiciones personalizadas
    func slideFromLeading() -> some View {
        transition(SlideTransition.fromLeading)
    }
    
    func slideFromTrailing() -> some View {
        transition(SlideTransition.fromTrailing)
    }
    
    func slideFromBottom() -> some View {
        transition(SlideTransition.fromBottom)
    }
    
    func slideFromTop() -> some View {
        transition(SlideTransition.fromTop)
    }
    
    func scaleTransition(_ type: ScaleTransitionType = .gentle) -> some View {
        switch type {
        case .gentle:
            return transition(ScaleTransition.gentle)
        case .bouncy:
            return transition(ScaleTransition.bouncy)
        case .subtle:
            return transition(ScaleTransition.subtle)
        }
    }
    
    // Animación de aparición con retraso
    func appearWithDelay(_ delay: Double, animation: Animation = AnimationConstants.smoothEase) -> some View {
        modifier(AppearWithDelay(delay: delay, animation: animation))
    }
    
    // Animación de entrada desde escala
    func scaleInAnimation(delay: Double = 0) -> some View {
        modifier(ScaleInAnimation(delay: delay))
    }
}

// MARK: - Supporting Types

enum ScaleTransitionType {
    case gentle, bouncy, subtle
}

struct AppearWithDelay: ViewModifier {
    @State private var isVisible = false
    let delay: Double
    let animation: Animation
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(animation.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

struct ScaleInAnimation: ViewModifier {
    @State private var scale: Double = 0
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(AnimationConstants.bouncy.delay(delay)) {
                    scale = 1
                }
            }
    }
}

// MARK: - Haptic Feedback

struct HapticFeedback {
    static func light() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
    }
    
    static func medium() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
    }
    
    static func heavy() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        #endif
    }
    
    static func success() {
        #if canImport(UIKit)
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        #endif
    }
    
    static func warning() {
        #if canImport(UIKit)
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
        #endif
    }
    
    static func error() {
        #if canImport(UIKit)
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
        #endif
    }
}