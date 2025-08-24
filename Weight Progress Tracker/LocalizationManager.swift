//
//  LocalizationManager.swift
//  Weight Progress Tracker
//
//  Created by Weight Progress Tracker on 2024.
//

import Foundation
import SwiftUI
import CoreData

// MARK: - Supported Languages
enum SupportedLanguage: String, CaseIterable {
    case english = "en-US"
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"
    case japanese = "ja"
    case korean = "ko"
    case spanish = "es-ES"
    case german = "de-DE"
    case french = "fr-FR"
    
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .chineseSimplified:
            return "简体中文"
        case .chineseTraditional:
            return "繁體中文"
        case .japanese:
            return "日本語"
        case .korean:
            return "한국어"
        case .spanish:
            return "Español"
        case .german:
            return "Deutsch"
        case .french:
            return "Français"
        }
    }
    
    var flag: String {
        switch self {
        case .english:
            return "🇺🇸"
        case .chineseSimplified:
            return "🇨🇳"
        case .chineseTraditional:
            return "🇹🇼"
        case .japanese:
            return "🇯🇵"
        case .korean:
            return "🇰🇷"
        case .spanish:
            return "🇪🇸"
        case .german:
            return "🇩🇪"
        case .french:
            return "🇫🇷"
        }
    }
    
    var locale: Locale {
        return Locale(identifier: self.rawValue)
    }
}

// MARK: - Translation Cache
class TranslationCache {
    private var cache: [String: [String: String]] = [:]
    private let queue = DispatchQueue(label: "translation.cache", attributes: .concurrent)
    
    func setTranslations(_ translations: [String: String], for language: String) {
        queue.async(flags: .barrier) {
            self.cache[language] = translations
        }
    }
    
    func getTranslation(for key: String, language: String) -> String? {
        return queue.sync {
            return cache[language]?[key]
        }
    }
    
    func hasLanguage(_ language: String) -> Bool {
        return queue.sync {
            return cache[language] != nil
        }
    }
    
    func clearCache() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
}

// MARK: - Strings File Parser
class StringsFileParser {
    static func parseStringsFile(at path: String) -> [String: String]? {
        guard FileManager.default.fileExists(atPath: path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            
            // Primero verificar si es un archivo binario plist
            if let binaryTranslations = parseBinaryPlistFile(data: data) {
                return binaryTranslations
            }
            
            // Si no es binario, intentar como archivo de texto
            return parseTextStringsFile(data: data)
            
        } catch {
            return nil
        }
    }
    
    private static func parseBinaryPlistFile(data: Data) -> [String: String]? {
        // Verificar si es un archivo plist binario
        if data.count > 6 {
            let header = data.prefix(6)
            let headerString = String(data: header, encoding: .ascii) ?? ""
            if headerString.hasPrefix("bplist") {
                do {
                    let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
                    if let dict = plist as? [String: String] {
                        return dict
                    }
                } catch {
                    // Error parseando plist binario
                }
            }
        }
        
        return nil
    }
    
    private static func parseTextStringsFile(data: Data) -> [String: String]? {
        // Intentar diferentes codificaciones en orden de prioridad
        let encodings: [String.Encoding] = [
            .utf8,
            .utf16,
            .utf16LittleEndian,
            .utf16BigEndian,
            .ascii,
            .isoLatin1
        ]
        
        var content: String?
        var usedEncoding: String.Encoding?
        
        for encoding in encodings {
            if let decodedContent = String(data: data, encoding: encoding) {
                content = decodedContent
                usedEncoding = encoding
                break
            }
        }
        
        guard let fileContent = content else {
            return nil
        }
        
        return parseStringContent(fileContent)
    }
    
    private static func parseStringContent(_ content: String) -> [String: String] {
        var translations: [String: String] = [:]
        
        // Dividir en líneas y procesar cada una
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Ignorar líneas vacías y comentarios
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("//") || trimmedLine.hasPrefix("/*") || trimmedLine.hasPrefix("*") {
                continue
            }
            
            // Buscar patrón: "key" = "value";
            if let match = parseStringLine(trimmedLine) {
                translations[match.key] = match.value
            }
        }
        
        return translations
    }
    
    private static func parseStringLine(_ line: String) -> (key: String, value: String)? {
        // Patrón regex para "key" = "value"; (con o sin punto y coma al final)
        let pattern = #""([^"]*)"\s*=\s*"([^"]*)"[;]?\s*$"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: line.utf16.count)
            
            if let match = regex.firstMatch(in: line, options: [], range: range) {
                let keyRange = Range(match.range(at: 1), in: line)
                let valueRange = Range(match.range(at: 2), in: line)
                
                if let keyRange = keyRange, let valueRange = valueRange {
                    let key = String(line[keyRange])
                    let value = String(line[valueRange])
                    return (key: key, value: value)
                }
            }
        } catch {
            // Error en regex
        }
        
        return nil
    }
}

