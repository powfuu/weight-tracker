//
//  WelcomeView.swift
//  Weight Progress Tracker
//
//  Created by Weight Progress Tracker on 2024.
//

import SwiftUI
import UserNotifications

struct WelcomeView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.managedObjectContext) private var viewContext
    @State private var currentStep = 0
    @State private var selectedLanguage: SupportedLanguage = .english
    @State private var selectedUnit: WeightUnit = .kilograms
    @State private var currentWeight: String = ""
    @State private var notificationsEnabled = true // Activadas por defecto
    @State private var notificationTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date() // 8 AM por defecto
    @State private var isCompleted = false
    
    // Goal setup states
    @State private var goalType: GoalType = .lose
    @State private var targetWeight: String = ""
    @State private var targetDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    // Removed skipGoal - goal setup is now mandatory
    
    // Animation states
    @State private var showContent = false
    @State private var showTitle = false
    @State private var showDescription = false
    @State private var showLanguageCards = false
    
    // Focus states
    @FocusState private var isGoalInputFocused: Bool
    
    private let totalSteps = 5
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fondo con partículas
                ParticlesView()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header con breadcrumb
                    headerView
                    
                    // Contenido principal
                    ScrollView {
                        VStack(spacing: 30) {
                            // Indicador de progreso
                            progressIndicator
                            
                            // Contenido del paso actual
                            stepContent
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    }
                    .ignoresSafeArea(.keyboard)
                    
                    // Botones de navegación
                    navigationButtons
                }
            }
        }
        .onAppear {
            selectedLanguage = localizationManager.currentLanguage
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Logo
            HStack(spacing: 8) {
                Image(systemName: "figure.walk")
                    .font(.title2)
                    .foregroundColor(.teal)
                
                Text(LocalizationKeys.appTitle.localized)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Breadcrumb
            HStack(spacing: 8) {
                Text(LocalizationKeys.home.localized)
                    .font(.caption)
                    .foregroundColor(.teal)
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.teal.opacity(0.6))
                
                Text(LocalizationKeys.initialSteps.localized)
                    .font(.caption)
                    .foregroundColor(.teal)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 5)
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        VStack(spacing: 16) {
            // Barra de progreso
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.teal : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .scaleEffect(index == currentStep ? 1.1 : 1.0)
                    
                    if index < totalSteps - 1 {
                        Rectangle()
                            .fill(index < currentStep ? Color.teal : Color.gray.opacity(0.3))
                            .frame(height: 2)

                    }
                }
            }
            .padding(.horizontal, 40)
            
            // Título del paso
            Text(stepTitle)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Step Content
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            languageSelectionStep
        case 1:
            weightUnitsStep
        case 2:
            firstWeightStep
        case 3:
            notificationsStep
        case 4:
            goalSetupStep
        default:
            EmptyView()
        }
    }
    
    // MARK: - Language Selection Step
    private var languageSelectionStep: some View {
        VStack(spacing: 20) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(languages.enumerated()), id: \.element) { index, language in
                    LanguageCard(
                        language: language,
                        isSelected: selectedLanguage == language,
                        action: {
                            selectedLanguage = language
                        localizationManager.setLanguage(language)
                        }
                    )
                    .opacity(showLanguageCards ? 1 : 0)
                    .offset(y: showLanguageCards ? 0 : 50)
                    .animation(
                        .easeOut(duration: 0.3)
                        .delay(0.3 + Double(index) * 0.05),
                        value: showLanguageCards
                    )
                }
            }
            .padding(.horizontal)
            
            Spacer(minLength: 20)
        }
        .padding(.top, 20)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 50)
        .animation(.easeOut(duration: 0.4), value: showContent)
        .onAppear {
            // Secuencia de animaciones optimizada
            showContent = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showTitle = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                showDescription = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showLanguageCards = true
            }
        }
    }
    
    // Lista de idiomas para el selector
    private let languages: [SupportedLanguage] = [
        .english,
        .spanish,
        .german,
        .french,
        .chineseSimplified,
        .chineseTraditional,
        .japanese,
        .korean
    ]
    
    // MARK: - Weight Units Step
    private var weightUnitsStep: some View {
        WeightUnitSelector(selectedUnit: $selectedUnit)
    }
    
    // MARK: - First Weight Step
    private var firstWeightStep: some View {
        FirstWeightInput(
            currentWeight: $currentWeight,
            selectedUnit: selectedUnit
        )
    }
    
    // MARK: - Notifications Step
    private var notificationsStep: some View {
        NotificationSetup(
            notificationsEnabled: $notificationsEnabled,
            notificationTime: $notificationTime
        )
    }
    
    // MARK: - Goal Setup Step
    private var goalSetupStep: some View {
        VStack(spacing: 24) {
            goalSetupHeader
            goalSetupContent
        }
        .padding(.horizontal)
    }
    
    private var goalSetupHeader: some View {
        VStack(spacing: 12) {
            Text(LocalizationKeys.goalSetup.localized)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text(LocalizationKeys.goalSetupDesc.localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var goalSetupContent: some View {
        VStack(spacing: 20) {
            goalTypeSelector
            goalWeightInput
            goalDatePicker
            goalSummaryView
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.05))
        )
    }
    
    private var goalTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizationKeys.goalType.localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                ForEach(GoalType.allCases, id: \.self) { type in
                    Button {
                        goalType = type
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: type.icon)
                                .font(.title2)
                                .foregroundColor(goalType == type ? .white : type.color)
                            
                            Text(type.localizedTitle)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(goalType == type ? .white : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(goalType == type ? type.color : Color.gray.opacity(0.1))
                        )
                    }
                }
            }
        }
    }
    
    private var goalWeightInput: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationKeys.targetWeight.localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundColor(.teal)
                
                TextField(
                    LocalizationKeys.weightPlaceholder.localized,
                    text: $targetWeight
                )
                .keyboardType(UIKeyboardType.decimalPad)
                .textInputAutocapitalization(TextInputAutocapitalization.never)
                .autocorrectionDisabled(true)
                .font(Font.system(size: 20, weight: Font.Weight.semibold))
                .multilineTextAlignment(TextAlignment.center)
                .focused($isGoalInputFocused)
                .animation(Animation?.none, value: isGoalInputFocused)
                
                Text(selectedUnit.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.teal)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.teal.opacity(0.1))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.teal.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    private var goalDatePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizationKeys.targetDate.localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                DatePicker("", selection: $targetDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .labelsHidden()
                    .environment(\.locale, localizationManager.currentLanguage.locale)
                    .preferredColorScheme(.dark)
                Spacer()
            }
        }
    }
    
    private var goalSummaryView: some View {
        Group {
            if !targetWeight.isEmpty, let weight = Double(targetWeight), weight > 0 {
                VStack(alignment: .leading, spacing: 12) {
                    Text(LocalizationKeys.goalSummary.localized)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: goalType.icon)
                                .foregroundColor(goalType.color)
                            Text("\(goalType.localizedTitle) \(targetWeight) \(selectedUnit.displayName)")
                                .font(.subheadline)
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text(targetDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                                .environment(\.locale, LocalizationManager.shared.currentLanguage.locale)
                            Spacer()
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    )
                }
            }
        }
    }
    
    // skipGoalButton removed - goal setup is now mandatory
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button(LocalizationKeys.back.localized) {
                    currentStep = max(0, currentStep - 1)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            
            Spacer()
            
            Button(currentStep == totalSteps - 1 ? LocalizationKeys.finish.localized : LocalizationKeys.next.localized) {
                if currentStep == totalSteps - 1 {
                    completeOnboarding()
                } else {
                    currentStep += 1
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canProceed)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 34)
    }
    
    // MARK: - Computed Properties
    private var stepTitle: String {
        switch currentStep {
        case 0: return LocalizationKeys.languageSelection.localized
        case 1: return LocalizationKeys.weightUnits.localized
        case 2: return LocalizationKeys.firstWeight.localized
        case 3: return LocalizationKeys.notifications.localized
        case 4: return LocalizationKeys.stepGoal.localized
        default: return ""
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return true // Idioma siempre seleccionado
        case 1: return true // Unidad siempre seleccionada
        case 2: return !currentWeight.isEmpty && Double(currentWeight) != nil
        case 3: return true // Notificaciones opcionales
        case 4: return !targetWeight.isEmpty && Double(targetWeight) != nil && targetDate > Date() // Objetivo obligatorio
        default: return false
        }
    }
    
    // MARK: - Actions
    private func completeOnboarding() {
        do {
            // Obtener o crear UserSettings
            let userSettings = try UserSettings.current(in: viewContext)
            
            // Guardar configuración en UserSettings
            userSettings.preferredUnit = selectedUnit.rawValue
            userSettings.notificationsEnabled = notificationsEnabled
            if notificationsEnabled {
                userSettings.reminderTime = notificationTime
            }
            
            // Guardar el idioma seleccionado
            userSettings.setLanguage(selectedLanguage.rawValue)
            
            // Marcar onboarding como completado
            userSettings.completeOnboarding()
            
            // Guardar primer peso si se ingresó
            if let weight = Double(currentWeight) {
                saveFirstWeight(weight, unit: selectedUnit)
            }
            
            // Crear objetivo (ahora obligatorio)
            if let targetWeightValue = Double(targetWeight), targetWeightValue > 0 {
                createGoal(targetWeight: targetWeightValue, targetDate: targetDate)
            }
            
            // Guardar cambios en Core Data
            try viewContext.save()
            
            // Configurar notificaciones si están habilitadas
            if notificationsEnabled {
                requestNotificationPermission()
            }
            
            // Notificar que el onboarding se completó
            NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
            
            isCompleted = true
            
        } catch {
            // Error completing onboarding
            // En caso de error, aún notificamos la finalización para no bloquear al usuario
            NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
            isCompleted = true
        }
    }
    
    private func saveFirstWeight(_ weight: Double, unit: WeightUnit) {
        let newEntry = WeightEntry(context: viewContext)
        newEntry.id = UUID()
        newEntry.weight = weight
        newEntry.unit = unit.rawValue
        newEntry.timestamp = Date()
        newEntry.createdAt = Date()
        newEntry.updatedAt = Date()
        
        // No guardamos aquí porque se guarda en completeOnboarding()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                scheduleNotification()
            }
        }
    }
    
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = LocalizationKeys.appTitle.localized
        content.body = LocalizationKeys.timeToLogWeight.localized
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: "weightReminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func createGoal(targetWeight: Double, targetDate: Date) {
        let weightManager = WeightDataManager.shared
        Task {
            await weightManager.createGoal(targetWeight: targetWeight, targetDate: targetDate)
        }
    }
}

// MARK: - Supporting Types
// GoalType is defined in CreateGoalView.swift

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.teal)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(.teal)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.teal.opacity(0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}



#Preview {
    WelcomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
