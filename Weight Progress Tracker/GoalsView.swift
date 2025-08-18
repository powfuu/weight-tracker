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
    
    @State private var currentGoal: WeightGoal?
    @State private var showingCreateGoal = false
    @State private var showingEditGoal = false
    @State private var isLoading = true
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
                    if isLoading {
                        CustomLoader()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .scaleInAnimation(delay: 0.2)
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
            .background(Color(.systemBackground))
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
                
                Text("¡Define tu objetivo!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Establece una meta de peso y fecha para mantenerte motivado en tu progreso")
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
                    Text("Crear Objetivo")
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
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Objetivo Actual")
                        .font(.headline)
                        .foregroundColor(.teal)
                    
                    Text("Meta: \(weightManager.getDisplayWeight(goal.targetWeight, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue), specifier: "%.1f") \(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(daysRemaining) días")
                        .font(.headline)
                        .foregroundColor(.teal)
                    
                    Text("restantes")
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
                .fill(Color(.systemGray6))
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func timeProgressBar(goal: WeightGoal) -> some View {
        let totalDays = Calendar.current.dateComponents([.day], from: goal.startDate ?? Date(), to: goal.targetDate ?? Date()).day ?? 1
        let elapsedDays = Calendar.current.dateComponents([.day], from: goal.startDate ?? Date(), to: Date()).day ?? 0
        let timeProgress = min(Double(elapsedDays) / Double(totalDays), 1.0)
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tiempo transcurrido")
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
                        .fill(Color(.systemGray4))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.teal)
                        .frame(width: geometry.size.width * timeProgress, height: 8)
                        .animation(.easeInOut(duration: 0.5), value: timeProgress)
                }
            }
            .frame(height: 8)
        }
    }
    
    private func progressCircleView(goal: WeightGoal) -> some View {
        VStack(spacing: 16) {
            ZStack {
                // Círculo de fondo
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 12)
                    .frame(width: 200, height: 200)
                
                // Círculo de progreso
                Circle()
                    .trim(from: 0, to: progressPercentage / 100)
                    .stroke(
                        .teal,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: progressPercentage)
                
                // Contenido central
                VStack(spacing: 8) {
                    Text("\(Int(progressPercentage))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Completado")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if weightToGo > 0 {
                        Text("\(weightManager.getDisplayWeight(weightToGo, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue), specifier: "%.1f") \(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue) restantes")
                            .font(.caption2)
                            .foregroundColor(.teal)
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }
    
    private func progressStatsView(goal: WeightGoal) -> some View {
        HStack(spacing: 20) {
            ProgressStatCard(
                title: "Peso Actual",
                value: "\(String(format: "%.1f", weightManager.getDisplayWeight(currentWeight, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue)",
                icon: "scalemass.fill",
                color: .teal
            )
            
            ProgressStatCard(
                title: "Peso Inicial",
                value: "\(String(format: "%.1f", weightManager.getDisplayWeight(goal.startWeight, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue)",
                icon: "flag.fill",
                color: .blue
            )
            
            ProgressStatCard(
                title: "Meta",
                value: "\(String(format: "%.1f", weightManager.getDisplayWeight(goal.targetWeight, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue)",
                icon: "target",
                color: .green
            )
        }
    }

    
    private func progressChartView(goal: WeightGoal) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Progreso Visual")
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
                    
                    Text("No hay datos suficientes")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text("Registra más pesos para ver tu progreso")
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
                .fill(Color(.systemGray6))
                .stroke(Color(.systemGray4), lineWidth: 1)
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
                    Text("Editar Objetivo")
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
                    Text("Marcar como Completado")
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
            Text("Consejos para establecer objetivos")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                TipRow(
                    icon: "target",
                    title: "Sé realista",
                    description: "Establece metas alcanzables y saludables"
                )
                
                TipRow(
                    icon: "calendar",
                    title: "Tiempo adecuado",
                    description: "Da tiempo suficiente para lograr tu objetivo"
                )
                
                TipRow(
                    icon: "heart.fill",
                    title: "Mantente motivado",
                    description: "Celebra los pequeños logros en el camino"
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    
    private func loadGoalData() {
        isLoading = true
        
        Task {
            let goal = await weightManager.getActiveGoal()
            let latestWeight = await weightManager.getLatestWeight()
            
            await MainActor.run {
                // Verificar que el objetivo no haya sido eliminado antes de asignarlo
                if let goal = goal, !goal.isDeleted {
                    self.currentGoal = goal
                    calculateProgress(for: goal)
                } else {
                    self.currentGoal = nil
                    // Resetear valores cuando no hay objetivo
                    self.progressPercentage = 0
                    self.daysRemaining = 0
                    self.weightToGo = 0
                }
                
                self.currentWeight = latestWeight?.weight ?? 0
                isLoading = false
            }
        }
    }
    
    private func calculateProgress(for goal: WeightGoal) {
        let startWeight = goal.startWeight
        let targetWeight = goal.targetWeight
        let currentWeight = self.currentWeight
        
        let totalWeightChange = abs(targetWeight - startWeight)
        let currentWeightChange = abs(currentWeight - startWeight)
        
        if totalWeightChange > 0 {
            progressPercentage = min((currentWeightChange / totalWeightChange) * 100, 100)
        } else {
            progressPercentage = 100
        }
        
        weightToGo = abs(targetWeight - currentWeight)
        
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
                .fill(Color(.systemGray6))
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
