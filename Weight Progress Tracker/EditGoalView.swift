//
//  EditGoalView.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import SwiftUI
import CoreData

struct EditGoalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var weightManager = WeightDataManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    let goal: WeightGoal
    
    @State private var targetWeight: String = ""
    @State private var targetDate = Date()
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingDeleteAlert = false
    @State private var editAnimationProgress: Double = 0
    @State private var showingSuccess = false
    @State private var targetWeightScale: CGFloat = 1.0
    @State private var targetDateScale: CGFloat = 1.0
    @State private var previousTargetWeight: String = ""
    @FocusState private var isTargetWeightFocused: Bool
    
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
    
    private var canSaveGoal: Bool {
        return isValidWeight && isValidDate && !targetWeight.isEmpty
    }
    
    private var hasChanges: Bool {
        guard let weight = Double(targetWeight) else { return false }
        return weight != goal.targetWeight || targetDate != goal.targetDate
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header con progreso actual
                    headerView
                        .appearWithDelay(0.1)
                    
                    // Progreso actual
                    currentProgressView
                        .appearWithDelay(0.2)
                    
                    // Peso objetivo
                    targetWeightInput
                        .appearWithDelay(0.3)
                    
                    // Fecha objetivo
                    targetDatePicker
                        .appearWithDelay(0.4)
                    
                    // Estadísticas del objetivo
                    goalStatsView
                        .appearWithDelay(0.5)
                    
                    // Botones de acción
                    actionButtons
                        .appearWithDelay(0.6)
                }
                .padding(.horizontal)
            }
            .navigationTitle(LocalizationManager.shared.localizedString(for: LocalizationKeys.editGoal))
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
            .alert(LocalizationKeys.error.localized, isPresented: $showingError) {
                Button(LocalizationKeys.ok.localized) { 
                    HapticFeedback.light()
                }
            } message: {
                Text(errorMessage)
            }
            .alert(LocalizationManager.shared.localizedString(for: LocalizationKeys.deleteGoal), isPresented: $showingDeleteAlert) {
                Button(LocalizationKeys.cancel.localized, role: .cancel) { 
                    HapticFeedback.light()
                }
                Button(LocalizationKeys.delete.localized, role: .destructive) {
                    HapticFeedback.heavy()
                    deleteGoal()
                }
            } message: {
                Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.goalDeleteConfirmation))
            }
        }
        .overlay {
            if showingSuccess {
                SuccessCheckmark()
                    .transition(.opacity)
            }
        }
        .onAppear {
            setupInitialValues()
            withAnimation(AnimationConstants.smoothEase.delay(0.2)) {
                editAnimationProgress = 1.0
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 40))
                .accentGradientText()
                .modernShadow()
            
            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.goalInProgress))
                .font(.title2)
                .fontWeight(.bold)
                .primaryGradientText()
                .modernShadow()
            
            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.goalAdjustDescription))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    // MARK: - Current Progress View
    
    private var currentProgressView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.currentProgress))
                .font(.headline)
                .primaryGradientText()
            
            VStack(spacing: 12) {
                // Progreso visual
                let progress = calculateProgress()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        let progressPercentage = Int(progress * 100 * editAnimationProgress)
                        let percentText = LocalizationManager.shared.localizedString(for: LocalizationKeys.percentCompleted)
                        
                        Text("\(progressPercentage)\(percentText)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .accentGradientText()
                            .animatedCounter(value: progress * editAnimationProgress, formatter: LocalizationManager.shared.localizedPercentFormatter)
                        
                        let sinceDateText = LocalizationManager.shared.localizedString(for: LocalizationKeys.sinceDate)
                        let formattedDate = goal.startDate?.formatted(date: .abbreviated, time: .omitted) ?? "—"
                        
                        Text("\(sinceDateText) \(formattedDate)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .environment(\.locale, LocalizationManager.shared.currentLanguage.locale)
                    }
                    
                    Spacer()
                    
                    CircularProgressView(progress: progress * editAnimationProgress)
                        .frame(width: 60, height: 60)
                        .pulseEffect(intensity: 0.05, duration: 3.0)
                }
                
                // Barra de progreso
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .teal))
                    .scaleEffect(y: 2)
                
                // Estadísticas de progreso
                HStack {
                    ProgressStatItem(
                        title: LocalizationManager.shared.localizedString(for: LocalizationKeys.initialWeight),
                        value: "\(String(format: "%.1f", weightManager.getDisplayWeight(goal.startWeight, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.getLocalizedUnitSymbol())",
                        color: .gray
                    )
                    
                    Spacer()
                    
                    ProgressStatItem(
                        title: LocalizationManager.shared.localizedString(for: LocalizationKeys.currentWeightTitle),
                        value: "\(String(format: "%.1f", weightManager.getDisplayWeight(getCurrentWeight(), in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.getLocalizedUnitSymbol())",
                        color: .teal
                    )
                    
                    Spacer()
                    
                    ProgressStatItem(
                        title: LocalizationManager.shared.localizedString(for: LocalizationKeys.goalTitle),
                        value: "\(String(format: "%.1f", weightManager.getDisplayWeight(goal.targetWeight, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.getLocalizedUnitSymbol())",
                        color: .green
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
    
    // MARK: - Target Weight Input
    
    private var targetWeightInput: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.newTargetWeight))
                .font(.headline)
                .primaryGradientText()
            
            HStack(spacing: 12) {
                TextField("Ej: 70.5", text: $targetWeight)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .focused($isTargetWeightFocused)
                    .scaleEffect(isTargetWeightFocused ? 1.05 : 1.0)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black)
                            .shadow(color: isTargetWeightFocused ? .teal.opacity(0.3) : .black.opacity(0.1), radius: isTargetWeightFocused ? 8 : 6, x: 0, y: 3)
                            .scaleEffect(isTargetWeightFocused ? 1.02 : 1.0)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isTargetWeightFocused ? Color.teal : (isValidWeight ? Color.blue : Color.gray.opacity(0.4)), lineWidth: isTargetWeightFocused ? 3 : 2)
                            .scaleEffect(isTargetWeightFocused ? 1.02 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isTargetWeightFocused)
                    )
                    .animation(.easeInOut(duration: 0.2), value: isTargetWeightFocused)
                    .preferredColorScheme(.dark)
                    .onChange(of: targetWeight) { _ in
                        previousTargetWeight = targetWeight
                    }
                
                VStack(spacing: 4) {
                    Text(weightManager.getLocalizedUnitSymbol())
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.weightUnit))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
                .padding(.leading, 8)
            }
            
            if !targetWeight.isEmpty && !isValidWeight {
                Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.validWeightError))
                    .font(.caption)
                    .foregroundColor(Color.red)
            }
            
            // Diferencia con el objetivo actual
            if let weight = Double(targetWeight), weight > 0 {
                let difference = weight - goal.targetWeight
                let direction = difference > 0 ? LocalizationKeys.increase.localized : LocalizationKeys.decrease.localized
                let absValue = abs(difference)
                
                if absValue > 0.1 {
                    Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.weightDifference))
                        .font(.caption)
                        .foregroundColor(Color.blue)
                        .fontWeight(.medium)
                }
            }
        }
    }
    
    // MARK: - Target Date Picker
    private var targetDatePicker: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.newTargetDate))
                .font(.headline)
                .primaryGradientText()
            
            VStack(spacing: 12) {
                DatePicker(
                    LocalizationKeys.targetDate.localized,
                    selection: $targetDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .environment(\.locale, localizationManager.currentLanguage.locale)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black)
                        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isValidDate ? Color.blue : Color.gray.opacity(0.4), lineWidth: 2)
                )
                .preferredColorScheme(.dark)
                .onChange(of: targetDate) { _ in
                    // Simplified onChange without animations
                }
                
                if !isValidDate {
                    Text(LocalizationKeys.futureDateRequired.localized)
                        .font(.caption)
                        .foregroundColor(Color.red)
                }
                
                if isValidDate {
                    let duration = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        Text("\(LocalizationManager.shared.localizedString(for: LocalizationKeys.goalDuration)): \(duration) \(LocalizationManager.shared.localizedString(for: LocalizationKeys.days))")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    .transition(.opacity)
                }
            }
            
            // Comparación con fecha actual
            let _ = Calendar.current.dateComponents(
                [.day],
                from: goal.startDate ?? Date(), // 👈 valor por defecto
                to: Date()
            ).day ?? 0
            
            // Días originales del objetivo (desde inicio hasta fecha objetivo original)
            let currentDays = Calendar.current.dateComponents(
                [.day],
                from: goal.startDate ?? Date(),
                to: goal.targetDate ?? Date()
            ).day ?? 0

            let newDays = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
            let daysDifference = newDays - currentDays
            
            if daysDifference != 0 {
                let action = daysDifference > 0 ? LocalizationKeys.extend.localized : LocalizationKeys.shorten.localized
                let absDays = abs(daysDifference)
                
                Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.goalDateChange))
                    .font(.caption)
                    .foregroundColor(Color.blue)
                    .fontWeight(.medium)
            }
        }
    }
    
    // MARK: - Goal Stats View
    
    private var goalStatsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.goalStats))
                .font(.headline)
                .primaryGradientText()
            
            VStack(spacing: 12) {
                let daysElapsed = Calendar.current.dateComponents(
                    [.day],
                    from: goal.startDate ?? Date(), // 👈 valor por defecto
                    to: Date()
                ).day ?? 0
                
                // Total de días del objetivo original
                let totalDays = Calendar.current.dateComponents(
                    [.day],
                    from: goal.startDate ?? Date(),
                    to: goal.targetDate ?? Date()
                ).day ?? 0
                
                let remainingDays = Calendar.current.dateComponents([.day], from: Date(), to: goal.targetDate ?? Date()).day ?? 0
                
                StatRow(
                    icon: "calendar",
                    title: LocalizationManager.shared.localizedString(for: LocalizationKeys.daysElapsed),
                    value: "\(daysElapsed) \(LocalizationManager.shared.localizedString(for: LocalizationKeys.of)) \(totalDays)",
                    color: Color.blue
                )
                
                StatRow(
                    icon: "clock",
                    title: LocalizationManager.shared.localizedString(for: LocalizationKeys.daysRemaining),
                    value: "\(max(0, remainingDays))",
                    color: remainingDays > 0 ? Color.green : .red
                )
                
                let weightChange = getCurrentWeight() - goal.startWeight
                let _ = goal.targetWeight - goal.startWeight
                
                StatRow(
                    icon: "scalemass",
                    title: LocalizationManager.shared.localizedString(for: LocalizationKeys.weightChange),
                    value: "\(String(format: "%.1f", weightManager.getDisplayWeight(weightChange, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.getLocalizedUnitSymbol())",
                    color: weightChange != 0 ? Color.orange : .gray
                )
                
                if daysElapsed > 0 {
                    let avgWeeklyChange = (weightChange / Double(daysElapsed)) * 7
                    
                    StatRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: LocalizationManager.shared.localizedString(for: LocalizationKeys.weeklyAverage),
                        value: "\(String(format: "%.2f", weightManager.getDisplayWeight(avgWeeklyChange, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.getLocalizedUnitSymbol())/\(LocalizationManager.shared.localizedString(for: LocalizationKeys.week))",
                        color: Color.yellow
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
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Botón guardar
            Button {
                HapticFeedback.heavy()
                saveGoal()
            } label: {
                HStack {
                    if isLoading {
                        LoadingSpinner(color: .white, size: 20)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.teal)
                    }
                    
                    Text(isLoading ? LocalizationManager.shared.localizedString(for: LocalizationKeys.saving) : LocalizationManager.shared.localizedString(for: LocalizationKeys.saveChanges))
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: (canSaveGoal && hasChanges) ? [Color.blue, Color.orange] : [.gray, .gray],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .disabled(!canSaveGoal || !hasChanges || isLoading)
            .pressableScale(scale: (canSaveGoal && hasChanges) ? 0.98 : 1.0)
            .glowEffect(color: (canSaveGoal && hasChanges) ? Color.blue : .clear, radius: 8)
            .opacity((canSaveGoal && hasChanges) ? 1.0 : 0.6)
            .animation(AnimationConstants.smoothEase, value: canSaveGoal && hasChanges)
            
            // Botón eliminar
            Button {
                HapticFeedback.warning()
                showingDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.deleteGoal))
                }
                .font(.headline)
                .foregroundColor(Color.red)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red, lineWidth: 2)
                )
            }
            .pressableScale(scale: 0.98)
            .glowEffect(color: Color.red, radius: 6)
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupInitialValues() {
        targetWeight = String(goal.targetWeight)
        targetDate = goal.targetDate ?? Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 días por defecto
    }
    
    private func calculateProgress() -> Double {
        let startWeight = goal.startWeight
        let targetWeight = goal.targetWeight
        let currentWeight = getCurrentWeight()
        
        // Determinar si es objetivo de perder o ganar peso
        let isLosingWeight = targetWeight < startWeight
        let totalWeightChange = abs(targetWeight - startWeight)
        
        // Calcular progreso según la dirección del objetivo
        var currentProgress: Double = 0
        
        if totalWeightChange > 0 {
            if isLosingWeight {
                // Objetivo de perder peso: progreso = peso perdido / peso total a perder
                let weightLost = max(startWeight - currentWeight, 0)
                currentProgress = weightLost / totalWeightChange
            } else {
                // Objetivo de ganar peso: progreso = peso ganado / peso total a ganar
                let weightGained = max(currentWeight - startWeight, 0)
                currentProgress = weightGained / totalWeightChange
            }
            // Limitar el progreso entre 0 y 1 (0% y 100%)
            currentProgress = max(min(currentProgress, 1.0), 0.0)
        } else {
            // Si no hay cambio de peso objetivo, considerar como completado
            currentProgress = 1.0
        }
        
        return currentProgress
    }
    
    private func getCurrentWeight() -> Double {
        // Obtener el peso más reciente del usuario
        guard let latestEntry = weightManager.getLatestWeightEntry() else {
            return goal.startWeight // Si no hay entradas, usar el peso inicial del objetivo
        }
        return latestEntry.weight
    }
    
    private func saveGoal() {
        guard canSaveGoal && hasChanges, let weight = Double(targetWeight) else { 
            HapticFeedback.error()
            return 
        }
        
        isLoading = true
        
        Task {
            let success = await weightManager.updateGoal(
                goal,
                targetWeight: weight,
                targetDate: targetDate
            )
            
            await MainActor.run {
                isLoading = false
                
                if success {
                    HapticFeedback.success()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.2)) {
                        showingSuccess = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        NotificationCenter.default.post(name: .goalUpdated, object: nil)
                        dismiss()
                    }
                } else {
                    HapticFeedback.error()
                    errorMessage = LocalizationManager.shared.localizedString(for: LocalizationKeys.goalUpdateError)
                    showingError = true
                }
            }
        }
    }
    
    private func deleteGoal() {
        isLoading = true
        
        Task {
            // Verificar que el objetivo aún existe antes de intentar eliminarlo
            guard !goal.isDeleted else {
                await MainActor.run {
                    isLoading = false
                    HapticFeedback.error()
                    errorMessage = LocalizationManager.shared.localizedString(for: LocalizationKeys.goalAlreadyDeleted)
                    showingError = true
                }
                return
            }
            
            let success = await weightManager.deleteGoal(goal)
            
            await MainActor.run {
                isLoading = false
                
                if success {
                    HapticFeedback.success()
                    
                    // Notificar inmediatamente y cerrar el modal
                    NotificationCenter.default.post(name: .goalUpdated, object: nil)
                    dismiss()
                } else {
                    HapticFeedback.error()
                    errorMessage = LocalizationManager.shared.localizedString(for: LocalizationKeys.goalDeleteError)
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Supporting Views



struct StatRow: View {
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
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .textGradient()
        }
    }
}
