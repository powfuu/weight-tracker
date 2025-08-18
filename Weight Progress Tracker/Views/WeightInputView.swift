//
//  WeightInputView.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import SwiftUI
import Combine

struct WeightInputView: View {
    @Binding var isPresented: Bool
    @StateObject private var weightManager = WeightDataManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    @State private var weightInput = ""
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var isLoading = false
    @State private var showingSuccessAnimation = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingSuccess = false
    @State private var buttonScale: CGFloat = 1.0
    
    // Animación “pop” del input
    @State private var inputScale: CGFloat = 1.0
    @State private var previousWeightInput: String = ""
    
    @FocusState private var isWeightFieldFocused: Bool
    
    private var preferredUnit: String {
        weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
    }
    
    private var isValidWeight: Bool {
        guard let weight = Double(weightInput.replacingOccurrences(of: ",", with: ".")),
              weight > 0 else { return false }
        
        // Validación de rangos razonables
        if preferredUnit == WeightUnit.kilograms.rawValue {
            return weight >= 20 && weight <= 300
        } else {
            return weight >= 44 && weight <= 660 // lbs
        }
    }
    
    private var weightValue: Double? {
        guard isValidWeight else { return nil }
        return Double(weightInput.replacingOccurrences(of: ",", with: "."))
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
            .background(Color(.systemBackground))
            .navigationTitle("Registrar Peso")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .accessibilityAddTraits(.isHeader)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismissView()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .onAppear {
            setupInitialState()
        }
        // Animación de “pop” cuando cambia el texto del input
        .onChange(of: weightInput) { newValue in
            let inserting = newValue.count > previousWeightInput.count
            let peak: CGFloat = inserting ? 1.16 : 1.08
            withAnimation(.spring(response: 0.18, dampingFraction: 0.6)) {
                inputScale = peak
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                    inputScale = 1.0
                }
            }
            previousWeightInput = newValue
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                showingError = false
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
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
                
                Text("Registrar Peso")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
            }
            
            Text("Ingresa tu peso actual para continuar con tu seguimiento")
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
                TextField("0.0", text: $weightInput)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 24)
                    .accessibilityLabel("Campo de peso")
                    .accessibilityHint("Ingresa tu peso en \(preferredUnit)")
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isValidWeight ? Color.teal : Color(.systemGray4), lineWidth: 2)
                            .animation(.easeInOut(duration: 0.3), value: isValidWeight)
                    )
                    // 👇 Efecto de “pop/zoom” al escribir
                    .scaleEffect(inputScale)
                    .focused($isWeightFieldFocused)
                
                VStack(spacing: 4) {
                    Text(preferredUnit)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.teal)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    Text("unidad")
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
                    
                    Text("Ingresa un peso válido (\(preferredUnit == WeightUnit.kilograms.rawValue ? "20-300 kg" : "44-660 lbs"))")
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
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
                    
                    Text("Fecha del registro")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                        .accessibilityAddTraits(.isHeader)
                }
                
                Spacer()
                
                if !Calendar.current.isDateInToday(selectedDate) {
                    Button("Hoy") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDate = Date()
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.teal)
                    .accessibilityLabel("Seleccionar fecha de hoy")
                    .accessibilityHint("Cambia la fecha del registro a hoy")
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
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingDatePicker.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    Text(selectedDate, style: .date)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Image(systemName: showingDatePicker ? "chevron.up" : "chevron.down")
                        .foregroundColor(.teal)
                        .font(.caption)
                        .rotationEffect(.degrees(showingDatePicker ? 180 : 0))
                        .animation(.easeInOut(duration: 0.3), value: showingDatePicker)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
            
            if showingDatePicker {
                DatePicker(
                    "Seleccionar fecha",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .transition(
                    AnyTransition.opacity
                        .combined(with: AnyTransition.scale(scale: 0.95))
                )

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
                
                Text("Consejos para un mejor registro")
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
                    text: "Pésate siempre a la misma hora del día"
                )
                
                InfoRow(
                    icon: "drop",
                    text: "Preferiblemente en ayunas por la mañana"
                )
                
                InfoRow(
                    icon: "tshirt",
                    text: "Usa la menor cantidad de ropa posible"
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
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
                    
                    Text(isLoading ? "Guardando..." : "Guardar Peso")
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
                        .shadow(
                            color: isValidWeight ? Color.teal.opacity(0.3) : Color.clear,
                            radius: isValidWeight ? 8 : 0,
                            x: 0,
                            y: isValidWeight ? 4 : 0
                        )
                )
                .animation(.easeInOut(duration: 0.3), value: isValidWeight)
            }
            .disabled(!isValidWeight || isLoading)
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(isLoading ? "Guardando peso" : "Guardar peso")
            .accessibilityHint("Guarda el peso ingresado en tu registro")
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
                    .scaleEffect(showingSuccessAnimation ? 1.0 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showingSuccessAnimation)
                
                Text("¡Peso guardado!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text("Tu progreso ha sido actualizado")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.9)
                    .lineLimit(2)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            )
            .scaleEffect(showingSuccessAnimation ? 1.0 : 0.8)
            .opacity(showingSuccessAnimation ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingSuccessAnimation)
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupInitialState() {
        isWeightFieldFocused = true
        
        // Pre-llenar con el último peso si existe
        if let lastEntry = weightManager.getLatestWeightEntry() {
            let displayWeight = weightManager.getDisplayWeight(lastEntry.weight, in: preferredUnit)
            weightInput = String(format: "%.1f", displayWeight)
            previousWeightInput = weightInput
        }
    }
    
    private func saveWeight() {
        guard let weight = weightValue else {
            HapticFeedback.error()
            return
        }
        
        isLoading = true
        isWeightFieldFocused = false
        HapticFeedback.medium()
        
        Task {
            do {
                // Convertir a kg si es necesario
                let weightInKg = preferredUnit == WeightUnit.kilograms.rawValue ? weight : weight * 0.453592
                
                // Guardar en Core Data
                await weightManager.addWeightEntry(
                    weight: weightInKg,
                    timestamp: selectedDate
                )
                
                // Verificar progreso del objetivo
                if let progress = weightManager.getGoalProgress() {
                    await checkGoalMilestones(progress: progress)
                }
                
                await MainActor.run {
                    isLoading = false
                    showingSuccess = true
                    HapticFeedback.success()
                    
                    // Mostrar éxito inmediatamente
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showSuccessAnimation()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error: \(error.localizedDescription)"
                    showingError = true
                    isLoading = false
                    HapticFeedback.error()
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
    
    private func showSuccessAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showingSuccessAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingSuccessAnimation = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismissView()
            }
        }
    }
    
    private func dismissView() {
        isWeightFieldFocused = false
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
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
