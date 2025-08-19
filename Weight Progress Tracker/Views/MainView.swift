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
    @StateObject private var weightManager = WeightDataManager.shared
    @StateObject private var gamificationManager = GamificationManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var isLoading = true
    @State private var showingSettings = false
    @State private var showingGoals = false
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
        guard let latestEntry = weightManager.getLatestWeightEntry() else { return 0.0 }
        let unit = weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
        return weightManager.getDisplayWeight(latestEntry.weight, in: unit)
    }
    
    private var weeklyProgress: Double {
        let entries = weightManager.getWeightEntries(for: .week)
        guard entries.count >= 2 else { return 0 }
        let latest = entries.first?.weight ?? 0
        let oldest = entries.last?.weight ?? 0
        let change = latest - oldest
        let unit = weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
        return weightManager.getDisplayWeight(change, in: unit)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Fondo limpio y minimalista
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                // Partículas de fondo modernas
                ParticlesView()
                    .ignoresSafeArea()
                    .opacity(0.6)
                
                if isLoading {
                    loadingView
                } else {
                    mainContentView
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .onAppear {
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
        .sheet(isPresented: $showingWeightInput) {
            WeightInputView(isPresented: $showingWeightInput)
        }
        .sheet(isPresented: $showingCharts) {
            ChartsView()
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        CustomLoader()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleInAnimation(delay: 0.2)
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 32) {
                headerSection
                
                // Solo mostrar insights si hay datos
                if !weightManager.weightEntries.isEmpty {
                    insightsContainer
                }
                
                currentWeightSection
                chartSection
                streakContainer
                quickActionsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image("weight_ico_transparent")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 42, height: 42)
                        .foregroundColor(.teal)
                }
                
                // Subtítulo dinámico
                if let latestWeight = weightManager.getLatestWeightEntry() {
                    let timeSince = weightManager.getTimeSinceLastEntry()
                    let weightText = weightManager.formatWeight(latestWeight.weight)
                    Text("\(timeSince) · \(weightText)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Última actualización: \(timeSince), peso actual: \(weightText)")
                } else {
                    Text("Sin registros")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("No hay registros de peso disponibles")
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Botón de configuración
                Button(action: {
                    HapticFeedback.light()
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.teal)
                        .padding(8)
                        .background(Color.teal.opacity(0.1))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Configuración")
                .accessibilityHint("Abre la pantalla de configuración")
            }
        }
        .padding(.top, 20)
        .scaleInAnimation(delay: 0.1)
    }
    
    @ViewBuilder
    private var currentWeightSection: some View {
        VStack(spacing: 16) {
            // Línea 1: Peso en teal + flecha + porcentaje
            HStack(alignment: .center) {
                if let latestEntry = weightManager.getLatestWeightEntry() {
                    // Peso en color teal con flecha alineada
                    HStack(alignment: .bottom, spacing: 8) {
                        Text(String(format: "%.1f", currentWeight))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .foregroundColor(.teal)
                        
                        HStack(alignment: .bottom, spacing: 8) {
                            Text(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue)
                                .font(.title2)
                                .foregroundColor(.teal)
                                .accessibilityHidden(true)
                            
                            // Flecha alineada con kg
                            if let change = weightManager.getWeightChange() {
                                WeightChangeIndicator(
                                    change: change,
                                    isGoalToLose: weightManager.isGoalToLoseWeight()
                                )
                            }
                        }
                    }
                    
                    Spacer()
                     
                     // Botón + rediseñado
                     Button(action: {
                         HapticFeedback.medium()
                         showingWeightInput = true
                     }) {
                         Image(systemName: "plus")
                             .font(.title2)
                             .fontWeight(.bold)
                             .foregroundColor(.white)
                             .frame(width: 50, height: 50)
                             .background(
                                 Circle()
                                     .fill(Color.teal)
                             )
                             .shadow(color: Color.teal.opacity(0.3), radius: 8, x: 0, y: 4)
                     }
                     .scaleEffect(addWeightButtonScale)
                     .accessibilityLabel("Registrar nuevo peso")
                } else {
                    HStack(alignment: .bottom, spacing: 8) {
                        Text("--")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .foregroundColor(.teal)
                        
                        Text(weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue)
                            .font(.title2)
                            .foregroundColor(.teal)
                    }
                    
                    Spacer()
                }
            }
            
            // Línea 2: Promedio, Min, Max
            if let stats = weightManager.getWeightStatistics(for: selectedPeriod) {
                let unit = weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Promedio")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f %@", stats.avg, unit))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("Mínimo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f %@", stats.min, unit))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("Máximo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f %@", stats.max, unit))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Línea 3: Última actualización
            if let lastEntry = weightManager.getWeightEntries(for: .week).first {
                HStack {
                    Text("Última actualización")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(lastEntry.timestamp?.formatted(date: .abbreviated, time: .shortened) ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            

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
    private var insightsContainer: some View {
        let insights = getInformativeInsights()
        
        VStack(spacing: 16) {
            // Header con título
            HStack {
                // Indicadores de página
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index == currentInsightIndex ? Color.teal : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: currentInsightIndex)
                    }
                }
            }
            
            // Contenido del insight
            VStack(alignment: .leading, spacing: 8) {
                Text(insights[currentInsightIndex].1)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(insights[currentInsightIndex].2)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentInsightIndex)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.yellow.opacity(0.2))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
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
    
    @ViewBuilder
    private var streakContainer: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    Text("Racha")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)
                }
                
                let currentStreak = gamificationManager.currentStreak.currentStreak
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(currentStreak)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .foregroundColor(.orange)
                    
                    Text(currentStreak == 1 ? "día" : "días")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }
                .accessibilityLabel("Racha actual: \(currentStreak) \(currentStreak == 1 ? "día" : "días") consecutivos")
                
                Text(gamificationManager.currentStreak.motivationalMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Ícono de motivación
            let currentStreak = weightManager.getCurrentStreak()
            Image(systemName: currentStreak >= 7 ? "trophy.fill" : currentStreak >= 3 ? "star.fill" : "target")
                .font(.title)
                .foregroundColor(currentStreak >= 7 ? .yellow : currentStreak >= 3 ? .orange : .white)
                .padding(12)
                .background(
                    Circle()
                        .fill(currentStreak >= 7 ? Color.yellow.opacity(0.2) : currentStreak >= 3 ? Color.orange.opacity(0.3) : Color.orange.opacity(0.2))
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
                
                Text("Progreso")
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
                    Text("Cambio")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    
                    Text(String(format: "%@%.1f %@", weeklyProgress >= 0 ? "+" : "", weeklyProgress, weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(weeklyProgress >= 0 ? .red : .teal)
                        .accessibilityLabel("Cambio de peso: \(String(format: "%@%.1f %@", weeklyProgress >= 0 ? "más " : "menos ", abs(weeklyProgress), weightManager.userSettings?.preferredUnit == "lbs" ? "libras" : "kilogramos"))")
                }
                
                Spacer()
                
                PillButton(
                    title: "Ver detalles",
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
            Text("Acciones Rápidas")
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
                        
                        Text("Registrar Peso")
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
                .accessibilityLabel("Registrar nuevo peso")
                .accessibilityHint("Abre la pantalla para añadir un nuevo registro de peso")
                
                // Ver Estadísticas
                Button(action: {
                    showingCharts = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title2)
                            .foregroundColor(.teal)
                        
                        Text("Ver Estadísticas")
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
                .accessibilityLabel("Ver estadísticas detalladas")
                .accessibilityHint("Abre la vista de estadísticas con análisis detallado")
                
                // Objetivos
                Button(action: {
                    showingGoals = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "target")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        Text("Objetivos")
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
                .accessibilityLabel("Gestionar objetivos")
                .accessibilityHint("Abre la pantalla para configurar tus objetivos de peso")
                
                // Configuración
                Button(action: {
                    showingSettings = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text("Configuración")
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
                .accessibilityLabel("Abrir configuración")
                .accessibilityHint("Abre la pantalla de configuración de la aplicación")
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
                    Text("Progreso de peso")
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
            .accessibilityLabel("Ver estadísticas detalladas")
            .accessibilityHint("Toca para abrir la vista de estadísticas completas")
            
            let entries = weightManager.getWeightEntries(for: TimePeriod.week)
            let unit = weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
            
            if entries.isEmpty {
                emptyChartView
            } else {
                Chart(entries, id: \.id) { entry in
                    let displayWeight = weightManager.getDisplayWeight(entry.weight, in: unit)
                    LineMark(
                        x: .value("Fecha", entry.timestamp ?? Date()),
                        y: .value("Peso", displayWeight)
                    )
                    .foregroundStyle(.teal)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    
                    AreaMark(
                        x: .value("Fecha", entry.timestamp ?? Date()),
                        y: .value("Peso", displayWeight)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.teal.opacity(0.3), Color.teal.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
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
                    .stroke(Color(UIColor.systemGray5), lineWidth: 1)
            )
        .scaleInAnimation(delay: 0.5)
    }
    
    @ViewBuilder
    private var emptyChartView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.title)
                .foregroundColor(.teal.opacity(0.6))
            
            Text("No hay datos suficientes")
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Text("Agrega más entradas de peso para ver tu progreso")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Methods
    private func getInformativeInsights() -> [(String, String, String)] {
        let entries = weightManager.weightEntries
        guard !entries.isEmpty else {
            return [] // Devolver lista vacía cuando no hay datos
        }
        
        let sortedEntries = entries.sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
        let currentWeight = sortedEntries.last?.weight ?? 0
        let calendar = Calendar.current
        let now = Date()
        let unit = weightManager.userSettings?.preferredUnit ?? WeightUnit.kilograms.rawValue
        
        var insights: [(String, String, String)] = []
        
        // Progreso en 7 días
        if let weekAgoDate = calendar.date(byAdding: .day, value: -7, to: now) {
            let weekAgoEntry = sortedEntries.min(by: { entry1, entry2 in
                let date1 = entry1.timestamp ?? Date()
                let date2 = entry2.timestamp ?? Date()
                return abs(date1.timeIntervalSince(weekAgoDate)) < abs(date2.timeIntervalSince(weekAgoDate))
            })
            
            if let entry = weekAgoEntry {
                let weightChange = entry.weight - currentWeight
                let weightChangeFormatted = String(format: "%.1f", abs(weightChange))
                if weightChange > 0.1 {
                    insights.append(("", "7 días", "Perdiste \(weightChangeFormatted) \(unit)"))
                } else if weightChange < -0.1 {
                    insights.append(("", "7 días", "Ganaste \(weightChangeFormatted) \(unit)"))
                } else {
                    insights.append(("", "7 días", "Peso estable esta semana"))
                }
            }
        }
        
        // Progreso en 30 días
        if let monthAgoDate = calendar.date(byAdding: .day, value: -30, to: now) {
            let monthAgoEntry = sortedEntries.min(by: { entry1, entry2 in
                let date1 = entry1.timestamp ?? Date()
                let date2 = entry2.timestamp ?? Date()
                return abs(date1.timeIntervalSince(monthAgoDate)) < abs(date2.timeIntervalSince(monthAgoDate))
            })
            
            if let entry = monthAgoEntry {
                let weightChange = entry.weight - currentWeight
                let weightChangeFormatted = String(format: "%.1f", abs(weightChange))
                if weightChange > 0.1 {
                    insights.append(("", "30 días", "Perdiste \(weightChangeFormatted) \(unit)"))
                } else if weightChange < -0.1 {
                    insights.append(("", "30 días", "Ganaste \(weightChangeFormatted) \(unit)"))
                } else {
                    insights.append(("", "30 días", "Peso estable este mes"))
                }
            }
        }
        
        // Progreso en 90 días
        if let ninetyDaysAgoDate = calendar.date(byAdding: .day, value: -90, to: now) {
            let ninetyDaysAgoEntry = sortedEntries.min(by: { entry1, entry2 in
                let date1 = entry1.timestamp ?? Date()
                let date2 = entry2.timestamp ?? Date()
                return abs(date1.timeIntervalSince(ninetyDaysAgoDate)) < abs(date2.timeIntervalSince(ninetyDaysAgoDate))
            })
            
            if let entry = ninetyDaysAgoEntry {
                let weightChange = entry.weight - currentWeight
                let weightChangeFormatted = String(format: "%.1f", abs(weightChange))
                if weightChange > 0.1 {
                    insights.append(("", "90 días", "Perdiste \(weightChangeFormatted) \(unit)"))
                } else if weightChange < -0.1 {
                    insights.append(("", "90 días", "Ganaste \(weightChangeFormatted) \(unit)"))
                } else {
                    insights.append(("", "90 días", "Peso estable en 90 días"))
                }
            }
        }
        
        // Progreso en 1 año
        if let yearAgoDate = calendar.date(byAdding: .year, value: -1, to: now) {
            let yearAgoEntry = sortedEntries.min(by: { entry1, entry2 in
                let date1 = entry1.timestamp ?? Date()
                let date2 = entry2.timestamp ?? Date()
                return abs(date1.timeIntervalSince(yearAgoDate)) < abs(date2.timeIntervalSince(yearAgoDate))
            })
            
            if let entry = yearAgoEntry {
                let weightChange = entry.weight - currentWeight
                let weightChangeFormatted = String(format: "%.1f", abs(weightChange))
                if weightChange > 0.1 {
                    insights.append(("", "1 año", "Perdiste \(weightChangeFormatted) \(unit)"))
                } else if weightChange < -0.1 {
                    insights.append(("", "1 año", "Ganaste \(weightChangeFormatted) \(unit)"))
                } else {
                    insights.append(("", "1 año", "Peso estable este año"))
                }
            }
        }
        
        // Si no hay suficientes insights, agregar algunos informativos
        while insights.count < 4 {
            if insights.count == 0 {
                insights.append(("", "Registros", "\(entries.count) pesajes realizados"))
            } else if insights.count == 1 {
                let streakDays = weightManager.getCurrentStreak()
                if streakDays > 0 {
                    insights.append(("", "Racha", "\(streakDays) días consecutivos"))
                } else {
                    insights.append(("", "Progreso", "Sigue registrando tu peso"))
                }
            } else if insights.count == 2 {
                insights.append(("", "Constancia", "Cada registro cuenta"))
            } else {
                insights.append(("", "Meta", "Define tu objetivo de peso"))
            }
        }
        
        return Array(insights.prefix(4))
    }
    
    private func loadInitialData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.35)) {
                isLoading = false
            }
        }
        
        // Cargar datos de peso
        weeklyChange = weeklyProgress
        
        // Inicializar rachas y logros
        Task {
            await gamificationManager.checkForNewAchievements(weightManager: weightManager)
        }
        
        // Configurar notificaciones
        notificationManager.setupNotificationCategories()
    }
    
    private func startInsightTimer() {
        insightTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                currentInsightIndex = (currentInsightIndex + 1) % 4
            }
        }
    }
    
    func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .weightDataUpdated,
            object: nil,
            queue: .main
        ) { _ in
            // Actualizar las rachas cuando se actualicen los datos de peso
            Task {
                await gamificationManager.checkForNewAchievements(weightManager: weightManager)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .settingsUpdated,
            object: nil,
            queue: .main
        ) { _ in
            // Forzar actualización de la UI cuando cambien las configuraciones
            // Esto incluye cambios en las unidades de peso
            // La UI se actualizará automáticamente ya que weightManager es @StateObject
        }
    }
    
    func removeNotificationObservers() {
        // Para structs, no necesitamos remover observadores explícitamente
        // ya que los observadores se manejan automáticamente cuando la vista se destruye
    }
}