// MARK: - Localization Manager
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: SupportedLanguage {
        didSet {
            loadTranslationsForCurrentLanguage()
            // Solo guardar si no estamos en inicialización
            if isInitialized {
                saveLanguageToUserSettings()
            }
        }
    }
    
    private var isInitialized = false
    private let translationCache = TranslationCache()
    private var persistenceController: PersistenceController? {
        // Acceso lazy para evitar inicialización circular
        return PersistenceController.shared
    }
    
    private init() {
        // Inicializar con inglés por defecto sin acceder a Core Data
        self.currentLanguage = .english
        loadTranslationsForCurrentLanguage()
    }
    
    private func loadLanguageFromUserSettings() -> SupportedLanguage {
        // Evitar deadlocks usando solo el contexto directamente
        guard let persistenceController = persistenceController else {
            return .english
        }
        let context = persistenceController.container.viewContext
        
        do {
            let userSettings = try UserSettings.current(in: context)
            if let languageCode = userSettings.preferredLanguage,
               let language = SupportedLanguage(rawValue: languageCode) {
                return language
            }
        } catch {
            // Error loading language, use default
        }
        return .english
    }
    
    @MainActor
    private func loadLanguageFromUserSettingsAsync() async {
        do {
            // Usar un contexto de background para evitar bloqueos
            guard let persistenceController = persistenceController else {
                return
            }
            let context = persistenceController.container.newBackgroundContext()
            
            let savedLanguage = try await context.perform {
                let userSettings = try UserSettings.current(in: context)
                if let languageCode = userSettings.preferredLanguage,
                   let language = SupportedLanguage(rawValue: languageCode) {
                    return language
                }
                return SupportedLanguage.english
            }
            
            // Solo actualizar si el idioma es diferente al actual
            if savedLanguage != currentLanguage {
                currentLanguage = savedLanguage
            }
            
        } catch {
            // Error loading language async
        }
    }
    
    private func saveLanguageToUserSettings() {
        DispatchQueue.main.async {
            guard let persistenceController = self.persistenceController else {
                return
            }
            let context = persistenceController.container.viewContext
            
            do {
                let userSettings = try UserSettings.current(in: context)
                userSettings.setLanguage(self.currentLanguage.rawValue)
                try context.save()
            } catch {
                // Error saving language
            }
        }
    }
    
    private func loadTranslationsForCurrentLanguage() {
        let languageCode = currentLanguage.rawValue
        
        // Verificar si ya tenemos las traducciones en cache
        if translationCache.hasLanguage(languageCode) {
            return
        }
        
        // Buscar el archivo Localizable.strings para el idioma actual
        guard let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj") else {
            loadFallbackTranslations()
            return
        }
        
        let stringsPath = "\(path)/Localizable.strings"
        
        // Verificar si el archivo existe
        if !FileManager.default.fileExists(atPath: stringsPath) {
            loadFallbackTranslations()
            return
        }
        
        // Parsear el archivo y cargar las traducciones
        
        if let translations = StringsFileParser.parseStringsFile(at: stringsPath) {
            translationCache.setTranslations(translations, for: languageCode)
        } else {
            loadFallbackTranslations()
        }
    }
    
    private func loadFallbackTranslations() {
        // Cargar inglés como fallback si el idioma actual falla
        if currentLanguage != .english {
            let englishPath = Bundle.main.path(forResource: SupportedLanguage.english.rawValue, ofType: "lproj")
            if let path = englishPath {
                let stringsPath = "\(path)/Localizable.strings"
                if let translations = StringsFileParser.parseStringsFile(at: stringsPath) {
                    translationCache.setTranslations(translations, for: SupportedLanguage.english.rawValue)
                }
            }
        }
    }
    
    func localizedString(for key: String, comment: String = "") -> String {
        let languageCode = currentLanguage.rawValue
        
        // Buscar en el cache primero
        if let translation = translationCache.getTranslation(for: key, language: languageCode) {
            return translation
        }
        
        // Si no se encuentra, intentar cargar las traducciones si no están cargadas
        if !translationCache.hasLanguage(languageCode) {
            loadTranslationsForCurrentLanguage()
            
            // Intentar de nuevo después de cargar
            if let translation = translationCache.getTranslation(for: key, language: languageCode) {
                return translation
            }
        }
        
        // Fallback a inglés si no se encuentra en el idioma actual
        if currentLanguage != .english {
            if let englishTranslation = translationCache.getTranslation(for: key, language: SupportedLanguage.english.rawValue) {
                return englishTranslation
            }
            
            // Si no tenemos inglés cargado, intentar cargarlo
            if !translationCache.hasLanguage(SupportedLanguage.english.rawValue) {
                loadFallbackTranslations()
                if let englishTranslation = translationCache.getTranslation(for: key, language: SupportedLanguage.english.rawValue) {
                    return englishTranslation
                }
            }
        }
        
        // Clave no encontrada en ningún idioma - devolver la clave como último recurso
        return key
    }
    
    // MARK: - Public Methods
    
    // Debug methods
    func getBundlePath() -> String {
        return Bundle.main.bundlePath
    }
    
    func getBundleIdentifier() -> String? {
        return Bundle.main.bundleIdentifier
    }
    
    func getLocalizableStringsPath() -> String? {
        return Bundle.main.path(forResource: "Localizable", ofType: "strings")
    }
    
    func setLanguage(_ language: SupportedLanguage) {
        currentLanguage = language
        
        // Limpiar cache para forzar recarga
        translationCache.clearCache()
        loadTranslationsForCurrentLanguage()
        saveLanguageToUserSettings()
        
        // Notificar a las vistas que el idioma ha cambiado
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func initializeWithUserSettings() {
        // Cargar el idioma guardado de forma síncrona durante la inicialización
        let savedLanguage = loadLanguageFromUserSettings()
        isInitialized = true
        currentLanguage = savedLanguage
        
        // Cargar las traducciones para el idioma actual
        loadTranslationsForCurrentLanguage()
    }
    
    func initializeWithDefaultLanguage() {
        isInitialized = true
        currentLanguage = .english
        loadTranslationsForCurrentLanguage()
    }
}

