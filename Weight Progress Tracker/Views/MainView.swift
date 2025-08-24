//
//  MainView.swift
//  Weight Progress Tracker
//
//  Created by Weight Progress Tracker on 2024.
//

import SwiftUI
import Charts
import CoreData
import Foundation

struct MainView: View, NotificationObserver {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Inicialización paso a paso para identificar el problema
    @StateObject private var weightManager: WeightDataManager = {
        // Inicializando WeightDataManager
        let manager = WeightDataManager.shared
        // WeightDataManager inicializado
        return manager
    }()
    
    @State private var gamificationManager: GamificationManager?
    @State private var notificationManager: NotificationManager?
    @State private var themeManager: ThemeManager?
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    @State private var isLoading = true
    @State private var showingSettings = false
    @State private var showingGoals = false
    @State private var showingCreateGoal = false
    @State private var showingWeightInput = false
    @State private var showingCharts = false
    @State private var selectedPeriod: TimePeriod = .week
    @State private var weeklyChange: Double = 0
    @State private var isPressed = false
    @State private var cardHoverScale: CGFloat = 1.0
    @State private var progressCardHover = false
    @State private var addWeightButtonScale: CGFloat = 1.0
    @State private var goalsButtonScale: CGFloat = 1.0
    @State private var chartCardHover = false
    @State private var currentInsightIndex = 0
    @State private var insightTimer: Timer?
    
    private var currentWeight: Double {
        // Calculando currentWeight
        guard let latestEntry = weightManager.getLatestWeightEntry() else {
            return 0.0
        }
        let unit = weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
        let result = weightManager.getDisplayWeight(latestEntry.weight, in: unit)
        return result
    }
    
