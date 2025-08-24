//
//  GoalsView.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import SwiftUI
import CoreData

struct GoalsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var weightManager = WeightDataManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    @State private var currentGoal: WeightGoal?
    @State private var showingCreateGoal = false
    @State private var showingEditGoal = false
    @State private var isLoading = true
    @State private var isLoadingGoalData = false
    @State private var goalAnimationProgress: Double = 0
    
    // Datos para el progreso
    @State private var currentWeight: Double = 0
    @State private var progressPercentage: Double = 0
    @State private var daysRemaining: Int = 0
    @State private var weightToGo: Double = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    if isLoading || isLoadingGoalData {
                        VStack(spacing: 20) {
                            CustomLoader()
                                .scaleInAnimation(delay: 0.2)
                            
                            if isLoadingGoalData {
                                Text(localizationManager.localizedString(for: LocalizationKeys.loadingGoalData))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .appearWithDelay(0.5)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let goal = currentGoal {
                        // Vista con objetivo activo
                        activeGoalView(goal: goal)
                            .appearWithDelay(0.1)
                    } else {
                        // Vista sin objetivo
                        noGoalView
                            .appearWithDelay(0.1)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color.black)
            .navigationTitle("")
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
            .sheet(isPresented: $showingCreateGoal) {
                CreateGoalView()
                    .slideFromBottom()
            }
            .sheet(isPresented: $showingEditGoal) {
                if let goal = currentGoal {
                    EditGoalView(goal: goal).slideFromBottom()
                }
            }
        }
        .onAppear {
            loadGoalData()
            withAnimation(AnimationConstants.smoothEase.delay(0.3)) {
                goalAnimationProgress = 1.0
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .goalUpdated)) { _ in
            // Mostrar loader mientras se recargan los datos
            isLoadingGoalData = true
            
            // Agregar un pequeño delay para asegurar que Core Data haya procesado los cambios
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                loadGoalData()
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        CustomLoader()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - No Goal View
    
    private var noGoalView: some View {
        VStack(spacing: 32) {
            // Icono y texto principal
            VStack(spacing: 16) {
                Image(systemName: "target")
                    .font(.system(size: 80))
                    .foregroundColor(.teal)
                
                Text(localizationManager.localizedString(for: LocalizationKeys.defineGoalTitle))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(localizationManager.localizedString(for: LocalizationKeys.defineGoalSubtitle))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .scaleInAnimation(delay: 0.2)
            
            // Botón para crear objetivo
            Button {
                HapticFeedback.medium()
                showingCreateGoal = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(localizationManager.localizedString(for: LocalizationKeys.createGoal))
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(.teal)
                .cornerRadius(16)
            }
            .appearWithDelay(0.3)
            
            // Consejos
            tipsView
                .appearWithDelay(0.4)
        }
        .padding(.top, 40)
    }
    
    // MARK: - Active Goal View
    
    private func activeGoalView(goal: WeightGoal) -> some View {
        VStack(spacing: 24) {
            // Header del objetivo
            goalHeaderView(goal: goal)
                .appearWithDelay(0.1)
            
            // Progreso circular
            progressCircleView(goal: goal)
                .appearWithDelay(0.2)
            
            // Estadísticas del progreso
            progressStatsView(goal: goal)
                .appearWithDelay(0.3)
            
            // Gráfico de progreso
            progressChartView(goal: goal)
                .appearWithDelay(0.4)
            
            // Acciones
            goalActionsView(goal: goal)
                .appearWithDelay(0.5)
        }
    }
    
    private func goalHeaderView(goal: WeightGoal) -> some View {
        // Verificar que el objetivo sigue siendo válido
        guard goal.managedObjectContext != nil && !goal.isDeleted else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizationKeys.currentGoal.localized)
                            .font(.headline)
                            .foregroundColor(.teal)
                        
                        Text("\(LocalizationKeys.goalTarget.localized): \(weightManager.getDisplayWeight(goal.targetWeight, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue), specifier: "%.1f") \(weightManager.getLocalizedUnitSymbol())")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(daysRemaining) \(LocalizationKeys.daysRemaining.localized)")
                            .font(.headline)
                            .foregroundColor(.teal)
                        
                        Text(LocalizationKeys.remaining.localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Barra de progreso de tiempo
                timeProgressBar(goal: goal)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(Color.gray.opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private func timeProgressBar(goal: WeightGoal) -> some View {
        // Verificar que el objetivo sigue siendo válido
        guard goal.managedObjectContext != nil && !goal.isDeleted else {
            return AnyView(EmptyView())
        }
        
        // Asegurar que tenemos fechas válidas
        guard let startDate = goal.startDate,
              let targetDate = goal.targetDate else {
            return AnyView(EmptyView())
        }
        
        let totalDays = Calendar.current.dateComponents([.day], from: startDate, to: targetDate).day ?? 1
        let elapsedDays = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        
        // Asegurar que no dividimos por cero y que el progreso esté entre 0 y 1
        let timeProgress = totalDays > 0 ? min(max(Double(elapsedDays) / Double(totalDays), 0.0), 1.0) : 0.0
        
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(LocalizationKeys.timeElapsed.localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(timeProgress * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.teal)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.4))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.teal)
                            .frame(width: geometry.size.width * timeProgress, height: 8)
                            .animation(.easeInOut(duration: 0.5), value: timeProgress)
                    }
                }
                .frame(height: 8)
            }
        )
    }
    
    private func progressCircleView(goal: WeightGoal) -> some View {
        // Verificar que el objetivo sigue siendo válido
        guard goal.managedObjectContext != nil && !goal.isDeleted else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 16) {
                Text(localizationManager.localizedString(for: LocalizationKeys.currentProgress))
                    .font(.headline)
                    .primaryGradientText()
                
                VStack(spacing: 12) {
                    // Progreso visual
                    let progress = progressPercentage / 100
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            let progressPercentageInt = Int(progressPercentage * goalAnimationProgress)
                            let percentText = localizationManager.localizedString(for: LocalizationKeys.percentCompleted)
                            
                            Text("\(progressPercentageInt)\(percentText)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .accentGradientText()
                            
                            let sinceDateText = localizationManager.localizedString(for: LocalizationKeys.sinceDate)
                            let formattedDate = goal.startDate?.formatted(date: .abbreviated, time: .omitted) ?? "—"
                            
                            Text("\(sinceDateText) \(formattedDate)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .environment(\.locale, LocalizationManager.shared.currentLanguage.locale)
                        }
                        
                        Spacer()
                        
                        CircularProgressView(progress: progress * goalAnimationProgress)
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
                            title: localizationManager.localizedString(for: LocalizationKeys.initialWeight),
                            value: "\(String(format: "%.1f", weightManager.getDisplayWeight(goal.startWeight, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.getLocalizedUnitSymbol())",
                            color: .gray
                        )
                        
                        Spacer()
                        
                        ProgressStatItem(
                            title: localizationManager.localizedString(for: LocalizationKeys.currentWeightTitle),
                            value: "\(String(format: "%.1f", weightManager.getDisplayWeight(currentWeight, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.getLocalizedUnitSymbol())",
                            color: .teal
                        )
                        
                        Spacer()
                        
                        ProgressStatItem(
                            title: localizationManager.localizedString(for: LocalizationKeys.goalTitle),
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
        )
    }
    
    private func progressStatsView(goal: WeightGoal) -> some View {
        HStack(spacing: 20) {
            ProgressStatCard(
                title: LocalizationKeys.currentWeight.localized,
                value: "\(String(format: "%.1f", weightManager.getDisplayWeight(currentWeight, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.getLocalizedUnitSymbol())",
                icon: "scalemass.fill",
                color: .teal
            )
            
            ProgressStatCard(
                title: LocalizationKeys.initialWeight.localized,
                value: "\(String(format: "%.1f", weightManager.getDisplayWeight(goal.startWeight, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.getLocalizedUnitSymbol())",
                icon: "flag.fill",
                color: .blue
            )
            
            ProgressStatCard(
                title: LocalizationKeys.goal.localized,
                value: "\(String(format: "%.1f", weightManager.getDisplayWeight(goal.targetWeight, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.getLocalizedUnitSymbol())",
                icon: "target",
                color: .green
            )
        }
    }

    
    private func progressChartView(goal: WeightGoal) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(LocalizationKeys.visualProgress.localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            // Gráfico real basado en datos de peso
            let weightEntries = weightManager.getWeightEntries(for: .month).prefix(7)
            let maxWeight = weightEntries.map { $0.weight }.max() ?? goal.startWeight
            let minWeight = weightEntries.map { $0.weight }.min() ?? goal.targetWeight
            let weightRange = maxWeight - minWeight
            
            if weightEntries.isEmpty {
                // Vista cuando no hay datos
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.title2)
                        .foregroundColor(.teal.opacity(0.6))
                    
                    Text(LocalizationKeys.noDataAvailable.localized)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text(LocalizationKeys.recordMoreWeights.localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 80)
                .frame(maxWidth: .infinity)
            } else {
                // Gráfico con datos reales
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(Array(weightEntries.enumerated()), id: \.offset) { index, entry in
                        let normalizedHeight = weightRange > 0 ? 
                            20 + ((entry.weight - minWeight) / weightRange) * 40 : 30
                        
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(entry.weight <= goal.targetWeight ? .green : .teal)
                                .frame(width: 20, height: max(normalizedHeight, 10))
                                .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.1), value: normalizedHeight)
                            
                            Text("\(String(format: "%.0f", weightManager.getDisplayWeight(entry.weight, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue)))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Rellenar espacios vacíos si hay menos de 7 entradas
                    ForEach(weightEntries.count..<7, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.clear)
                            .frame(width: 20, height: 10)
                    }
                }
                .frame(height: 80)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(Color.gray.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func goalActionsView(goal: WeightGoal) -> some View {
        VStack(spacing: 12) {
            Button {
                showingEditGoal = true
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text(LocalizationKeys.editGoal.localized)
                }
                .font(.headline)
                .foregroundColor(.teal)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.teal, lineWidth: 2)
                )
            }
            
            Button {
                completeGoal(goal)
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text(LocalizationKeys.markAsCompleted.localized)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.teal)
                .cornerRadius(12)
            }
            .disabled(progressPercentage < 100)
            .opacity(progressPercentage < 100 ? 0.6 : 1.0)
        }
    }
    
    // MARK: - Tips View
    
    private var tipsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.goalTips))
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                TipRow(
                    icon: "target",
                    title: LocalizationManager.shared.localizedString(for: LocalizationKeys.beRealistic),
                    description: LocalizationManager.shared.localizedString(for: LocalizationKeys.beRealisticDesc)
                )
                
                TipRow(
                    icon: "calendar",
                    title: LocalizationManager.shared.localizedString(for: LocalizationKeys.adequateTime),
                    description: LocalizationManager.shared.localizedString(for: LocalizationKeys.adequateTimeDesc)
                )
                
                TipRow(
                    icon: "heart.fill",
                    title: LocalizationManager.shared.localizedString(for: LocalizationKeys.stayMotivated),
                    description: LocalizationManager.shared.localizedString(for: LocalizationKeys.stayMotivatedDesc)
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.2))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    
    private func loadGoalData() {
        // Solo mostrar el loader principal en la primera carga
        if currentGoal == nil && !isLoadingGoalData {
            isLoading = true
        }
        
        Task {
            let goal = await weightManager.getActiveGoal()
            let latestWeight = await weightManager.getLatestWeight()
            
            await MainActor.run {
                // Primero asignar el peso actual
                self.currentWeight = latestWeight?.weight ?? 0
                
                // Verificar que el objetivo existe y es válido
                if let goal = goal {
                    // Verificar que el objetivo no haya sido eliminado del contexto y no esté marcado como eliminado
                    if goal.managedObjectContext != nil && !goal.isDeleted {
                        self.currentGoal = goal
                        calculateProgress(for: goal)
                    } else {
                        self.currentGoal = nil
                        // Resetear valores cuando no hay objetivo
                        self.progressPercentage = 0
                        self.daysRemaining = 0
                        self.weightToGo = 0
                    }
                } else {
                    self.currentGoal = nil
                    // Resetear valores cuando no hay objetivo
                    self.progressPercentage = 0
                    self.daysRemaining = 0
                    self.weightToGo = 0
                }
                
                // Ocultar ambos loaders
                isLoading = false
                isLoadingGoalData = false
            }
        }
    }
    
    private func calculateProgress(for goal: WeightGoal) {
        // Verificar que el objetivo sigue siendo válido antes de acceder a sus propiedades
        guard goal.managedObjectContext != nil && !goal.isDeleted else {
            // Si el objetivo ha sido eliminado, resetear valores
            self.progressPercentage = 0
            self.daysRemaining = 0
            self.weightToGo = 0
            return
        }
        
        let startWeight = goal.startWeight
        let targetWeight = goal.targetWeight
        let currentWeight = self.currentWeight
        
        // Determinar si es objetivo de perder o ganar peso
        let isLosingWeight = targetWeight < startWeight
        let totalWeightChange = abs(targetWeight - startWeight)
        
        // Calcular progreso según la dirección del objetivo
        var currentProgress: Double = 0
        
        if totalWeightChange > 0 {
            if isLosingWeight {
                // Objetivo de perder peso: progreso = peso perdido / peso total a perder
                let weightLost = max(startWeight - currentWeight, 0)
                currentProgress = weightLost / Double(totalWeightChange)
            } else {
                // Objetivo de ganar peso: progreso = peso ganado / peso total a ganar
                let weightGained = max(currentWeight - startWeight, 0)
                currentProgress = weightGained / Double(totalWeightChange)
            }
            // Limitar el progreso entre 0 y 1 (0% y 100%)
            currentProgress = max(min(currentProgress, 1.0), 0.0)
        } else {
            // Si no hay cambio de peso objetivo, considerar como completado
            currentProgress = 1.0
        }
        
        progressPercentage = currentProgress * 100
        
        // Calcular peso restante para alcanzar el objetivo
        if isLosingWeight {
            weightToGo = max(currentWeight - targetWeight, 0)
        } else {
            weightToGo = max(targetWeight - currentWeight, 0)
        }
        
        // Calcular días restantes
        if let targetDate = goal.targetDate {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: Date(), to: targetDate)
            daysRemaining = max(components.day ?? 0, 0)
        }
    }
    
    private func completeGoal(_ goal: WeightGoal) {
        Task {
            await weightManager.completeGoal(goal)
            await loadGoalData()
        }
    }
}

// MARK: - Supporting Views

struct ProgressStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct TipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.teal)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(.teal.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
