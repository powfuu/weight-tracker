//
//  CreateGoalView.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import SwiftUI
import CoreData
import Combine

struct CreateGoalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var weightManager = WeightDataManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    @State private var targetWeight: String = ""
    @State private var targetDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var currentWeight: Double = 0
    @State private var goalType: GoalType = .lose
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var formAnimationProgress: Double = 0
    @State private var showingSuccess = false
    @State private var targetWeightScale: CGFloat = 1.0
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
            .navigationTitle(LocalizationKeys.newGoal.localized)
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
        }
        .overlay {
            if showingSuccess {
                SuccessCheckmark()
                    .transition(.opacity)
            }
        }
        .onAppear {
            loadCurrentWeight()
            withAnimation(AnimationConstants.smoothEase.delay(0.2)) {
                formAnimationProgress = 1.0
            }
            
            // Observar notificaciones de error
            NotificationCenter.default.addObserver(
                forName: .goalCreationFailed,
                object: nil,
                queue: .main
            ) { notification in
                if let error = notification.userInfo?["error"] as? Error {
                    errorMessage = "\(LocalizationManager.shared.localizedString(for: "goal_creation_error")): \(error.localizedDescription)"
                    showingError = true
                    isLoading = false
                }
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: .goalCreationFailed, object: nil)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 50))
                .textGradient()
                .modernShadow()
            
            Text(LocalizationManager.shared.localizedString(for: "goal_motivation_text"))
                .font(.body)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    // MARK: - Goal Type Selector
    
    private var goalTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizationManager.shared.localizedString(for: "goal_type"))
                .font(.headline)
                .primaryGradientText()

            HStack(spacing: 12) {
                ForEach(GoalType.allCases, id: \.self) { type in
                    GoalTypeCard(
                        type: type,
                        isSelected: goalType == type,
                        onTap: {
                            HapticFeedback.medium()
                            goalType = type
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

                    Text(type.localizedTitle)
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
            }
            .pressableScale(scale: 0.95)
            .glowEffect(color: isSelected ? type.color : .clear, radius: 4)
        }
    }


    
    // MARK: - Current Weight View
    
    private var currentWeightView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizationManager.shared.localizedString(for: "current_weight"))
                .font(.headline)
                .primaryGradientText()
            
            HStack {
                Image(systemName: "scalemass.fill")
                    .accentGradientText()
                
                Text("\(weightManager.getDisplayWeight(currentWeight, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue), specifier: "%.1f") \(weightManager.getLocalizedUnitSymbol())")
                    .font(Font.title3)
                    .fontWeight(.medium)
                    .primaryGradientText()
                
                Spacer()
                
                Text(LocalizationManager.shared.localizedString(for: "last_record"))
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
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString(for: "target_weight"))
                .font(.headline)
                .primaryGradientText()
            
            HStack(spacing: 12) {
                TextField(LocalizationManager.shared.localizedString(for: "weight_placeholder"), text: $targetWeight)
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
                    .preferredColorScheme(.dark)
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
                    .onReceive(Just(targetWeight)
                        .removeDuplicates()
                        .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)) { value in
                        Task.detached {
                            await MainActor.run {
                                HapticFeedback.light()
                                previousTargetWeight = value
                            }
                        }
                    }
                
                VStack(spacing: 4) {
                    Text(weightManager.getLocalizedUnitSymbol())
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    Text(LocalizationManager.shared.localizedString(for: "unit"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
                .padding(.leading, 8)
            }
            
            if !targetWeight.isEmpty && !isValidWeight {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text(String(format: LocalizationManager.shared.localizedString(for: "enter_valid_weight_range_format"), weightManager.getLocalizedUnitSymbol()))
                        .font(.caption)
                        .foregroundColor(.orange)
                        .minimumScaleFactor(0.8)
                        .lineLimit(2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                )
                .transition(.opacity)
            }
            
            // Diferencia de peso
            if let weight = Double(targetWeight), weight > 0 {
                let difference = abs(weight - currentWeight)
                let direction = weight > currentWeight ? LocalizationManager.shared.localizedString(for: "gain") : LocalizationManager.shared.localizedString(for: "lose")
                
                HStack {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text("\(LocalizationManager.shared.localizedString(for: "you_need_to")) \(direction) \(weightManager.getDisplayWeight(difference, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue), specifier: "%.1f") \(weightManager.getLocalizedUnitSymbol())")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                        .minimumScaleFactor(0.8)
                        .lineLimit(2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
                .scaleInAnimation(delay: 0.1)
            }
        }
    }
    
    // MARK: - Target Date Picker
    
    private var targetDatePicker: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationKeys.targetDate.localized)
                .font(.headline)
                .primaryGradientText()
            
            VStack(spacing: 12) {
                DatePicker(
                    "Selecciona la fecha",
                    selection: $targetDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .environment(\.locale, localizationManager.currentLanguage.locale)
                .preferredColorScheme(.dark)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isValidDate ? Color.green : Color.gray.opacity(0.4), lineWidth: 1)
                )
                
                if !isValidDate {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text(LocalizationKeys.futureDateRequired.localized)
                            .font(.caption)
                            .foregroundColor(.orange)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.1))
                    )
                    .transition(.opacity)
                }
                
                // Duración del objetivo
                let days = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
                if days > 0 {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text(String(format: LocalizationKeys.durationDaysWeeks.localized, days, days / 7))
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.1))
                    )
                    .transition(.opacity)
                }
            }
        }
    }
    
    // MARK: - Goal Summary View
    
    private var goalSummaryView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationKeys.goalSummary.localized)
                .font(.headline)
                .primaryGradientText()
            
            VStack(spacing: 12) {
                SummaryRow(
                        icon: "scalemass.fill",
                        title: LocalizationKeys.targetWeight.localized,
                        value: isValidWeight ? "\(targetWeight) \(weightManager.getLocalizedUnitSymbol())" : "--",
                        color: Color.blue
                    )
                
                SummaryRow(
                    icon: "calendar",
                    title: LocalizationKeys.deadline.localized,
                    value: targetDate.formatted(date: .abbreviated, time: .omitted),
                    color: Color.green
                )
                .environment(\.locale, localizationManager.currentLanguage.locale)
                
                if let weight = Double(targetWeight), weight > 0 {
                    let difference = abs(weight - currentWeight)
                    let direction = weight > currentWeight ? LocalizationKeys.gain.localized : LocalizationKeys.lose.localized
                    
                    SummaryRow(
                        icon: goalType.icon,
                        title: LocalizationKeys.requiredChange.localized,
                        value: "\(direction) \(String(format: "%.1f", weightManager.getDisplayWeight(abs(difference), in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.getLocalizedUnitSymbol())",
                        color: goalType.color
                    )
                }
                
                let days = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
                if days > 0 && isValidWeight, let weight = Double(targetWeight) {
                    let weeklyChange = abs(weight - currentWeight) / Double(days) * 7
                    
                    SummaryRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: LocalizationKeys.weeklyChange.localized,
                        value: "\(String(format: "%.2f", weightManager.getDisplayWeight(weeklyChange, in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.getLocalizedUnitSymbol())/\(LocalizationManager.shared.localizedString(for: "week"))",
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
                
                Text(isLoading ? LocalizationKeys.creating.localized : LocalizationKeys.createGoal.localized)
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
            let success = await weightManager.createGoal(
                targetWeight: weight,
                targetDate: targetDate
            )
            
            await MainActor.run {
                isLoading = false
                
                if success {
                    HapticFeedback.success()
                    withAnimation(.spring) {
                        showingSuccess = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                } else {
                    HapticFeedback.error()
                    errorMessage = LocalizationManager.shared.localizedString(for: "goal_creation_error")
                    showingError = true
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
            return "Lose Weight"
        case .gain:
            return "Gain Weight"
        case .maintain:
            return "Maintain Weight"
        }
    }
    
    var localizedTitle: String {
        switch self {
        case .lose:
            return LocalizationKeys.goalTypeLose.localized
        case .gain:
            return LocalizationKeys.goalTypeGain.localized
        case .maintain:
            return LocalizationKeys.goalTypeMaintain.localized
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
