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
    
    let goal: WeightGoal
    
    @State private var targetWeight: String = ""
    @State private var targetDate = Date()
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingDeleteAlert = false
    @State private var editAnimationProgress: Double = 0
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
            .navigationTitle("Editar Objetivo")
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
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        HapticFeedback.heavy()
                        saveGoal()
                    } label: {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.title3)
                            .foregroundColor(canSaveGoal && hasChanges ? .primary : .secondary)
                    }
                    .disabled(!canSaveGoal || !hasChanges)
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
            .alert("Eliminar Objetivo", isPresented: $showingDeleteAlert) {
                Button("Cancelar", role: .cancel) { 
                    HapticFeedback.light()
                }
                Button("Eliminar", role: .destructive) {
                    HapticFeedback.heavy()
                    deleteGoal()
                }
            } message: {
                Text("¿Estás seguro de que quieres eliminar este objetivo? Esta acción no se puede deshacer.")
            }
        }
        .overlay {
            if showingSuccess {
                SuccessCheckmark()
                    .transition(.scale.combined(with: .opacity))
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
            
            Text("Objetivo en progreso")
                .font(.title2)
                .fontWeight(.bold)
                .primaryGradientText()
                .modernShadow()
            
            Text("Ajusta tu objetivo según tu progreso actual")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    // MARK: - Current Progress View
    
    private var currentProgressView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progreso actual")
                .font(.headline)
                .primaryGradientText()
            
            VStack(spacing: 12) {
                // Progreso visual
                let progress = calculateProgress()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(progress * 100 * editAnimationProgress))% completado")
                            .font(.title3)
                            .fontWeight(.bold)
                            .accentGradientText()
                            .animatedCounter(value: progress * 100 * editAnimationProgress)
                        
                        Text("Desde \(goal.startDate?.formatted(date: .abbreviated, time: .omitted) ?? "—")")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                        title: "Peso inicial",
                        value: "\(String(format: "%.1f", weightManager.getDisplayWeight(goal.startWeight, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue)",
                        color: .gray
                    )
                    
                    Spacer()
                    
                    ProgressStatItem(
                        title: "Peso actual",
                        value: "\(String(format: "%.1f", weightManager.getDisplayWeight(getCurrentWeight(), in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue)",
                        color: .teal
                    )
                    
                    Spacer()
                    
                    ProgressStatItem(
                        title: "Objetivo",
                        value: "\(String(format: "%.1f", weightManager.getDisplayWeight(goal.targetWeight, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue)",
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Nuevo peso objetivo")
                .font(.headline)
                .primaryGradientText()
            
            HStack {
                TextField("Ej: 70.5", text: $targetWeight)
                    .font(.title3)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .onChange(of: targetWeight) { oldValue, newValue in
                        HapticFeedback.light()
                    }
                
                Text(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .pulseEffect(intensity: 0.1, duration: 2.0)
            }
            
            if !targetWeight.isEmpty && !isValidWeight {
                Text("Ingresa un peso válido (1-500 \(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))")
                    .font(.caption)
                    .foregroundColor(Color.red)
            }
            
            // Diferencia con el objetivo actual
            if let weight = Double(targetWeight), weight > 0 {
                let difference = weight - goal.targetWeight
                let direction = difference > 0 ? "aumentar" : "reducir"
                let absValue = abs(difference)
                
                if absValue > 0.1 {
                    Text("Esto significa \(direction) tu objetivo en \(weightManager.getDisplayWeight(absValue, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue), specifier: "%.1f") \(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue)")
                        .font(.caption)
                        .foregroundColor(Color.blue)
                        .fontWeight(.medium)
                }
            }
        }
    }
    
    // MARK: - Target Date Picker
    private var targetDatePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nueva fecha objetivo")
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
                let action = daysDifference > 0 ? "extender" : "acortar"
                let absDays = abs(daysDifference)
                
                Text("Esto va a \(action) tu objetivo en \(absDays) días")
                    .font(.caption)
                    .foregroundColor(Color.blue)
                    .fontWeight(.medium)
            }
        }
    }
    
    // MARK: - Goal Stats View
    
    private var goalStatsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Estadísticas del objetivo")
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
                    title: "Días transcurridos",
                    value: "\(daysElapsed) de \(totalDays)",
                    color: Color.blue
                )
                
                StatRow(
                    icon: "clock",
                    title: "Días restantes",
                    value: "\(max(0, remainingDays))",
                    color: remainingDays > 0 ? Color.green : .red
                )
                
                let weightChange = getCurrentWeight() - goal.startWeight
                let _ = goal.targetWeight - goal.startWeight
                
                StatRow(
                    icon: "scalemass",
                    title: "Cambio de peso",
                    value: "\(String(format: "%.1f", weightManager.getDisplayWeight(weightChange, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue)",
                    color: weightChange != 0 ? Color.orange : .gray
                )
                
                if daysElapsed > 0 {
                    let avgWeeklyChange = (weightChange / Double(daysElapsed)) * 7
                    
                    StatRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Promedio semanal",
                        value: "\(String(format: "%.2f", weightManager.getDisplayWeight(avgWeeklyChange, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue)/sem",
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
                    }
                    
                    Text(isLoading ? "Guardando..." : "Guardar Cambios")
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
                    Text("Eliminar Objetivo")
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
        let currentWeight = getCurrentWeight()
        let totalChange = goal.targetWeight - goal.startWeight
        let currentChange = currentWeight - goal.startWeight
        
        guard totalChange != 0 else { return 0 }
        
        return min(max(currentChange / totalChange, 0), 1)
    }
    
    private func getCurrentWeight() -> Double {
        // En una implementación real, esto debería obtener el peso más reciente
        // Por ahora, usamos un valor simulado basado en el progreso
        let progress = 0.6 // 60% de progreso simulado
        return goal.startWeight + (goal.targetWeight - goal.startWeight) * progress
    }
    
    private func saveGoal() {
        guard canSaveGoal && hasChanges, let weight = Double(targetWeight) else { 
            HapticFeedback.error()
            return 
        }
        
        isLoading = true
        
        Task {
            do {
                try await weightManager.updateGoal(
                    goal,
                    targetWeight: weight,
                    targetDate: targetDate
                )
                
                await MainActor.run {
                    isLoading = false
                    HapticFeedback.success()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.2)) {
                    showingSuccess = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        NotificationCenter.default.post(name: .goalUpdated, object: nil)
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    HapticFeedback.error()
                    errorMessage = "No se pudo actualizar el objetivo. Inténtalo de nuevo."
                    showingError = true
                }
            }
        }
    }
    
    private func deleteGoal() {
        Task {
            // Verificar que el objetivo aún existe antes de intentar eliminarlo
            guard !goal.isDeleted else {
                await MainActor.run {
                    HapticFeedback.error()
                    errorMessage = "El objetivo ya ha sido eliminado."
                    showingError = true
                }
                return
            }
            
            let success = await weightManager.deleteGoal(goal)
            
            await MainActor.run {
                if success {
                    HapticFeedback.success()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.2)) {
                        showingSuccess = true
                    }
                    
                    // Notificar inmediatamente y cerrar después de un breve delay
                    NotificationCenter.default.post(name: .goalUpdated, object: nil)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        dismiss()
                    }
                } else {
                    HapticFeedback.error()
                    errorMessage = "No se pudo eliminar el objetivo. Inténtalo de nuevo."
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.green.opacity(0.3), lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(gradient: Gradient(colors: [.teal, .blue]), startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.bold)
                .accentGradientText()
        }
    }
}

struct ProgressStatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

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