// MARK: - Localization Keys
public struct LocalizationKeys {
    // MARK: - Welcome & Onboarding
    static let welcome = "welcome"
    static let getStarted = "get_started"
    static let welcomeSubtitle = "welcome_subtitle"
    static let welcomeMessage = "welcome_message"
    static let setupProfileMessage = "setup_profile_message"
    static let getStartedButton = "get_started_button"
    static let weightProgressTitle = "weight_progress_title"
    static let language = "language"
    static let selectLanguageDesc = "select_language_desc"
    static let chooseLanguage = "choose_language"
    static let next = "next"
    static let back = "back"
    static let finish = "finish"
    static let period = "period"
    static let skip = "skip"
    
    // MARK: - Breadcrumbs
    static let home = "home"
    static let progress = "progress"
    static let initialSteps = "initial_steps"
    
    // MARK: - Onboarding Steps
    static let stepLanguage = "step_language"
    static let stepWeight = "step_weight"
    static let stepUnits = "step_units"
    static let stepNotifications = "step_notifications"
    static let stepGoal = "step_goal"
    
    // MARK: - Goal Setup
    static let goalSetup = "goal_setup"
    static let goalSetupDesc = "goal_setup_desc"
    static let goalTypeLose = "goal_type_lose"
    static let goalTypeGain = "goal_type_gain"
    static let goalTypeMaintain = "goal_type_maintain"
    
    static let skipForNow = "skip_for_now"
    
    // MARK: - Validation Messages
    static let invalidWeightData = "invalid_weight_data"
    static let invalidWeightDataDesc = "invalid_weight_data_desc"
    static let emptyWeightField = "empty_weight_field"
    static let emptyWeightFieldDesc = "empty_weight_field_desc"
    static let invalidGoalWeight = "invalid_goal_weight"
    static let invalidGoalWeightDesc = "invalid_goal_weight_desc"
    static let emptyGoalField = "empty_goal_field"
    static let emptyGoalFieldDesc = "empty_goal_field_desc"
    static let weightOutOfRange = "weight_out_of_range"
    static let weightOutOfRangeDesc = "weight_out_of_range_desc"
    static let validationError = "validation_error"
    static let ok = "ok"
    
    static let languageSelection = "language_selection"
    static let languageSelectionDesc = "language_selection_desc"
    
    static let firstWeight = "first_weight"
    static let firstWeightDesc = "first_weight_desc"
    static let enterWeight = "enter_weight"
    
