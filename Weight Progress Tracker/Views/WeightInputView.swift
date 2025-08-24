//
//  WeightInputView.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import SwiftUI
import Combine
import Foundation

struct WeightInputView: View {
    @Binding var isPresented: Bool
    @StateObject private var weightManager = WeightDataManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    
    @State private var weightInput = ""
    @State private var selectedDate = Date()
    @State private var showingDatePicker = true
    @State private var isLoading = false
    @State private var isLoadingInitialWeight = true
    @State private var showingSuccessAnimation = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingSuccess = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Variable para tracking de cambios
    @State private var previousWeightInput: String = ""
    
    @FocusState private var isWeightFieldFocused: Bool
    
    private var preferredUnit: String {
        weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
    }
    
    private var preferredUnitSymbol: String {
        weightManager.getLocalizedUnitSymbol()
    }
    
    private var isValidWeight: Bool {
        // Intentar parsear usando el formatter localizado primero
        let normalizedInput = weightInput.replacingOccurrences(of: ",", with: ".")
        
        guard let weight = localizationManager.localizedDecimalFormatter.number(from: weightInput)?.doubleValue ?? Double(normalizedInput),
              weight > 0 else { return false }
        
        // Validación de rangos razonables (1-600 para ambas unidades)
        return weight >= 1 && weight <= 600
    }
    
