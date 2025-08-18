//
//  CreateGoalView.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import SwiftUI
import CoreData

struct CreateGoalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var weightManager = WeightDataManager.shared
    
    @State private var targetWeight: String = ""
    @State private var targetDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var currentWeight: Double = 0
    @State private var goalType: GoalType = .lose
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var formAnimationProgress: Double = 0
    @State private var showingSuccess = false
    
    // Validación
    private var isValidWeight: Bool {
        guard let weight = Double(targetWeight), weight > 0, weight < 500 else {
            return false
        }
        return true
    }
    
    private var isValidDate: Bool {
        return targetDate > Date()
    }
    
    private var canCreateGoal: Bool {
        return isValidWeight && isValidDate && !targetWeight.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView
                        .appearWithDelay(0.1)
                    
                    // Tipo de objetivo
                    goalTypeSelector
                        .appearWithDelay(0.2)
                    
                    // Peso actual
                    currentWeightView
                        .appearWithDelay(0.3)
                    
                    // Peso objetivo
                    targetWeightInput
                        .appearWithDelay(0.4)
                    
                    // Fecha objetivo
                    targetDatePicker
                        .appearWithDelay(0.5)
                    
                    // Resumen del objetivo
                    goalSummaryView
                        .appearWithDelay(0.6)
                    
                    // Botón crear
                    createButton
                        .appearWithDelay(0.7)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Nuevo Objetivo")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        HapticFeedback.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    .pressableScale()
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { 
                    HapticFeedback.light()
                }
            } message: {
                Text(errorMessage)
            }
        }
        .overlay {
            if showingSuccess {
                SuccessCheckmark()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            loadCurrentWeight()
            withAnimation(AnimationConstants.smoothEase.delay(0.2)) {
                formAnimationProgress = 1.0
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 50))
                .textGradient()
                .modernShadow()
            
            Text("Establece una meta realista y alcanzable para mantenerte motivado")
                .font(.body)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    // MARK: - Goal Type Selector
    
    private var goalTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tipo de objetivo")
                .font(.headline)
                .primaryGradientText()

            HStack(spacing: 12) {
                ForEach(GoalType.allCases, id: \.self) { type in
                    GoalTypeCard(
                        type: type,
                        isSelected: goalType == type,
                        onTap: {
                            HapticFeedback.medium()
                            withAnimation(.spring) {
                                goalType = type
                            }
                        }
                    )
                }
            }
        }
    }
    
    private struct GoalTypeCard: View {
        let type: GoalType
        let isSelected: Bool
        let onTap: () -> Void

        var body: some View {
            let iconColor: Color = isSelected ? .white : type.color
            let textColor: Color = isSelected ? .white : Color.primary
            let bgColor: Color = isSelected ? type.color : Color.gray.opacity(0.1)
            let scale: CGFloat = isSelected ? 1.02 : 1.0
            let iconScale: CGFloat = isSelected ? 1.1 : 1.0

            return Button(action: onTap) {
                VStack(spacing: 8) {
                    Image(systemName: type.icon)
                        .font(.title2)
                        .foregroundColor(iconColor)
                        .scaleEffect(iconScale)
                        .animation(.spring, value: isSelected)

                    Text(type.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(textColor)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(bgColor)
                )
                .scaleEffect(scale) // evita scale dentro del background
            }
            .pressableScale(scale: 0.95)
            .glowEffect(color: isSelected ? type.color : .clear, radius: 4)
            .animation(.spring, value: isSelected)
        }
    }


    
    // MARK: - Current Weight View
    
    private var currentWeightView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Peso actual")
                .font(.headline)
                .primaryGradientText()
            
            HStack {
                Image(systemName: "scalemass.fill")
                    .accentGradientText()
                
                Text("\(weightManager.getDisplayWeight(currentWeight, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue), specifier: "%.1f") \(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue)")
                    .font(Font.title3)
                    .fontWeight(.medium)
                    .primaryGradientText()
                
                Spacer()
                
                Text("Último registro")
                    .font(.caption)
                    .foregroundColor(Color.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
        }
    }
    
    // MARK: - Target Weight Input
    
    private var targetWeightInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Peso objetivo")
                .font(.headline)
                .primaryGradientText()
            
            HStack {
                TextField("Ej: 70.5", text: $targetWeight)
                    .font(Font.title3)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: targetWeight) { oldValue, newValue in
                        HapticFeedback.light()
                    }
                
                Text(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue)
                    .font(Font.title3)
                    .foregroundColor(Color.secondary)
                    .pulseEffect(intensity: 0.1, duration: 2.0)
            }
            
            if !targetWeight.isEmpty && !isValidWeight {
                Text("Ingresa un peso válido (1-500 \(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))")
                    .font(.caption)
                    .foregroundColor(Color.red)
            }
            
            // Diferencia de peso
            if let weight = Double(targetWeight), weight > 0 {
                let difference = abs(weight - currentWeight)
                let direction = weight > currentWeight ? "ganar" : "perder"
                
                Text("Necesitas \(direction) \(weightManager.getDisplayWeight(difference, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue), specifier: "%.1f") \(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue)")
                    .font(.caption)
                    .foregroundColor(Color.blue)
                    .fontWeight(.medium)
                    .scaleInAnimation(delay: 0.1)
            }
        }
    }
    
    // MARK: - Target Date Picker
    
    private var targetDatePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fecha objetivo")
                .font(.headline)
                .primaryGradientText()
            
            DatePicker(
                "Selecciona la fecha",
                selection: $targetDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            
            if !isValidDate {
                Text("La fecha debe ser futura")
                    .font(.caption)
                    .foregroundColor(Color.red)
            }
            
            // Duración del objetivo
            let days = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
            if days > 0 {
                Text("Duración: \(days) días (\(days / 7) semanas)")
                    .font(.caption)
                    .foregroundColor(Color.blue)
                    .fontWeight(.medium)
            }
        }
    }
    
    // MARK: - Goal Summary View
    
    private var goalSummaryView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resumen del objetivo")
                .font(.headline)
                .primaryGradientText()
            
            VStack(spacing: 12) {
                SummaryRow(
                        icon: "scalemass.fill",
                        title: "Peso objetivo",
                        value: isValidWeight ? "\(targetWeight) \(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue)" : "--",
                        color: Color.blue
                    )
                
                SummaryRow(
                    icon: "calendar",
                    title: "Fecha límite",
                    value: targetDate.formatted(date: .abbreviated, time: .omitted),
                    color: Color.green
                )
                
                if let weight = Double(targetWeight), weight > 0 {
                    let difference = abs(weight - currentWeight)
                    let direction = weight > currentWeight ? "Ganar" : "Perder"
                    
                    SummaryRow(
                        icon: goalType.icon,
                        title: "Cambio necesario",
                        value: "\(direction) \(String(format: "%.1f", weightManager.getDisplayWeight(abs(difference), in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue)",
                        color: goalType.color
                    )
                }
                
                let days = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
                if days > 0 && isValidWeight, let weight = Double(targetWeight) {
                    let weeklyChange = abs(weight - currentWeight) / Double(days) * 7
                    
                    SummaryRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Cambio semanal",
                        value: "\(String(format: "%.2f", weightManager.getDisplayWeight(weeklyChange, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue)/semana",
                        color: Color.orange
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    // MARK: - Create Button
    
    private var createButton: some View {
        Button {
            HapticFeedback.heavy()
            createGoal()
        } label: {
            HStack {
                if isLoading {
                    LoadingSpinner(color: .white, size: 20)
                } else {
                    Image(systemName: "plus.circle.fill")
                }
                
                Text(isLoading ? "Creando..." : "Crear Objetivo")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: canCreateGoal ? [Color.blue, Color.orange] : [.gray, .gray],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .disabled(!canCreateGoal || isLoading)
        .pressableScale(scale: canCreateGoal ? 0.98 : 1.0)
        .glowEffect(color: canCreateGoal ? Color.blue : .clear, radius: 8)
        .opacity(canCreateGoal ? 1.0 : 0.6)
        .animation(AnimationConstants.smoothEase, value: canCreateGoal)
    }
    
    // MARK: - Helper Methods
    
    private func loadCurrentWeight() {
        Task {
            if let latestWeight = await weightManager.getLatestWeight() {
                await MainActor.run {
                    self.currentWeight = latestWeight.weight
                }
            }
        }
    }
    
    private func createGoal() {
        guard canCreateGoal, let weight = Double(targetWeight) else { 
            HapticFeedback.error()
            return 
        }
        
        isLoading = true
        
        Task {
            weightManager.createGoal(
                targetWeight: weight,
                targetDate: targetDate
            )
            
            await MainActor.run {
                isLoading = false
                HapticFeedback.success()
                withAnimation(.spring) {
                    showingSuccess = true
                }
                
                // Notificar que se creó un objetivo
                NotificationCenter.default.post(name: .goalUpdated, object: nil)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum GoalType: CaseIterable {
    case lose
    case gain
    case maintain
    
    var title: String {
        switch self {
        case .lose:
            return "Perder"
        case .gain:
            return "Ganar"
        case .maintain:
            return "Mantener"
        }
    }
    
    var icon: String {
        switch self {
        case .lose:
            return "arrow.down.circle.fill"
        case .gain:
            return "arrow.up.circle.fill"
        case .maintain:
            return "equal.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .lose:
            return Color.green
        case .gain:
            return Color.yellow
        case .maintain:
            return Color.blue
        }
    }
}

// MARK: - Supporting Views

struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.primary)
        }
    }
}