    static let weightUnits = "weight_units"
    static let weightUnitsDesc = "weight_units_desc"
    static let kilograms = "kilograms"
    static let pounds = "pounds"
    
    static let notifications = "notifications"
    static let notificationsDesc = "notifications_desc"
    static let enableNotifications = "enable_notifications"
    static let notificationTime = "notification_time"
    
    // MARK: - Main App
    static let weightProgress = "weight_progress"
    static let currentWeight = "current_weight"
    static let goalWeight = "goal_weight"
    static let addWeight = "add_weight"
    static let editWeight = "edit_weight"
    static let deleteWeight = "delete_weight"
    
    // MARK: - Insights
    static let insights = "insights"
    static let weeklyProgress = "weekly_progress"
    static let monthlyProgress = "monthly_progress"
    static let streak = "streak"
    static let days = "days"
    static let weeks = "weeks"
    static let months = "months"
    static let year = "year"
    static let avg = "avg"
    static let min = "min"
    static let max = "max"
    static let selectUnit = "select_unit"
    static let selectUnitDesc = "select_unit_desc"
    static let kg = "kg"
    static let lb = "lb"
    static let kgDesc = "kg_desc"
    static let lbDesc = "lb_desc"
    
    // MARK: - Weight Unit Symbols (for localized display)
    static let kgSymbol = "kg_symbol"
    static let lbSymbol = "lb_symbol"
    
    // MARK: - Notifications
    static let goal25Completed = "goal_25_completed"
    static let goal25CompletedDesc = "goal_25_completed_desc"
    static let goal50Completed = "goal_50_completed"
    static let goal50CompletedDesc = "goal_50_completed_desc"
    static let goal75Completed = "goal_75_completed"
    static let goal75CompletedDesc = "goal_75_completed_desc"
    static let goalCompleted = "goal_completed"
    static let goalCompletedDesc = "goal_completed_desc"
    static let goalCompletedNotificationTitle = "goal_completed_notification_title"
    static let goalCompletedNotificationBody = "goal_completed_notification_body"
    static let streak3Days = "streak_3_days"
    static let streak3DaysDesc = "streak_3_days_desc"
    static let streak7Days = "streak_7_days"
    static let streak7DaysDesc = "streak_7_days_desc"
    static let streak14Days = "streak_14_days"
    static let streak14DaysDesc = "streak_14_days_desc"
    static let streak30Days = "streak_30_days"
    static let streak30DaysDesc = "streak_30_days_desc"
    static let streak60Days = "streak_60_days"
    static let streak60DaysDesc = "streak_60_days_desc"
    static let streak90Days = "streak_90_days"
    static let streak90DaysDesc = "streak_90_days_desc"
    static let keepGoing = "keep_going"
    static let keepGoingDesc = "keep_going_desc"
    static let weeklyProgressTitle = "weekly_progress_title"
    static let timeToWeighIn = "time_to_weigh_in"
    static let timeToWeighInDesc = "time_to_weigh_in_desc"
    static let weeklyProgressDesc = "weekly_progress_desc"
    static let logWeight = "log_weight"
    static let remindIn1Hour = "remind_in_1_hour"
    static let viewProgress = "view_progress"
    static let viewStats = "view_stats"
    static let viewCharts = "view_charts"
    static let weightReminder = "weight_reminder"
    static let weightReminderDesc = "weight_reminder_desc"
    
    // MARK: - Notification Setup
    static let notificationDailyReminder = "notification_daily_reminder"
    static let notificationImportantInfo = "notification_important_info"
    static let notificationHabitHelp = "notification_habit_help"
    static let notificationPermissionTitle = "notification_permission_title"
    static let notificationPermissionMessage = "notification_permission_message"
    
    // Privacy Policy
    static let privacyPolicy = "privacy_policy"
    static let close = "close"
    static let privacyImportant = "privacy_important"
    static let dataCollection = "data_collection"
    static let dataCollectionDesc = "data_collection_desc"
    static let lastUpdated = "last_updated"
    static let dataUsage = "data_usage"
    static let dataUsageDesc = "data_usage_desc"
    static let dataStorage = "data_storage"
    static let dataStorageDesc = "data_storage_desc"
    static let dataExport = "data_export"
    static let dataExportDesc = "data_export_desc"
    static let dataDeletion = "data_deletion"
    static let dataDeletionDesc = "data_deletion_desc"
    static let contact = "contact"
    static let contactDesc = "contact_desc"
    