    private var weeklyProgress: Double {
        // Calculando weeklyProgress
        let entries = weightManager.getWeightEntries(for: .week)
        guard entries.count >= 2 else {
            return 0
        }
        let latest = entries.first?.weight ?? 0
        let oldest = entries.last?.weight ?? 0
        let change = latest - oldest
        let unit = weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
        let result = weightManager.getDisplayWeight(change, in: unit)
        return result
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Fondo limpio y minimalista
                Color.black
                    .ignoresSafeArea()
                
                // Partículas de fondo modernas
                ParticlesView()
                    .ignoresSafeArea()
                    .opacity(0.6)
                
                if isLoading {
                    LoadingView()
                } else {
                    mainContentView
                }
            }
            .navigationTitle("")
        }
        .onAppear {
            initializeManagersStepByStep()
            loadInitialData()
            startInsightTimer()
            setupNotificationObservers()
        }
        .onDisappear {
            insightTimer?.invalidate()
            removeNotificationObservers()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingGoals) {
            GoalsView()
        }
        .sheet(isPresented: $showingCreateGoal) {
            CreateGoalView()
        }
        .sheet(isPresented: $showingWeightInput) {
            WeightInputView(isPresented: $showingWeightInput)
        }
        .sheet(isPresented: $showingCharts) {
            ChartsView()
        }
    }
    

    
    @ViewBuilder
    private var mainContentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 32) {
                headerSection
                
                if !weightManager.weightEntries.isEmpty {
                    insightsContainer
                }
                
                               currentWeightSection
                
                if weightManager.activeGoal != nil {
                    goalProgressCard
                }
                
                chartSection
                streakContainer
                quickActionsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .ignoresSafeArea(.keyboard)
    }
    
    @ViewBuilder
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 12) {
                    Image("weight_ico_transparent")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 42, height: 42)
                        .foregroundColor(.teal)
                    
                    // Breadcrumb decorativo
                    HStack(spacing: 6) {
                        Text(localizationManager.localizedString(for: LocalizationKeys.home))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.teal)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.teal.opacity(0.6))
                        
                        Text(localizationManager.localizedString(for: LocalizationKeys.progress))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.teal)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.teal.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.teal.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                
                // Subtítulo dinámico
                //                if !weightManager.weightEntries.isEmpty {
                //                    if let latestEntry = weightManager.weightEntries.max(by: {
                //                        // coge la más reciente (maneja timestamp nulo)
                //                        ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast)
                //                    }) {
                //                        let timeSince = getTimeSinceLastEntryText(for: latestEntry)
                //                        let weightText = getFormattedWeightText(for: latestEntry.weight)
                //
                //                        Text("\(timeSince) · \(weightText)")
                //                            .font(.subheadline)
                //                            .foregroundColor(.secondary)
                //                            .accessibilityLabel(String(format: LocalizationManager.shared.localizedString(for: LocalizationKeys.lastUpdateAccessibility), timeSince, weightText))
                //                    } else {
                //                        Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.noRecords))
                //                            .font(.subheadline)
                //                            .foregroundColor(.secondary)
                //                    }
                //                } else {
                //                    Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.noRecords))
                //                        .font(.subheadline)
                //                        .foregroundColor(.secondary)
                //                        .accessibilityLabel(LocalizationManager.shared.localizedString(for: LocalizationKeys.noRecords))
                //                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Botón de configuración
                Button(action: {
                    HapticFeedback.light()
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showingSettings = true
                    }
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.teal)
                        .padding(8)
                        .background(Color.teal.opacity(0.1))
                        .clipShape(Circle())
                }
                .accessibilityLabel(localizationManager.localizedString(for: LocalizationKeys.settingsButton))
                .accessibilityHint(localizationManager.localizedString(for: LocalizationKeys.settingsHint))
            }
        }
    }
    
    // MARK: - Current Weight Section (refactor liviano)
    
    private var currentWeightSection: some View {
        VStack(spacing: 16) {
            headerRow
            statsRow
            lastUpdateRow
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.teal.opacity(0.1))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.teal.opacity(0.3), lineWidth: 1)
        )
        .scaleInAnimation(delay: 0.2)
    }
    
    @ViewBuilder
    private var headerRow: some View {
        HStack(alignment: .center) {
            if let latest = weightManager.getLatestWeightEntry() {
                let unit = weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
                let display = weightManager.getDisplayWeight(latest.weight, in: unit)
                
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(display, specifier: "%.1f")")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundColor(.teal)
                    
                    Text(weightManager.getLocalizedUnitSymbol())
                        .font(.title2)
                        .foregroundColor(.teal)
                    
                    if let change = weightManager.getWeightChange() {
                        WeightChangeIndicator(
                            change: change,
                            isGoalToLose: weightManager.isGoalToLoseWeight(),
                            weightManager: weightManager
                        )
                    }
                }
                
                Spacer()
                addWeightButton(accessibilityKey: localizationManager.localizedString(for: LocalizationKeys.recordNewWeight))
            } else {
                let unit = weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
                
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("--")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundColor(.teal)
                    
                    Text(weightManager.getLocalizedUnitSymbol())
                        .font(.title2)
                        .foregroundColor(.teal)
                }
                
                Spacer()
                addWeightButton(accessibilityKey: localizationManager.localizedString(for: LocalizationKeys.recordFirstWeight))
            }
        }
    }
    
    @ViewBuilder
    private var statsRow: some View {
        if let stats = weightManager.getWeightStatistics(for: selectedPeriod) {
            let unit = weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text(localizationManager.localizedString(for: LocalizationKeys.average))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f %@", stats.avg, weightManager.getLocalizedUnitSymbol()))
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(localizationManager.localizedString(for: LocalizationKeys.minimum))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f %@", stats.min, weightManager.getLocalizedUnitSymbol()))
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(localizationManager.localizedString(for: LocalizationKeys.maximum))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f %@", stats.max, weightManager.getLocalizedUnitSymbol()))
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    @ViewBuilder
    private var lastUpdateRow: some View {
        if let last = weightManager.getWeightEntries(for: .week).first {
            HStack {
                Text(localizationManager.localizedString(for: LocalizationKeys.lastUpdate))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(last.timestamp?.formatted(date: .abbreviated, time: .shortened) ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .environment(\.locale, localizationManager.currentLanguage.locale)
            }
        }
    }
    
    @ViewBuilder
    private func addWeightButton(accessibilityKey: String) -> some View {
        Button(action: {
            HapticFeedback.medium()
            showingWeightInput = true
        }) {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Circle().fill(Color.teal))
                .shadow(color: Color.teal.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .scaleEffect(addWeightButtonScale)
        .accessibilityLabel(localizationManager.localizedString(for: accessibilityKey))
    }
    
    
    @ViewBuilder
    private var insightsContainer: some View {
        let insights = getInformativeInsights()
        
        // Solo mostrar el contenedor si hay insights disponibles
        if !insights.isEmpty && currentInsightIndex < insights.count {
            VStack(spacing: 16) {
                // Contenido del insight en una sola línea
                HStack(spacing: 12) {
                    // Flecha o ícono
                    if !insights[currentInsightIndex].0.isEmpty {
                        Text(insights[currentInsightIndex].0)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(getInsightColor(insights[currentInsightIndex].3))
                    }
                    
                    // Período (ej. "7 días")
                    Text(insights[currentInsightIndex].1)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    // Cambio de peso
                    Text(insights[currentInsightIndex].2)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(getInsightColor(insights[currentInsightIndex].3))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Indicadores de página a la derecha
                    HStack(spacing: 6) {
                        ForEach(0..<insights.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentInsightIndex ? Color.teal : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                                .animation(.easeInOut(duration: 0.3), value: currentInsightIndex)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentInsightIndex)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(getInsightColor(insights[currentInsightIndex].3).opacity(0.15))
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(getInsightColor(insights[currentInsightIndex].3).opacity(0.3), lineWidth: 1)
            )
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        if value.translation.width > threshold {
                            // Deslizar hacia la derecha - insight anterior
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                currentInsightIndex = (currentInsightIndex - 1 + 4) % 4
                            }
                            HapticFeedback.light()
                        } else if value.translation.width < -threshold {
                            // Deslizar hacia la izquierda - insight siguiente
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                currentInsightIndex = (currentInsightIndex + 1) % 4
                            }
                            HapticFeedback.light()
                        }
                    }
            )
            .scaleInAnimation(delay: 0.15)
        }
    }
    
    @ViewBuilder
    private var streakContainer: some View {
        HStack(spacing: 16) {
            StreakInfoView(gamificationManager: gamificationManager)
            
            Spacer()
            
            // Ícono de motivación
            let motivationStreak = weightManager.getCurrentStreak()
            let iconName = motivationStreak >= 7 ? "trophy.fill" : motivationStreak >= 3 ? "star.fill" : "target"
            let iconColor = motivationStreak >= 7 ? Color.yellow : motivationStreak >= 3 ? Color.orange : Color.white
            let backgroundColor = motivationStreak >= 7 ? Color.yellow.opacity(0.2) : motivationStreak >= 3 ? Color.orange.opacity(0.3) : Color.orange.opacity(0.2)
            
            Image(systemName: iconName)
                .font(.title)
                .foregroundColor(iconColor)
                .padding(12)
                .background(
                    Circle()
                        .fill(backgroundColor)
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.15))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .scaleInAnimation(delay: 0.25)
    }
    
    @ViewBuilder
    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.teal)
                
                Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.progress))
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                // Selector de período mejorado
                PeriodSelector(
                    selectedPeriod: $selectedPeriod,
                    onPeriodChange: { period in
                        selectedPeriod = period
                    }
                )
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.change))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    
                    Text(String(format: "%@%.1f %@", weeklyProgress >= 0 ? "+" : "", weeklyProgress, weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(weeklyProgress >= 0 ? .red : .teal)
                        .accessibilityLabel("\(LocalizationManager.shared.localizedString(for: LocalizationKeys.weightChange)): \(String(format: "%@%.1f %@", weeklyProgress >= 0 ? LocalizationManager.shared.localizedString(for: LocalizationKeys.more) : LocalizationManager.shared.localizedString(for: LocalizationKeys.less), abs(weeklyProgress), weightManager.getLocalizedUnitSymbol()))")
                }
                
                Spacer()
                
                PillButton(
                    title: LocalizationManager.shared.localizedString(for: LocalizationKeys.viewDetailedStatistics),
                    icon: "arrow.right",
                    backgroundColor: .teal,
                    foregroundColor: .white
                ) {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        progressCardHover.toggle()
                    }
                    showingCharts = true
                }
                .scaleEffect(progressCardHover ? 1.05 : 1.0)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .scaleInAnimation(delay: 0.6)
    }
    
    @ViewBuilder
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.actions))
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            // Acciones principales
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                // Registrar Peso
                Button(action: {
                    showingWeightInput = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.recordWeight))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.teal)
                    )
                }
                .accessibilityLabel(localizationManager.localizedString(for: LocalizationKeys.recordWeight))
                .accessibilityHint(localizationManager.localizedString(for: LocalizationKeys.recordWeight))
                
                // Ver Estadísticas
                Button(action: {
                    showingCharts = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title2)
                            .foregroundColor(.teal)
                        
                        Text(localizationManager.localizedString(for: LocalizationKeys.viewStatistics))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.teal)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.teal, lineWidth: 2)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.teal.opacity(0.1))
                            )
                    )
                }
                .accessibilityLabel(localizationManager.localizedString(for: LocalizationKeys.viewStatistics))
                .accessibilityHint(localizationManager.localizedString(for: LocalizationKeys.viewStatistics))
                
                // Objetivos
                Button(action: {
                    showingGoals = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "target")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        Text(localizationManager.localizedString(for: LocalizationKeys.goals))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange, lineWidth: 2)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange.opacity(0.1))
                            )
                    )
                }
                .accessibilityLabel(localizationManager.localizedString(for: LocalizationKeys.goals))
                .accessibilityHint(localizationManager.localizedString(for: LocalizationKeys.goals))
                
                // Configuración
                Button(action: {
                    showingSettings = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text(localizationManager.localizedString(for: LocalizationKeys.settings))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray, lineWidth: 2)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                            )
                    )
                }
                .accessibilityLabel(localizationManager.localizedString(for: LocalizationKeys.settings))
                .accessibilityHint(localizationManager.localizedString(for: LocalizationKeys.settings))
            }
            
            
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .scaleInAnimation(delay: 0.4)
    }
    
    @ViewBuilder
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: {
                showingCharts = true
            }) {
                HStack {
                    Text(localizationManager.localizedString(for: LocalizationKeys.weightProgress))
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.teal)
                }
            }
            .accessibilityLabel(localizationManager.localizedString(for: LocalizationKeys.viewDetailedStatistics))
            .accessibilityHint(localizationManager.localizedString(for: LocalizationKeys.tapToOpenStatistics))
            
            let entries = weightManager.getWeightEntries(for: TimePeriod.week)
            let unit = weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
            
            if entries.isEmpty {
                emptyChartView
            } else {
                Chart(entries, id: \.id) { entry in
                    let displayWeight = weightManager.getDisplayWeight(entry.weight, in: unit)
                    
                    // Solo mostrar línea y área si hay más de una entrada
                    if entries.count > 1 {
                        LineMark(
                            x: .value(localizationManager.localizedString(for: LocalizationKeys.date), entry.timestamp ?? Date()),
                            y: .value(localizationManager.localizedString(for: LocalizationKeys.weight), displayWeight)
                        )
                        .foregroundStyle(.teal)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        
                        AreaMark(
                            x: .value(localizationManager.localizedString(for: LocalizationKeys.date), entry.timestamp ?? Date()),
                            y: .value(localizationManager.localizedString(for: LocalizationKeys.weight), displayWeight)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.teal.opacity(0.3), Color.teal.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    
                    // Mostrar círculo verde prominente cuando solo hay una entrada
                    if entries.count == 1 {
                        PointMark(
                            x: .value(localizationManager.localizedString(for: LocalizationKeys.date), entry.timestamp ?? Date()),
                            y: .value(localizationManager.localizedString(for: LocalizationKeys.weight), displayWeight)
                        )
                        .foregroundStyle(.green)
                        .symbol(Circle())
                        .symbolSize(200) // Círculo grande y prominente
                    }
                }
                .frame(height: 120)
                .animation(.easeInOut(duration: 0.8), value: entries)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.07, green: 0.07, blue: 0.07))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .scaleInAnimation(delay: 0.5)
    }
    
    @ViewBuilder
    private var emptyChartView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.title)
                .foregroundColor(.teal.opacity(0.6))
            
            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.noDataAvailable))
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.addMoreEntries))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Methods
    private func getInformativeInsights() -> [(String, String, String, String)] {
        let entries = weightManager.weightEntries
        
        // Si hay menos de 2 entradas, mostrar mensaje de datos insuficientes para todos los períodos
        guard entries.count >= 2 else {
            return [
                ("", localizationManager.localizedString(for: LocalizationKeys.sevenDays), localizationManager.localizedString(for: LocalizationKeys.insufficientDataInsights), "gray"),
                ("", localizationManager.localizedString(for: LocalizationKeys.fifteenDays), localizationManager.localizedString(for: LocalizationKeys.insufficientDataInsights), "gray"),
                ("", localizationManager.localizedString(for: LocalizationKeys.thirtyDays), localizationManager.localizedString(for: LocalizationKeys.insufficientDataInsights), "gray"),
                ("", localizationManager.localizedString(for: LocalizationKeys.threeMonths), localizationManager.localizedString(for: LocalizationKeys.insufficientDataInsights), "gray"),
                ("", localizationManager.localizedString(for: LocalizationKeys.oneYear), localizationManager.localizedString(for: LocalizationKeys.insufficientDataInsights), "gray")
            ]
        }
        
        let sortedEntries = entries.sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
        let currentWeight = sortedEntries.last?.weight ?? 0
        let calendar = Calendar.current
        let now = Date()
        let unit = weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
        
        var insights: [(String, String, String, String)] = []
        
        // Progreso en 7 días
        if let weekAgoDate = calendar.date(byAdding: .day, value: -7, to: now) {
            let weekAgoEntry = sortedEntries.first { entry in
                let entryDate = entry.timestamp ?? Date()
                let daysDifference = abs(calendar.dateComponents([.day], from: entryDate, to: weekAgoDate).day ?? 0)
                return daysDifference <= 3
            }
            
            if let entry = weekAgoEntry {
                let weightChange = currentWeight - entry.weight
                let weightChangeFormatted = String(format: "%.1f", abs(weightChange))
                if weightChange < -0.1 {
                    insights.append(("↓", localizationManager.localizedString(for: LocalizationKeys.sevenDays), "\(localizationManager.localizedString(for: LocalizationKeys.weightDecreased)) \(weightChangeFormatted) \(weightManager.getLocalizedUnitSymbol())", localizationManager.localizedString(for: LocalizationKeys.colorGreen)))
                } else if weightChange > 0.1 {
                    insights.append(("↑", localizationManager.localizedString(for: LocalizationKeys.sevenDays), "\(localizationManager.localizedString(for: LocalizationKeys.weightIncreased)) \(weightChangeFormatted) \(weightManager.getLocalizedUnitSymbol())", localizationManager.localizedString(for: LocalizationKeys.colorRed)))
                } else {
                    insights.append(("", localizationManager.localizedString(for: LocalizationKeys.sevenDays), "\(localizationManager.localizedString(for: LocalizationKeys.weightStable)) \(localizationManager.localizedString(for: LocalizationKeys.thisWeek))", "gray"))
                }
            } else {
                insights.append(("", localizationManager.localizedString(for: LocalizationKeys.sevenDays), localizationManager.localizedString(for: LocalizationKeys.insufficientDataInsights), "gray"))
            }
        } else {
            insights.append(("", localizationManager.localizedString(for: LocalizationKeys.sevenDays), localizationManager.localizedString(for: LocalizationKeys.insufficientDataInsights), "gray"))
        }
        
        // Progreso en 15 días
        if let fifteenDaysAgoDate = calendar.date(byAdding: .day, value: -15, to: now) {
            let fifteenDaysAgoEntry = sortedEntries.first { entry in
                let entryDate = entry.timestamp ?? Date()
                let daysDifference = abs(calendar.dateComponents([.day], from: entryDate, to: fifteenDaysAgoDate).day ?? 0)
                return daysDifference <= 4
            }
            
            if let entry = fifteenDaysAgoEntry {
                let weightChange = currentWeight - entry.weight
                let weightChangeFormatted = String(format: "%.1f", abs(weightChange))
                if weightChange < -0.1 {
                    insights.append(("↓", localizationManager.localizedString(for: LocalizationKeys.fifteenDays), "\(localizationManager.localizedString(for: LocalizationKeys.weightDecreased)) \(weightChangeFormatted) \(weightManager.getLocalizedUnitSymbol())", localizationManager.localizedString(for: LocalizationKeys.colorGreen)))
                } else if weightChange > 0.1 {
                    insights.append(("↑", localizationManager.localizedString(for: LocalizationKeys.fifteenDays), "\(localizationManager.localizedString(for: LocalizationKeys.weightIncreased)) \(weightChangeFormatted) \(weightManager.getLocalizedUnitSymbol())", localizationManager.localizedString(for: LocalizationKeys.colorRed)))
                } else {
                    insights.append(("", localizationManager.localizedString(for: LocalizationKeys.fifteenDays), "\(localizationManager.localizedString(for: LocalizationKeys.weightStable)) \(localizationManager.localizedString(for: LocalizationKeys.inFifteenDays))", "gray"))
                }
            } else {
                insights.append(("", localizationManager.localizedString(for: LocalizationKeys.fifteenDays), localizationManager.localizedString(for: LocalizationKeys.insufficientDataInsights), "gray"))
            }
        } else {
            insights.append(("", localizationManager.localizedString(for: LocalizationKeys.fifteenDays), localizationManager.localizedString(for: LocalizationKeys.insufficientDataInsights), "gray"))
        }
        
        // Progreso en 30 días
        if let monthAgoDate = calendar.date(byAdding: .day, value: -30, to: now) {
            let monthAgoEntry = sortedEntries.first { entry in
                let entryDate = entry.timestamp ?? Date()
                let daysDifference = abs(calendar.dateComponents([.day], from: entryDate, to: monthAgoDate).day ?? 0)
                return daysDifference <= 7
            }
            
            if let entry = monthAgoEntry {
                let weightChange = currentWeight - entry.weight
                let weightChangeFormatted = String(format: "%.1f", abs(weightChange))
                
                if weightChange < -0.1 {
                    insights.append(("↓", localizationManager.localizedString(for: LocalizationKeys.thirtyDays), "\(localizationManager.localizedString(for: LocalizationKeys.weightDecreased)) \(weightChangeFormatted) \(weightManager.getLocalizedUnitSymbol())", localizationManager.localizedString(for: LocalizationKeys.colorGreen)))
                } else if weightChange > 0.1 {
                    insights.append(("↑", localizationManager.localizedString(for: LocalizationKeys.thirtyDays), "\(localizationManager.localizedString(for: LocalizationKeys.weightIncreased)) \(weightChangeFormatted) \(weightManager.getLocalizedUnitSymbol())", localizationManager.localizedString(for: LocalizationKeys.colorRed)))
                } else {
                    insights.append(("", localizationManager.localizedString(for: LocalizationKeys.thirtyDays), "\(localizationManager.localizedString(for: LocalizationKeys.weightStable)) \(localizationManager.localizedString(for: LocalizationKeys.thisMonth))", "gray"))
                }
            } else {
                insights.append(("", localizationManager.localizedString(for: LocalizationKeys.thirtyDays), localizationManager.localizedString(for: LocalizationKeys.insufficientDataInsights), "gray"))
            }
        } else {
            insights.append(("", localizationManager.localizedString(for: LocalizationKeys.thirtyDays), localizationManager.localizedString(for: LocalizationKeys.insufficientDataInsights), "gray"))
        }
        
        // Progreso en 3 meses
        if let threeMonthsAgoDate = calendar.date(byAdding: .month, value: -3, to: now) {
            // Buscar la entrada más cercana a 3 meses atrás
            let threeMonthsAgoEntry = sortedEntries.filter { entry in
                let entryDate = entry.timestamp ?? Date()
                return entryDate <= threeMonthsAgoDate
            }.last // La más reciente que sea anterior a la fecha objetivo
            
            if let entry = threeMonthsAgoEntry {
                let weightChange = currentWeight - entry.weight
                let weightChangeFormatted = String(format: "%.1f", abs(weightChange))
                if weightChange < -0.1 {
                    insights.append(("↓", localizationManager.localizedString(for: LocalizationKeys.threeMonths), "\(localizationManager.localizedString(for: LocalizationKeys.weightDecreased)) \(weightChangeFormatted) \(weightManager.getLocalizedUnitSymbol())", localizationManager.localizedString(for: LocalizationKeys.colorGreen)))
                } else if weightChange > 0.1 {
                    insights.append(("↑", localizationManager.localizedString(for: LocalizationKeys.threeMonths), "\(localizationManager.localizedString(for: LocalizationKeys.weightIncreased)) \(weightChangeFormatted) \(weightManager.getLocalizedUnitSymbol())", localizationManager.localizedString(for: LocalizationKeys.colorRed)))
                } else {
                    insights.append(("", localizationManager.localizedString(for: LocalizationKeys.threeMonths), "\(localizationManager.localizedString(for: LocalizationKeys.weightStable)) \(localizationManager.localizedString(for: LocalizationKeys.inThreeMonths))", "gray"))
                }
            } else {
                insights.append(("", localizationManager.localizedString(for: LocalizationKeys.threeMonths), localizationManager.localizedString(for: LocalizationKeys.insufficientDataInsights), "gray"))
            }
        } else {
            insights.append(("", localizationManager.localizedString(for: LocalizationKeys.threeMonths), localizationManager.localizedString(for: LocalizationKeys.insufficientDataInsights), "gray"))
        }
        
        // Progreso en 1 año
        if let yearAgoDate = calendar.date(byAdding: .year, value: -1, to: now) {
            // Buscar la entrada más cercana a 1 año atrás
            let yearAgoEntry = sortedEntries.filter { entry in
                let entryDate = entry.timestamp ?? Date()
                return entryDate <= yearAgoDate
            }.last // La más reciente que sea anterior a la fecha objetivo
            
            if let entry = yearAgoEntry {
                let weightChange = currentWeight - entry.weight
                let weightChangeFormatted = String(format: "%.1f", abs(weightChange))
                if weightChange < -0.1 {
                    insights.append(("↓", localizationManager.localizedString(for: LocalizationKeys.oneYear), "\(localizationManager.localizedString(for: LocalizationKeys.weightDecreased)) \(weightChangeFormatted) \(weightManager.getLocalizedUnitSymbol())", localizationManager.localizedString(for: LocalizationKeys.colorGreen)))
                } else if weightChange > 0.1 {
                    insights.append(("↑", localizationManager.localizedString(for: LocalizationKeys.oneYear), "\(localizationManager.localizedString(for: LocalizationKeys.weightIncreased)) \(weightChangeFormatted) \(weightManager.getLocalizedUnitSymbol())", localizationManager.localizedString(for: LocalizationKeys.colorRed)))
                } else {
                    insights.append(("", localizationManager.localizedString(for: LocalizationKeys.oneYear), "\(localizationManager.localizedString(for: LocalizationKeys.weightStable)) \(localizationManager.localizedString(for: LocalizationKeys.thisYear))", "gray"))
                }
            } else {
                insights.append(("", localizationManager.localizedString(for: LocalizationKeys.oneYear), localizationManager.localizedString(for: LocalizationKeys.insufficientDataInsights), "gray"))
            }
        } else {
            insights.append(("", localizationManager.localizedString(for: LocalizationKeys.oneYear), localizationManager.localizedString(for: LocalizationKeys.insufficientDataInsights), "gray"))
        }
        
        return insights
    }
    
    private func getInsightColor(_ colorName: String) -> Color {
        switch colorName {
        case localizationManager.localizedString(for: LocalizationKeys.colorGreen):
            return .green
        case localizationManager.localizedString(for: LocalizationKeys.colorRed):
            return .red
        case localizationManager.localizedString(for: LocalizationKeys.colorOrange):
            return .orange
        case localizationManager.localizedString(for: LocalizationKeys.colorBlue):
            return .blue
        case localizationManager.localizedString(for: LocalizationKeys.colorPurple):
            return .purple
        case localizationManager.localizedString(for: LocalizationKeys.colorTeal):
            return .teal
        default:
            return .secondary
        }
    }
    
    private func loadInitialData() {
        // Finalizar loading después de 1 segundo
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.35)) {
                isLoading = false
            }
        }
        
        // Cargar datos de peso
        weeklyChange = weeklyProgress
        
        // Inicializar rachas y logros
        Task {
            await gamificationManager?.checkForNewAchievements(weightManager: weightManager)
        }
        
        // Configurar notificaciones
        notificationManager?.setupNotificationCategories()
    }
    
    private func initializeManagersStepByStep() {
        // Inicializar GamificationManager
        do {
            gamificationManager = GamificationManager.shared
        } catch {
            fatalError("GamificationManager initialization failed: \(error)")
        }
        
        // Inicializar NotificationManager
        do {
            notificationManager = NotificationManager.shared
        } catch {
            fatalError("NotificationManager initialization failed: \(error)")
        }
        
        // Inicializar ThemeManager
        do {
            themeManager = ThemeManager.shared
        } catch {
            fatalError("ThemeManager initialization failed: \(error)")
        }
        
        // LocalizationManager ya está inicializado como @ObservedObject
    }
    
    private func startInsightTimer() {
        insightTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            let insights = getInformativeInsights()
            guard !insights.isEmpty else { return }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                currentInsightIndex = (currentInsightIndex + 1) % insights.count
            }
        }
    }
    
    
    
    // MARK: - Goal Progress Card
    
    @ViewBuilder
    private var goalProgressCard: some View {
        if let goal = weightManager.activeGoal {
            VStack(alignment: .leading, spacing: 16) {
                Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.goalProgressTitle))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(spacing: 12) {
                    // Progreso visual
                    let progress = calculateGoalProgress(for: goal)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(Int(progress * 100))\(LocalizationManager.shared.localizedString(for: LocalizationKeys.percentCompleted))")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.teal)
                            
                            Text("\(LocalizationManager.shared.localizedString(for: LocalizationKeys.sinceDate)) \(goal.startDate?.formatted(date: .abbreviated, time: .omitted) ?? "—")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .environment(\.locale, LocalizationManager.shared.currentLanguage.locale)
                        }
                        
                        Spacer()
                        
                        CircularProgressView(progress: progress)
                            .frame(width: 60, height: 60)
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
                            value: "\(String(format: "%.1f", weightManager.getDisplayWeight(getCurrentGoalWeight(), in: weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))) \(weightManager.getLocalizedUnitSymbol())",
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
            .scaleInAnimation(delay: 0.3)
        }
    }
    
    // MARK: - Helper Methods for Goal Progress
    
    private func calculateGoalProgress(for goal: WeightGoal) -> Double {
        let startWeight = goal.startWeight
        let targetWeight = goal.targetWeight
        let currentWeight = getCurrentGoalWeight()
        
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
    
    private func getCurrentGoalWeight() -> Double {
        return weightManager.getLatestWeightEntry()?.weight ?? 0.0
    }
    
    // MARK: - Helper Methods for Safe Data Access
    
    private func getTimeSinceLastEntryText(for entry: WeightEntry) -> String {
        guard let timestamp = entry.timestamp else {
            return LocalizationManager.shared.localizedString(for: LocalizationKeys.noRecordsTime)
        }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(timestamp)
        
        let hours = Int(timeInterval / 3600)
        let days = Int(timeInterval / 86400)
        
        if days > 0 {
            if days == 1 {
                return LocalizationManager.shared.localizedString(for: LocalizationKeys.dayAgo)
            } else {
                return String(format: LocalizationManager.shared.localizedString(for: LocalizationKeys.daysAgo), days)
            }
        } else if hours > 0 {
            return String(format: LocalizationManager.shared.localizedString(for: LocalizationKeys.hoursAgo), hours)
        } else {
            return LocalizationManager.shared.localizedString(for: LocalizationKeys.lessThanHour)
        }
    }
    
    private func getFormattedWeightText(for weight: Double) -> String {
        let unit = weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
        let displayWeight = weightManager.getDisplayWeight(weight, in: unit)
        return String(format: "%.1f %@", displayWeight, unit)
    }
    
    // MARK: - NotificationObserver Protocol
    func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name.weightDataUpdated,
            object: nil,
            queue: .main
        ) { _ in
            // Actualizar las rachas cuando se actualicen los datos de peso
            Task {
                await gamificationManager?.checkForNewAchievements(weightManager: weightManager)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name.settingsUpdated,
            object: nil,
            queue: .main
        ) { _ in
            // Forzar actualización de la UI cuando cambien las configuraciones
            // Esto incluye cambios en las unidades de peso
            // La UI se actualizará automáticamente ya que weightManager es @StateObject
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name.goalUpdated,
            object: nil,
            queue: .main
        ) { _ in
            // Verificar si no hay objetivo activo después de la actualización
            // Usar un delay más largo para asegurar que Core Data complete la operación
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Verificar múltiples condiciones para evitar crashes
                guard !isLoading,
                      !showingCreateGoal,
                      !showingGoals,
                      weightManager.activeGoal == nil else {
                    return
                }
                
                // Solo abrir CreateGoalView si no hay otras vistas modales abiertas
                showingCreateGoal = true
            }
        }
    }
    
    func removeNotificationObservers() {
        // Para structs, no necesitamos remover observadores explícitamente
        // ya que los observadores se manejan automáticamente cuando la vista se destruye
    }
    
    
    // MARK: - Supporting Views for Goal Progress
}

// MARK: - StreakInfoView Component
struct StreakInfoView: View {
    let gamificationManager: GamificationManager?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.streak))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
            }
            
            let currentStreak = gamificationManager?.currentStreak.currentStreak ?? 0
            let dayText = LocalizationManager.shared.localizedString(for: LocalizationKeys.day)
            let daysText = LocalizationManager.shared.localizedString(for: LocalizationKeys.days)
            let streakText = LocalizationManager.shared.localizedString(for: LocalizationKeys.streak)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(currentStreak)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundColor(.orange)
                
                Text(currentStreak == 1 ? dayText : daysText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .accessibilityLabel("\(streakText): \(currentStreak) \(currentStreak == 1 ? dayText : daysText)")
            
            Text(gamificationManager?.currentStreak.motivationalMessage ?? "Keep going!")
                .font(.caption)
                .foregroundColor(.secondary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
    }
}