    private var weightValue: Double? {
        guard isValidWeight else { return nil }
        
        // Intentar parsear usando el formatter localizado primero
        if let number = localizationManager.localizedDecimalFormatter.number(from: weightInput) {
            return number.doubleValue
        }
        
        // Fallback: reemplazar coma por punto y parsear
        let normalizedInput = weightInput.replacingOccurrences(of: ",", with: ".")
        return Double(normalizedInput)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: dismissView) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(.primary)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Contenido principal
                ScrollView {
                    VStack(spacing: 32) {
                        // Input de peso
                        weightInputSection
                        
                        // Selector de fecha
                        dateSection
                        
                        // Información adicional
                        infoSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
                
                // Botón de guardar
                saveButtonSection
            }
            .background(Color.black)
            .navigationTitle(LocalizationManager.shared.localizedString(for: LocalizationKeys.recordWeight))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .accessibilityAddTraits(.isHeader)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                toolbarContent
            }
        }
        .onAppear {
            setupInitialState()
        }
        .onChange(of: weightInput) { _ in
            previousWeightInput = weightInput
        }
        .alert(LocalizationManager.shared.localizedString(for: LocalizationKeys.errorTitle), isPresented: $showingError) {
            Button(LocalizationManager.shared.localizedString(for: LocalizationKeys.errorOk)) {
                showingError = false
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button(LocalizationManager.shared.localizedString(for: LocalizationKeys.validationOk)) {
                showingAlert = false
            }
        } message: {
            Text(alertMessage)
        }
        .overlay {
            if showingSuccessAnimation {
                successAnimationOverlay
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "scalemass")
                    .font(.title2)
                    .foregroundColor(.teal)
                
                Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.weightInputTitle))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
            }
            
            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.weightInputSubtitle))
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.9)
                .lineLimit(2)
        }
        .padding(.top, 16)
    }
    
    // MARK: - Weight Input Section
    
    private var weightInputSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    TextField("0.0", text: $weightInput)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        #endif
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 24)
                        .accessibilityLabel(LocalizationManager.shared.localizedString(for: LocalizationKeys.fieldLabel))
                .accessibilityHint(LocalizationManager.shared.localizedString(for: LocalizationKeys.fieldHint) + " \(preferredUnitSymbol)")
                        .opacity(isLoadingInitialWeight ? 0.3 : 1.0)
                        .disabled(isLoadingInitialWeight)
                        .focused($isWeightFieldFocused)
                        .animation(nil, value: isWeightFieldFocused)
                        .scaleEffect(isWeightFieldFocused ? 1.05 : 1.0)
                    
                    // Placeholder de carga
                    if isLoadingInitialWeight {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.teal)
                            
                            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.weightInputLoading))
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black)
                        .shadow(color: isWeightFieldFocused ? .teal.opacity(0.3) : .white.opacity(0.1), radius: isWeightFieldFocused ? 8 : 2)
                        .scaleEffect(isWeightFieldFocused ? 1.02 : 1.0)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isWeightFieldFocused ? Color.teal : Color.gray.opacity(0.3), lineWidth: isWeightFieldFocused ? 3 : 1)
                        .scaleEffect(isWeightFieldFocused ? 1.02 : 1.0)
                )
                .animation(.easeInOut(duration: 0.2), value: isWeightFieldFocused)
                
                VStack(spacing: 4) {
                    Text(preferredUnitSymbol)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.teal)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.weightUnit))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                        .accessibilityHidden(true)
                }
                .padding(.leading, 8)
            }
            .padding(.horizontal, 20)
            
            if !weightInput.isEmpty && !isValidWeight {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.invalidWeight) + " (1-600 \(preferredUnitSymbol))")
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
            }
        }
    }
    
    // MARK: - Date Section
    
    private var dateSection: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(.teal)
                        .font(.title3)
                    
                    Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.dateLabel))
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                        .accessibilityAddTraits(.isHeader)
                }
                
                Spacer()
                
                if !Calendar.current.isDateInToday(selectedDate) {
                    Button(LocalizationManager.shared.localizedString(for: LocalizationKeys.todayButton)) {
                        selectedDate = Date()
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.teal)
                    .accessibilityLabel(LocalizationManager.shared.localizedString(for: LocalizationKeys.todayAccessibility))
                    .accessibilityHint(LocalizationManager.shared.localizedString(for: LocalizationKeys.todayHint))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.teal.opacity(0.1))
                    )
                }
            }
            .padding(.horizontal, 20)
            
            Button(action: {
                showingDatePicker.toggle()
            }) {
                HStack(spacing: 12) {
                    Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                        .environment(\.locale, localizationManager.currentLanguage.locale)
                    
                    Spacer()
                    
                    Image(systemName: showingDatePicker ? "chevron.up" : "chevron.down")
                        .foregroundColor(.teal)
                        .font(.caption)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black)
                        .shadow(radius: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
            
            if showingDatePicker {
                DatePicker(
                    LocalizationManager.shared.localizedString(for: LocalizationKeys.selectDate),
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .preferredColorScheme(.dark)
                .environment(\.locale, localizationManager.currentLanguage.locale)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            }
        }
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb")
                    .font(.title3)
                    .foregroundColor(.teal)
                
                Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.tipsTitle))
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "clock",
                    text: LocalizationManager.shared.localizedString(for: LocalizationKeys.tipTime)
                )
                
                InfoRow(
                    icon: "drop",
                    text: LocalizationManager.shared.localizedString(for: LocalizationKeys.tipFasting)
                )
                
                InfoRow(
                    icon: "tshirt",
                    text: LocalizationManager.shared.localizedString(for: LocalizationKeys.tipClothing)
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Save Button Section
    
    private var saveButtonSection: some View {
        VStack(spacing: 20) {
            Button {
                saveWeight()
            } label: {
                HStack(spacing: 12) {
                    if isLoading {
                        CustomLoader()
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Text(isLoading ? LocalizationManager.shared.localizedString(for: LocalizationKeys.saving) : LocalizationManager.shared.localizedString(for: LocalizationKeys.saveButton))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isValidWeight ?
                                LinearGradient(
                                    colors: [Color.teal, Color.teal.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .shadow(color: Color.teal.opacity(0.2), radius: 6, x: 0, y: 3)
                )
            }
            .disabled(!isValidWeight || isLoading)
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(isLoading ? LocalizationManager.shared.localizedString(for: LocalizationKeys.savingAccessibility) : LocalizationManager.shared.localizedString(for: LocalizationKeys.saveAccessibility))
            .accessibilityHint(LocalizationManager.shared.localizedString(for: LocalizationKeys.saveHint))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }
    
    // MARK: - Success Animation Overlay
    
    private var successAnimationOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.teal)
                
                Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.successTitle))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.successMessage))
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.9)
                    .lineLimit(2)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black)
                    .shadow(color: .white.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .opacity(showingSuccessAnimation ? 1.0 : 0.0)
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupInitialState() {
        // Cargar el último peso de forma asíncrona para no bloquear la UI
        Task {
            await loadLastWeightAsync()
        }
    }
    
    @MainActor
    private func loadLastWeightAsync() async {
        // Usar la función asíncrona optimizada de WeightDataManager
        let lastEntry = await weightManager.getLatestWeight()
        
        // Actualizar la UI en el hilo principal
        if let lastEntry = lastEntry {
            let displayWeight = weightManager.getDisplayWeight(lastEntry.weight, in: preferredUnit)
            weightInput = LocalizationManager.shared.formatWeight(displayWeight)
            previousWeightInput = weightInput
        }
        
        // Marcar como completada la carga inicial
        isLoadingInitialWeight = false
    }
    
    private func saveWeight() {
        // Validar campo vacío
        if weightInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alertTitle = LocalizationManager.shared.localizedString(for: LocalizationKeys.emptyWeightField)
            alertMessage = LocalizationManager.shared.localizedString(for: LocalizationKeys.emptyWeightFieldDesc)
            showingAlert = true
            HapticFeedback.error()
            return
        }
        
        // Validar formato numérico
        let normalizedInput = weightInput.replacingOccurrences(of: ",", with: ".")
        guard let weight = localizationManager.localizedDecimalFormatter.number(from: weightInput)?.doubleValue ?? Double(normalizedInput) else {
            alertTitle = LocalizationManager.shared.localizedString(for: LocalizationKeys.invalidWeightData)
            alertMessage = LocalizationManager.shared.localizedString(for: LocalizationKeys.invalidWeightDataDesc)
            showingAlert = true
            HapticFeedback.error()
            return
        }
        
        // Validar rango
        if weight < 1 || weight > 600 {
            alertTitle = LocalizationManager.shared.localizedString(for: LocalizationKeys.weightOutOfRange)
            alertMessage = LocalizationManager.shared.localizedString(for: LocalizationKeys.weightOutOfRangeDesc)
            showingAlert = true
            HapticFeedback.error()
            return
        }
        
        isLoading = true
        isWeightFieldFocused = false
        HapticFeedback.medium()
        
        Task {
            // Guardar en Core Data con la unidad correcta
            weightManager.addWeightEntry(
                weight: weight,
                unit: preferredUnit,
                timestamp: selectedDate
            )
            
            // Verificar progreso del objetivo
            if let progress = weightManager.getGoalProgress() {
                await checkGoalMilestones(progress: progress)
            }
            
            // Verificar si el objetivo se ha cumplido automáticamente
            await checkGoalCompletion(newWeight: weight)
            
            await MainActor.run {
                isLoading = false
                showingSuccess = true
                HapticFeedback.success()
                
                // Mostrar éxito inmediatamente
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showSuccessAnimation()
                }
            }
        }
    }
    
    private func checkGoalMilestones(progress: Double) async {
        guard let targetWeight = weightManager.userSettings?.targetWeight else { return }
        
        await notificationManager.scheduleGoalMilestoneNotification(
            progress: progress,
            targetWeight: targetWeight
        )
    }
    
    private func checkGoalCompletion(newWeight: Double) async {
        // Verificar si hay un objetivo activo
        guard let activeGoal = await weightManager.getActiveGoal() else { return }
        
        // Calcular el progreso del objetivo con el nuevo peso
        let progress = weightManager.calculateGoalProgress(for: activeGoal, currentWeight: newWeight)
        
        // Si el progreso es 100% o más y no se ha enviado la notificación
        if progress >= 1.0 && !activeGoal.notificationSent {
            // Marcar que se envió la notificación
            await weightManager.markGoalNotificationSent(activeGoal)
            
            // Enviar notificación push de objetivo completado
            await NotificationManager.shared.sendGoalCompletedNotification(for: activeGoal)
            
            // Completar el objetivo
            await weightManager.completeGoal(activeGoal)
            
            // Notificar que el objetivo fue actualizado
            await MainActor.run {
                NotificationCenter.default.post(name: .goalUpdated, object: nil)
            }
        }
    }
    
    private func showSuccessAnimation() {
        showingSuccessAnimation = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showingSuccessAnimation = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismissView()
            }
        }
    }
    
    private func dismissView() {
        isWeightFieldFocused = false
        isPresented = false
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.teal)
                .frame(width: 20)
            
            Text(text)
                .font(.callout)
                .foregroundColor(.primary)
                .minimumScaleFactor(0.9)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