    // MARK: - Terms of Use
    static let termsOfUse = "terms_of_use"
    static let termsAndConditions = "terms_and_conditions"
    static let acceptanceOfTerms = "acceptance_of_terms"
    static let acceptanceOfTermsDesc = "acceptance_of_terms_desc"
    static let appUsage = "app_usage"
    static let appUsageDesc = "app_usage_desc"
    static let userResponsibility = "user_responsibility"
    static let userResponsibilityDesc = "user_responsibility_desc"
    static let limitationsOfLiability = "limitations_of_liability"
    static let limitationsOfLiabilityDesc = "limitations_of_liability_desc"
    static let medicalAdvice = "medical_advice"
    static let medicalAdviceDesc = "medical_advice_desc"
    static let intellectualProperty = "intellectual_property"
    static let intellectualPropertyDesc = "intellectual_property_desc"
    static let modifications = "modifications"
    static let modificationsDesc = "modifications_desc"
    static let termination = "termination"
    static let terminationDesc = "termination_desc"
    
    // MARK: - Loading
    static let loading = "loading"
    static let appTitle = "app_title"
    static let weightProgressTracker = "weight_progress_tracker"
    
    // MARK: - Achievements
    static let achievements = "achievements"
    static let achievementsAndStats = "achievements_and_stats"
    static let statistics = "statistics"
    static let startJourney = "start_journey"
    static let startJourneyDesc = "start_journey_desc"
    static let currentStreak = "current_streak"
    static let consecutiveDays = "consecutive_days"
    static let motivationalStats = "motivational_stats"
    static let overallProgress = "overall_progress"
    static let unlocked = "unlocked"
    static let unlockedAchievements = "unlocked_achievements"
    static let best = "best"
    static let completed = "completed"
    static let todayCompleted = "today_completed"
    static let logToday = "log_today"
    
    // MARK: - Achievement Types
    static let achievementFirstEntry = "achievement_first_entry"
    static let achievementWeekStreak = "achievement_week_streak"
    static let achievementMonthStreak = "achievement_month_streak"
    static let achievementWeightLoss5kg = "achievement_weight_loss_5kg"
    static let achievementWeightLoss10kg = "achievement_weight_loss_10kg"
    static let achievementConsistentLogger = "achievement_consistent_logger"
    static let achievementGoalAchiever = "achievement_goal_achiever"
    static let achievementDataExplorer = "achievement_data_explorer"
    
    // MARK: - Achievement Descriptions
    static let achievementFirstEntryDesc = "achievement_first_entry_desc"
    static let achievementWeekStreakDesc = "achievement_week_streak_desc"
    static let achievementMonthStreakDesc = "achievement_month_streak_desc"
    static let achievementWeightLoss5kgDesc = "achievement_weight_loss_5kg_desc"
    static let achievementWeightLoss10kgDesc = "achievement_weight_loss_10kg_desc"
    static let achievementConsistentLoggerDesc = "achievement_consistent_logger_desc"
    static let achievementGoalAchieverDesc = "achievement_goal_achiever_desc"
    static let achievementDataExplorerDesc = "achievement_data_explorer_desc"
    
    // MARK: - Motivational Messages
    static let streakStartToday = "streak_start_today"
    static let streakGoodWay = "streak_good_way"
    static let streakIncredible = "streak_incredible"
    static let streakUnstoppable = "streak_unstoppable"
    
    // MARK: - Motivational Stats
    static let currentStreakTitle = "current_streak_title"
    static let consecutiveDaysSubtitle = "consecutive_days_subtitle"
    static let bestStreakTitle = "best_streak_title"
    static let maxDaysSubtitle = "max_days_subtitle"
    static let achievementsTitle = "achievements_title"
    static let achievementsOfTotal = "achievements_of_total"
    
    // MARK: - Theme
    static let theme = "theme"
    static let dark = "dark"
    
    // MARK: - Settings
    static let configuration = "configuration"
    static let units = "units"
    static let weightUnit = "weight_unit"
    static let dailyReminders = "daily_reminders"
    static let dailyRemindersDesc = "daily_reminders_desc"
    static let reminderTime = "reminder_time"
    static let reminderInfo = "reminder_info"
    static let data = "data"
    static let deleteAllData = "delete_all_data"
    static let deleteAllDataDesc = "delete_all_data_desc"
    static let information = "information"
    static let version = "version"
    static let deleteData = "delete_data"
    static let deleteDataConfirm = "delete_data_confirm"
    static let error = "error"
    static let notificationPermissionError = "notification_permission_error"
    static let deleteDataError = "delete_data_error"
    
    // MARK: - Weight Entry
    static let weight = "weight"
    static let date = "date"
    static let save = "save"
    static let cancel = "cancel"
    static let delete = "delete"
    static let edit = "edit"
    
