//
//  SettingsView.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import SwiftUI
import CoreData
import UserNotifications

struct SettingsView: View {
    // MARK: - Preview flag (inyectable)
    private let forPreview: Bool

    // MARK: - Env
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Managers
    @StateObject private var weightManager: WeightDataManager
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared

    // MARK: - State
    @State private var userSettings: UserSettings?
    @State private var isLoading = true
    @State private var showingDeleteAlert = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var settingsAnimationProgress: Double = 0
    @State private var selectedLanguage: SupportedLanguage = .english

    // Temporales UI
    @State private var tempPreferredUnit: WeightUnit = .kilograms

    @State private var tempNotificationsEnabled = false
    @State private var tempReminderTime = Date()
    
    // Modales de política y términos
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfUse = false


    // MARK: - Init
    init(forPreview: Bool = false) {
        self.forPreview = forPreview
        // Usamos un WeightDataManager con el PersistenceController adecuado
        if forPreview {
            _weightManager = StateObject(wrappedValue: WeightDataManager(persistenceController: PersistenceController.preview))
        } else {
            _weightManager = StateObject(wrappedValue: WeightDataManager.shared)
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    loadingView
                } else {
                    settingsContent
                }
            }
            .navigationTitle(LocalizationManager.shared.localizedString(for: LocalizationKeys.configuration))
            .accessibilityAddTraits(.isHeader)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        HapticFeedback.light()
                        saveSettings()
                    } label: {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.title3)
                            .foregroundColor(.teal)
                    }
                    .pressableScale()
                }
            }

            .alert(LocalizationManager.shared.localizedString(for: LocalizationKeys.deleteData), isPresented: $showingDeleteAlert) {
            Button(LocalizationManager.shared.localizedString(for: LocalizationKeys.cancel), role: .cancel) { }
            Button(LocalizationManager.shared.localizedString(for: LocalizationKeys.deleteData), role: .destructive) { deleteAllData() }
        } message: {
            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.deleteDataConfirm))
        }
        .alert(LocalizationManager.shared.localizedString(for: LocalizationKeys.deleteDataError), isPresented: $showingError) {
            Button(LocalizationManager.shared.localizedString(for: LocalizationKeys.ok)) { }
            } message: { Text(errorMessage) }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showingTermsOfUse) {
                TermsOfUseView()
            }

        }
        .onAppear {
            // Sincronizar selectedLanguage con el idioma actual
            selectedLanguage = localizationManager.currentLanguage
            
            // En previews: sembramos datos y mostramos el contenido sin llamadas async
            if forPreview || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                preparePreviewData()
                isLoading = false
                withAnimation(AnimationConstants.smoothEase.delay(0.2)) { settingsAnimationProgress = 1.0 }
                return
            }

            loadSettings()
            withAnimation(AnimationConstants.smoothEase.delay(0.2)) { settingsAnimationProgress = 1.0 }
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        CustomLoader()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Settings Content
    private var settingsContent: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                languageSection.slideInFromLeading(0.1)
                
                unitsSection.slideInFromLeading(0.2)

                // healthKitSection eliminado

                notificationsSection.slideInFromLeading(0.4)

                dataSection.slideInFromLeading(0.6)

                infoSection.slideInFromLeading(0.8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Sections
    private var languageSection: some View {
        SettingsSection(
                title: LocalizationManager.shared.localizedString(for: LocalizationKeys.language),
            icon: "globe",
            color: .blue
        ) {
            NavigationLink(destination: LanguageSelector(selectedLanguage: $selectedLanguage, localizationManager: localizationManager)) {
                HStack {
                    Text(localizationManager.currentLanguage.displayName)
                        .font(.body)
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var unitsSection: some View {
        SettingsSection(title: LocalizationManager.shared.localizedString(for: LocalizationKeys.units), icon: "scalemass.fill", color: .teal) {
                HStack {
                    Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.weightUnit))
                    .font(.body)
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(2)
                
                Spacer()
                
                Picker(LocalizationManager.shared.localizedString(for: LocalizationKeys.weightUnit), selection: $tempPreferredUnit) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.symbol).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .preferredColorScheme(.dark)
                .frame(width: 120)
            }
        }
    }

    // healthKitSection eliminado - funcionalidad de Apple Health removida

    private var notificationsSection: some View {
        SettingsSection(title: LocalizationManager.shared.localizedString(for: LocalizationKeys.notifications), icon: "bell.fill", color: .teal) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.dailyReminders))
                            .font(.body)
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.8)
                            .lineLimit(2)
                        Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.dailyRemindersDesc))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .minimumScaleFactor(0.8)
                            .lineLimit(3)
                    }
                    Spacer()
                    Toggle("", isOn: $tempNotificationsEnabled)
                        .onChange(of: tempNotificationsEnabled) { _ in
                            HapticFeedback.light()
                            if tempNotificationsEnabled { requestNotificationPermission() }
                        }
                }

                if tempNotificationsEnabled {
                    VStack(spacing: 12) {
                        Divider()

                        HStack {
                            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.reminderTime))
                                .font(.body)
                                .foregroundColor(.primary)
                                .minimumScaleFactor(0.8)
                                .lineLimit(2)
                            Spacer()
                            DatePicker("", selection: $tempReminderTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .preferredColorScheme(.dark)
                                .scaleInAnimation(delay: 0.1)
                                .environment(\.locale, localizationManager.currentLanguage.locale)
                        }

                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.teal)
                            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.reminderInfo))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .minimumScaleFactor(0.8)
                                .lineLimit(4)
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var dataSection: some View {
        SettingsSection(title: LocalizationManager.shared.localizedString(for: LocalizationKeys.data), icon: "externaldrive.fill", color: .teal) {
            VStack(spacing: 16) {


                Button {
                    HapticFeedback.medium()
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.deleteAllData))
                                .font(.body)
                                .foregroundColor(.red)
                                .minimumScaleFactor(0.8)
                                .lineLimit(2)
                            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.deleteAllDataDesc))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .minimumScaleFactor(0.8)
                                .lineLimit(3)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var infoSection: some View {
        SettingsSection(title: LocalizationManager.shared.localizedString(for: LocalizationKeys.information), icon: "info.circle.fill", color: .teal) {
            VStack(spacing: 16) {
                HStack {
                    Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.version))
                        .font(.body)
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    Spacer()
                    Text("1.0.0")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }

                Divider()

                Button {
                    HapticFeedback.light()
                    showingPrivacyPolicy = true
                } label: {
                    HStack {
                        Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.privacyPolicy))
                            .font(.body)
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.8)
                            .lineLimit(2)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                Button {
                    HapticFeedback.light()
                    showingTermsOfUse = true
                } label: {
                    HStack {
                        Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.termsOfUse))
                            .font(.body)
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.8)
                            .lineLimit(2)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                

            }
        }
    }

    // MARK: - Helpers
    private func loadSettings() {
        Task {
            // Síncrono en tu manager
            weightManager.loadUserSettings()

            await MainActor.run {
                self.userSettings = weightManager.userSettings
                if let settings = weightManager.userSettings {
                    self.tempPreferredUnit = WeightUnit(rawValue: settings.preferredUnit ?? WeightUnit.kilograms.rawValue) ?? .kilograms
        
                    self.tempNotificationsEnabled = settings.notificationsEnabled
                    if let reminderTime = settings.reminderTime { self.tempReminderTime = reminderTime }
                }
                self.isLoading = false
            }
        }
    }

    private func saveSettings() {
        guard userSettings != nil else { return }

        Task {
            weightManager.updateUserSettings(
                preferredUnit: tempPreferredUnit.rawValue,
                // healthKitEnabled eliminado
                notificationsEnabled: tempNotificationsEnabled,
                reminderTime: tempReminderTime
            )
            if tempNotificationsEnabled {
                await notificationManager.scheduleDailyReminder(at: tempReminderTime)
            } else {
                await notificationManager.cancelDailyReminder()
            }
            await MainActor.run { dismiss() }
        }
    }

    private func requestNotificationPermission() {
        Task {
            let success = await notificationManager.requestAuthorization()
            await MainActor.run {
                if !success {
                    tempNotificationsEnabled = false
                    errorMessage = LocalizationManager.shared.localizedString(for: LocalizationKeys.notificationPermissionError)
                    showingError = true
                }
            }
        }
    }





    private func deleteAllData() {
        HapticFeedback.heavy()
        Task {
            let success = await weightManager.deleteAllData()
            await MainActor.run {
                if success {
                    // Resetear el onboarding para que se muestre de nuevo
                    do {
                        let userSettings = try UserSettings.current(in: PersistenceController.shared.container.viewContext)
                        userSettings.resetOnboarding()
                        try PersistenceController.shared.container.viewContext.save()
                        
                        // Enviar notificación para que la app principal actualice el estado
                        NotificationCenter.default.post(name: .dataDeleted, object: nil)
                    } catch {
                        // Error reseteando onboarding
                    }
                    
                    HapticFeedback.success()
                    dismiss()
                } else {
                    HapticFeedback.error()
                    errorMessage = LocalizationManager.shared.localizedString(for: LocalizationKeys.deleteDataError)
                    showingError = true
                }
            }
        }
    }

    // MARK: - Preview seeding
    private func preparePreviewData() {
        let ctx = PersistenceController.preview.container.viewContext
        let req: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        let existing = (try? ctx.fetch(req)) ?? []
        let settings: UserSettings

        if let first = existing.first {
            settings = first
        } else {
            let s = UserSettings(context: ctx)
            s.id = UUID()
            s.preferredUnit = WeightUnit.kilograms.rawValue
            // s.healthKitEnabled eliminado
            s.notificationsEnabled = true
            s.reminderTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())
            s.createdAt = Date()
            s.updatedAt = Date()
            try? ctx.save()
            settings = s
        }

        self.userSettings = settings
        self.tempPreferredUnit = .kilograms
        // tempHealthKitEnabled eliminado
        self.tempNotificationsEnabled = settings.notificationsEnabled
        self.tempReminderTime = settings.reminderTime ?? Date()
    }
}

// MARK: - Supporting Types
enum WeightUnit: String, CaseIterable {
    case kilograms = "kg"
    case pounds = "lb"

    var symbol: String {
        switch self {
        case .kilograms: return LocalizationManager.shared.localizedString(for: LocalizationKeys.kgSymbol)
        case .pounds: return LocalizationManager.shared.localizedString(for: LocalizationKeys.lbSymbol)
        }
    }
    
    var name: String {
        switch self {
        case .kilograms: return LocalizationManager.shared.localizedString(for: LocalizationKeys.kilograms)
        case .pounds:    return LocalizationManager.shared.localizedString(for: LocalizationKeys.pounds)
        }
    }
}



// MARK: - Section Wrapper
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
}