    // MARK: - Messages
    static let weightSaved = "weight_saved"
    static let weightDeleted = "weight_deleted"
    static let success = "success"
    
    // MARK: - Time Periods
    static let today = "today"
    static let yesterday = "yesterday"
    static let thisWeek = "this_week"
    static let lastWeek = "last_week"
    static let thisMonth = "this_month"
    static let lastMonth = "last_month"
    static let sevenDays = "seven_days"
    static let thirtyDays = "thirty_days"
    static let ninetyDays = "ninety_days"
    static let oneYear = "one_year"
    static let inNinetyDays = "in_ninety_days"
    static let thisYear = "this_year"
    
    // MARK: - Relative Time
    static let noRecordsTime = "no_records_time"
    static let daysAgo = "days_ago"
    static let dayAgo = "day_ago"
    static let hoursAgo = "hours_ago"
    static let lessThanHour = "less_than_hour"
    
    // MARK: - Data Insights
    static let insufficientData = "insufficient_data"
    static let insufficientDataInsights = "insufficient_data_insights"
    static let threeDays = "three_days"
    static let fifteenDays = "fifteen_days"
    static let threeMonths = "three_months"
    static let sixMonths = "six_months"
    static let inFifteenDays = "in_fifteen_days"
    static let inThreeMonths = "in_three_months"
    static let weightStableWeek = "weight_stable_week"
    static let weightStableMonth = "weight_stable_month"
    static let weightStableQuarter = "weight_stable_quarter"
    static let weightStableYear = "weight_stable_year"
    static let consistencyKey = "consistency_key"
    static let excellentProgress = "excellent_progress"
    static let lostWeightWeek = "lost_weight_week"
    static let gainedWeightWeek = "gained_weight_week"
    static let lostWeightMonth = "lost_weight_month"
    static let gainedWeightMonth = "gained_weight_month"
    static let lostWeightQuarter = "lost_weight_quarter"
    static let gainedWeightQuarter = "gained_weight_quarter"
    static let lostWeightYear = "lost_weight_year"
    static let gainedWeightYear = "gained_weight_year"
    static let weeklyAverage = "weekly_average"
    static let monthlyAverage = "monthly_average"
    static let averageWeightMonth = "average_weight_month"
    static let maintainConsistency = "maintain_consistency"
    static let keepFocusGoal = "keep_focus_goal"
    
    // MARK: - Quick Actions
    static let importHealth = "import_health"
    static let importHealthSubtitle = "import_health_subtitle"
    static let exportCSV = "export_csv"
    static let exportCSVSubtitle = "export_csv_subtitle"
    static let editGoalAction = "edit_goal_action"
    static let editGoalSubtitle = "edit_goal_subtitle"
    static let createGoalAction = "create_goal_action"
    static let createGoalSubtitle = "create_goal_subtitle"
    
    // MARK: - Weight Input
    static let weightInputTitle = "weight_input.title"
    static let weightInputSubtitle = "weight_input.subtitle"
    static let fieldLabel = "weight_input.field_label"
    static let fieldHint = "weight_input.field_hint"
    static let quickSelect = "quick_select"
    static let firstWeightInfo = "first_weight_info"
    static let weightInputLoading = "weight_input.loading"
    static let unitLabel = "weight_input.unit_label"
    static let invalidWeight = "weight_input.invalid_weight"
    static let dateLabel = "weight_input.date_label"
    static let todayButton = "weight_input.today_button"
    static let todayAccessibility = "weight_input.today_accessibility"
    static let todayHint = "weight_input.today_hint"
    static let selectDate = "weight_input.select_date"
    static let tipsTitle = "weight_input.tips_title"
    static let tipTime = "weight_input.tip_time"
    static let tipFasting = "weight_input.tip_fasting"
    static let tipClothing = "weight_input.tip_clothing"
    static let saveButton = "weight_input.save_button"
    static let saving = "weight_input.saving"
    static let saveAccessibility = "weight_input.save_accessibility"
    static let savingAccessibility = "weight_input.saving_accessibility"
    static let saveHint = "weight_input.save_hint"
    static let successTitle = "weight_input.success_title"
    static let successMessage = "weight_input.success_message"
    static let errorTitle = "weight_input.error_title"
    static let errorOk = "weight_input.error_ok"
    static let errorPrefix = "weight_input.error_prefix"
    
    // MARK: - MainView Specific
    static let noRecords = "main.no_records"
    static let registerNewWeight = "main.register_new_weight"
    static let registerFirstWeight = "main.register_first_weight"
    static let average = "main.average"
    static let minimum = "main.minimum"
    static let maximum = "main.maximum"
    static let lastUpdate = "main.last_update"
    static let day = "main.day"
    static let change = "main.change"
    static let actions = "main.actions"
    static let recordWeight = "main.log_weight"
    static let viewStatistics = "main.view_statistics"
    static let goals = "main.goals"
    static let settings = "main.settings"
    static let noDataAvailable = "main.no_data"
    static let addMoreEntries = "main.add_more_entries"
    static let weightDecreased = "main.weight_down"
    static let weightIncreased = "main.weight_up"
    static let weightStable = "main.weight_stable_week"
    static let goal = "main.goal"
    static let stayConsistent = "main.stay_consistent"
    
    // MARK: - Goals
    static let defineGoal = "define_goal"
    static let daysRemaining = "days_remaining"
    static let goalProgressTitle = "goal_progress_title"
    static let percentCompleted = "percent_completed"
    static let sinceDate = "since_date"
    static let initialWeight = "initial_weight"
    static let currentWeightTitle = "current_weight_title"
    static let goalTitle = "goal_title"
    static let logMoreWeights = "log_more_weights"
    static let achievementUnlocked = "achievement_unlocked"
    static let great = "great"
    static let loadingProgress = "loading_progress"
    static let preparingData = "preparing_data"
    static let loadingSimple = "loading_simple"
    static let loadingGoalData = "loading_goal_data"
    static let greatExclamation = "great_exclamation"
    static let welcomeCompanion = "welcome_companion"
    static let welcomeToApp = "welcome_to_app"
    static let lastRecord = "last_record"
    static let enterValidWeight = "enter_valid_weight"
    static let duration = "duration"
    static let deleteGoalConfirm = "delete_goal_confirm"
    static let adjustGoal = "adjust_goal"
    static let goalStats = "goal_stats"
    static let goalAction = "goal_action"
    static let targetDate = "target_date"
    static let futureDateRequired = "future_date_required"
    static let increase = "increase"
    static let decrease = "decrease"
    static let extend = "extend"
    static let shorten = "shorten"
    static let deleteGoal = "delete_goal"
    static let goalUpdateError = "goal_update_error"
    static let goalAlreadyDeleted = "goal_already_deleted"
    static let goalDeleteError = "goal_delete_error"
    static let goalCreationError = "goal_creation_error"
    static let goalMotivationText = "goal_motivation_text"
    static let goalType = "goal_type"
    static let targetWeight = "target_weight"
    static let weightPlaceholder = "weight_placeholder"
    static let unit = "unit"
    static let enterValidWeightRange = "enter_valid_weight_range"
    static let enterValidWeightRangeFormat = "enter_valid_weight_range_format"
    static let goalSummary = "goal_summary"
    static let deadline = "deadline"
    static let requiredChange = "required_change"
    static let gain = "gain"
    static let lose = "lose"
    static let weeklyChange = "weekly_change"
    static let creating = "creating"
    static let createGoal = "create_goal"
    
    // MARK: - Edit Goal View
    static let goalInProgress = "goal_in_progress"
    static let currentProgress = "current_progress"
    static let newWeightGoal = "new_weight_goal"
    static let newDateGoal = "new_date_goal"
    static let adjustGoalDesc = "adjust_goal_desc"
    static let goalDeleteConfirmation = "goal_delete_confirmation"
    static let goalAdjustDescription = "goal_adjust_description"
    static let newTargetWeight = "new_target_weight"
    static let percentCompletedShort = "percent_completed_short"
    static let from = "from"
    static let weightDifference = "weight_difference"
    static let increaseObjective = "increase_objective"
    static let reduceObjective = "reduce_objective"
    static let daysElapsed = "days_elapsed"
    static let daysRemainingShort = "days_remaining_short"
    static let weightChange = "weight_change"
    static let savingChanges = "saving_changes"
    static let saveChanges = "save_changes"
    static let of = "of"
    static let week = "week"
    static let validWeightError = "valid_weight_error"
    static let newTargetDate = "new_target_date"
    static let goalDuration = "goal_duration"
    static let goalDateChange = "goal_date_change"
    static let durationDaysWeeks = "duration_days_weeks"
    
    // MARK: - Goals View
    static let defineGoalTitle = "define_goal_title"
    static let defineGoalSubtitle = "define_goal_subtitle"
    static let createObjective = "create_objective"
    static let currentObjective = "current_objective"
    static let currentGoal = "current_goal"
    static let goalTarget = "goal_target"
    static let timeElapsed = "time_elapsed"
    static let remaining = "remaining"
    static let visualProgress = "visual_progress"
    static let recordMoreWeights = "record_more_weights"
    static let editGoal = "edit_goal"
    static let markAsCompleted = "mark_as_completed"
    static let goalTips = "goal_tips"
    static let beRealistic = "be_realistic"
    static let beRealisticDesc = "be_realistic_desc"
    static let adequateTime = "adequate_time"
    static let adequateTimeDesc = "adequate_time_desc"
    static let stayMotivated = "stay_motivated"
    static let stayMotivatedDesc = "stay_motivated_desc"
    static let newGoal = "new_goal"
    
    // MARK: - Charts
    static let progressChart = "progress_chart"
    static let detailedStats = "detailed_stats"
    static let weightRecorded = "weight_recorded"
    static let unknownDate = "unknown_date"
    static let detailedStatistics = "detailed_statistics"
    static let maximumWeight = "maximum_weight"
    static let minimumWeight = "minimum_weight"
    static let totalEntries = "total_entries"
    static let target = "target"
    static let recentEntries = "recent_entries"
    static let noWeightDataAvailable = "no_weight_data_available"
    
    // MARK: - Notification Messages
    static let timeToLogWeight = "time_to_log_weight"
    
    // MARK: - Additional UI Elements
    static let periodExample = "period_example"
    
    // MARK: - Missing Hardcoded Texts
    static let weightTracker = "weight_tracker"
    static let yourWeightCompanion = "your_weight_companion"
    static let welcomeToWeightProgress = "welcome_to_weight_progress"
    static let setupYourProfile = "setup_your_profile"
    static let begin = "begin"
    static let loadingYourProgress = "loading_your_progress"
    static let preparingYourData = "preparing_your_data"
    static let achievementUnlockedExclamation = "achievement_unlocked_exclamation"
    static let greatExclamationMark = "great_exclamation_mark"
    static let keyboardWarmupHidden = "keyboard_warmup_hidden"
    static let lastUpdateLabel = "last_update_label"
    static let settingsButton = "settings_button"
    static let settingsHint = "settings_hint"
    static let recordNewWeight = "record_new_weight"
    static let recordFirstWeight = "record_first_weight"
    
    // MARK: - MicroInteractions
    static let buttonTapped = "button_tapped"
    static let tapMe = "tap_me"
    static let pillButtonTapped = "pill_button_tapped"
    
    // MARK: - Accessibility and UI Text
    static let lastUpdateAccessibility = "last_update_accessibility"
    static let more = "more"
    static let less = "less"
    static let viewDetailedStatistics = "view_detailed_statistics"
    static let tapToOpenStatistics = "tap_to_open_statistics"
    
    // MARK: - Short Time Periods
    static let threeDaysShort = "three_days_short"
    static let sevenDaysShort = "seven_days_short"
    static let fifteenDaysShort = "fifteen_days_short"
    static let thirtyDaysShort = "thirty_days_short"
    static let threeMonthsShort = "three_months_short"
    static let sixMonthsShort = "six_months_short"
    static let oneYearShort = "one_year_short"
    
    // MARK: - Colors
    static let colorGreen = "color_green"
    static let colorRed = "color_red"
    static let colorOrange = "color_orange"
    static let colorBlue = "color_blue"
    static let colorPurple = "color_purple"
    static let colorTeal = "color_teal"
    
    // MARK: - Validation Messages
    static let validationGoalEmpty = "validation_goal_empty"
    static let validationGoalInvalid = "validation_goal_invalid"
    static let validationWeightRange = "validation_weight_range"
}

// MARK: - String Extension for Localization
extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}

// MARK: - NumberFormatter Extension for Localization
extension LocalizationManager {
    /// Retorna un NumberFormatter configurado con el locale actual
    var localizedNumberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = currentLanguage.locale
        return formatter
    }
    
    /// Retorna un NumberFormatter para decimales con el locale actual
    var localizedDecimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = currentLanguage.locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }
    
    /// Retorna un NumberFormatter para porcentajes con el locale actual
    var localizedPercentFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = currentLanguage.locale
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    /// Formatea un peso con el locale actual y una precisión decimal
    func formatWeight(_ weight: Double, precision: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.locale = currentLanguage.locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = precision
        formatter.maximumFractionDigits = precision
        return formatter.string(from: NSNumber(value: weight)) ?? String(format: "%.\(precision)f", weight)
    }
}
