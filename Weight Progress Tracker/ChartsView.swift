//
//  ChartsView.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import SwiftUI
import Charts
import CoreData
import Foundation
#if canImport(UIKit)
import UIKit
#endif

struct ChartsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var weightManager = WeightDataManager.shared
    
    @State private var selectedPeriod: TimePeriod = .month
    @State private var weightEntries: [WeightEntry] = []
    @State private var isLoading = true
    @State private var selectedEntry: WeightEntry?
    // Estadísticas detalladas siempre visibles
    @State private var chartAnimationProgress: Double = 0
    
    // Estadísticas calculadas
    @State private var averageWeight: Double = 0
    @State private var weightChange: Double = 0
    @State private var trend: WeightTrend = .stable
    
    var body: some View {
        NavigationView {
            mainContentView
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        ZStack {
            // Fondo limpio y minimalista
            Color.black
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 24) {
                    if isLoading {
                        loadingView
                    } else {
                        contentView
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .navigationTitle("")
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        HapticFeedback.light()
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.teal)
                    }
                    .accessibilityLabel("Back")
                }
            }

        }
        .onAppear {
            loadData()
            withAnimation(.easeInOut(duration: 0.3).delay(0.3)) {
                chartAnimationProgress = 1.0
            }
        }
        .onChange(of: selectedPeriod) { _ in
            HapticFeedback.light()
            // Animación suave sin recargar la vista completa
            withAnimation(.easeInOut(duration: 0.3)) {
                chartAnimationProgress = 0.3
            }
            
            // Cargar datos de forma asíncrona
            Task {
                await loadDataAsync()
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3).delay(0.1)) {
                        chartAnimationProgress = 1.0
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        CustomLoader()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleInAnimation(delay: 0.2)
    }
    
    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 24) {
            chartSection
            periodSelectorSection
            statisticsSection
            
            detailedStatsSection
            
            recentEntriesSection
        }
    }
    
    @ViewBuilder
    private var periodSelectorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            periodSelectorHeader
            periodSelectorButtons
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var periodSelectorHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .foregroundColor(.teal)
            Text("Period")
                .font(.headline)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
        }
    }
    
    private var periodSelectorButtons: some View {
        HStack(spacing: 12) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                periodButton(for: period)
            }
        }
    }
    
    private func periodButton(for period: TimePeriod) -> some View {
        Button(action: {
            HapticFeedback.light()
            selectedPeriod = period
        }) {
            Text(period.shortName)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(selectedPeriod == period ? .white : .teal)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedPeriod == period ? .teal : Color.gray.opacity(0.2))
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
        }
        .animation(.easeInOut(duration: 0.2), value: selectedPeriod)
    }
    
    @ViewBuilder
    private var chartSection: some View {
        if weightEntries.isEmpty {
            VStack {
                Text("Progress Chart")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
                Text("No Data Available")
                    .foregroundColor(.secondary)
                    .accessibilityLabel("No weight data available")
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        } else {
            chartView
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
        }
    }
    
    @ViewBuilder
    private var statisticsSection: some View {
        statisticsView
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
    }
    
    @ViewBuilder
    private var recentEntriesSection: some View {
        recentEntriesView
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
    }
    
    @ViewBuilder
    private var detailedStatsSection: some View {
        detailedStatsView
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
    }
    

    
    @ViewBuilder
    private var chartView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.teal)
                
                Text("Weight Progress")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
            }
            
            chartContentView
        }
        .padding(24)
    }
    
    @ViewBuilder
    private var detailedStatsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.teal)
                
                Text("Detailed Statistics")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                DetailedStatCard(
                    title: "Maximum Weight",
                    value: String(format: "%.1f %@", weightManager.getDisplayWeight(weightEntries.map { $0.weight }.max() ?? 0, in: weightManager.userSettings?.preferredUnit ?? "kg"), weightManager.userSettings?.preferredUnit ?? "kg"),
                    icon: "arrow.up.circle.fill",
                    color: .red
                )
                
                DetailedStatCard(
                    title: "Minimum Weight",
                    value: String(format: "%.1f %@", weightManager.getDisplayWeight(weightEntries.map { $0.weight }.min() ?? 0, in: weightManager.userSettings?.preferredUnit ?? "kg"), weightManager.userSettings?.preferredUnit ?? "kg"),
                    icon: "arrow.down.circle.fill",
                    color: .green
                )
                
                DetailedStatCard(
                    title: "Total Entries",
                    value: "\(weightEntries.count)",
                    icon: "number.circle.fill",
                    color: .teal
                )
                
                DetailedStatCard(
                    title: "Period",
                    value: selectedPeriod.displayName,
                    icon: "calendar.circle.fill",
                    color: .purple
                )
            }
        }
        .padding(24)
    }
    
    private var chartContentView: some View {
        Chart {
            // Línea de objetivo punteada
            if let targetWeight = weightManager.userSettings?.targetWeight, targetWeight > 0 {
                RuleMark(y: .value("Target", targetWeight))
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .topTrailing, alignment: .trailing) {
                        Text("Target: \(String(format: "%.1f", weightManager.getDisplayWeight(targetWeight, in: weightManager.userSettings?.preferredUnit ?? "kg"))) \(weightManager.userSettings?.preferredUnit ?? "kg")")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.ultraThinMaterial)
                            )
                    }
            }
            
            ForEach(weightEntries, id: \.id) { entry in
                LineMark(
                    x: .value("Date", entry.timestamp ?? Date()),
                    y: .value("Weight", entry.weight)
                )
                .foregroundStyle(.teal)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                
                AreaMark(
                    x: .value("Date", entry.timestamp ?? Date()),
                    y: .value("Weight", entry.weight)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.teal.opacity(0.3), Color.teal.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Marcar primer y último punto
                if entry.id == weightEntries.first?.id || entry.id == weightEntries.last?.id {
                    PointMark(
                        x: .value("Date", entry.timestamp ?? Date()),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(entry.id == weightEntries.first?.id ? .green : .blue)
                    .symbolSize(60)
                    .symbol(Circle().strokeBorder(lineWidth: 3))
                }
                
                // Optimización: Simplificar punto seleccionado para mejor rendimiento
                if let selectedEntry = selectedEntry, selectedEntry.id == entry.id {
                    PointMark(
                        x: .value("Date", entry.timestamp ?? Date()),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(.teal)
                    .symbolSize(80)
                    
                    PointMark(
                        x: .value("Date", entry.timestamp ?? Date()),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(.white)
                    .symbolSize(40)
                }
            }
        }
        .frame(height: 200)
        .chartPlotStyle { plotFrame in
            plotFrame
                .background(Color.clear)
                .cornerRadius(12)
        }
        // .chartAppearAnimation()
        .opacity(chartAnimationProgress)
        .scaleEffect(x: chartAnimationProgress, y: 1, anchor: .topLeading)
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        HapticFeedback.light()
                        if #available(iOS 17.0, *) {
                            selectNearestEntry(at: location, geometry: geometry, chartProxy: chartProxy)
                        } else {
                            selectNearestEntryFallback(at: location, geometry: geometry)
                        }
                    }
            }
        }
        .chartOverlay { chartProxy in
            if let selectedEntry = selectedEntry {
                chartOverlayView(for: selectedEntry, chartProxy: chartProxy)
                    .transition(ScaleTransition.gentle)
            }
        }
    }
    
    private func chartOverlayView(for entry: WeightEntry, chartProxy: ChartProxy) -> some View {
         GeometryReader { geometry in
             let xPosition = chartProxy.position(forX: entry.timestamp ?? Date()) ?? 0
             
             VStack(alignment: .leading, spacing: 4) {
                 Text(String(format: "%.1f %@", weightManager.getDisplayWeight(entry.weight, in: weightManager.userSettings?.preferredUnit ?? "kg"), weightManager.userSettings?.preferredUnit ?? "kg"))
                     .font(.system(size: 14, weight: .bold, design: .rounded))
                     .foregroundColor(.primary)
                 
                 Text(entry.timestamp?.formatted(date: .abbreviated, time: .omitted) ?? "")
                   .font(.system(size: 12, weight: .medium, design: .rounded))
                   .foregroundColor(.secondary)
             }
             .padding(.horizontal, 12)
             .padding(.vertical, 8)
             .background(
                 RoundedRectangle(cornerRadius: 8)
                     .fill(Color.white)
                     .overlay(
                         RoundedRectangle(cornerRadius: 8)
                             .stroke(Color.teal, lineWidth: 1)
                     )
                     .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
             )
             .position(x: xPosition, y: 30)
         }
     }
    
    @ViewBuilder
    private var statisticsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.teal)
                
                Text("Statistics")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
            }
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Average",
                    value: String(format: "%.1f %@", weightManager.getDisplayWeight(averageWeight, in: weightManager.userSettings?.preferredUnit ?? "kg"), weightManager.userSettings?.preferredUnit ?? "kg"),
                    icon: "scalemass",
                    color: .teal
                )
                
                StatCard(
                    title: "Change",
                    value: String(format: "%@%.1f %@", weightChange >= 0 ? "+" : "", weightManager.getDisplayWeight(abs(weightChange), in: weightManager.userSettings?.preferredUnit ?? "kg"), weightManager.userSettings?.preferredUnit ?? "kg"),
                    icon: trend.icon,
                    color: weightChange >= 0 ? .red : .green
                )
            }
        }
        .padding(24)
    }
    
    @ViewBuilder
    private var recentEntriesView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.teal)
                
                Text("Recent Entries")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(weightEntries.prefix(5)), id: \.self) { entry in
                    WeightEntryRow(entry: entry, weightManager: weightManager)
                }
            }
        }
        .padding(24)
    }
    
    // MARK: - Data Functions
    
    private func loadData() {
        Task {
            await loadDataAsync()
        }
    }
    
    @MainActor
    private func loadDataAsync() async {
        isLoading = true
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "WeightEntry")
        
        // Configurar predicado basado en el período seleccionado
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch selectedPeriod {
        case .week:
            startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .quarter:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        request.predicate = NSPredicate(format: "timestamp >= %@", startDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        // Optimización: Limitar resultados para períodos largos
        if selectedPeriod == .year {
            request.fetchLimit = 500 // Limitar a 500 entradas máximo
        }
        
        do {
            let entries = try viewContext.fetch(request)
            
            // Actualizar en el hilo principal con animación
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    weightEntries = entries.compactMap { $0 as? WeightEntry }
                    calculateStatistics()
                    isLoading = false
                }
            }
        } catch {
            // Error fetching weight entries
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    weightEntries = []
                    isLoading = false
                }
            }
        }
    }
    
    private func calculateStatistics() {
        guard !weightEntries.isEmpty else {
            averageWeight = 0
            weightChange = 0
            trend = .stable
            return
        }
        
        // Optimización: Calcular promedio de forma más eficiente
        let weights: [Double] = weightEntries.map { $0.weight }
        averageWeight = weights.reduce(0, +) / Double(weights.count)
        
        // Optimización: Acceso directo a primer y último elemento
        guard let firstWeight: Double = weights.first, let lastWeight: Double = weights.last else {
            weightChange = 0
            trend = .stable
            return
        }
        
        // Calcular cambio de peso
        weightChange = lastWeight - firstWeight
        
        // Determinar tendencia con umbral optimizado
        if abs(weightChange) < 0.5 {
            trend = .stable
        } else {
            trend = weightChange > 0 ? .increasing : .decreasing
        }
    }
    
    @available(iOS 17.0, *)
    private func selectNearestEntry(at location: CGPoint, geometry: GeometryProxy, chartProxy: ChartProxy) {
        guard let plotFrame = chartProxy.plotFrame else { return }
        let frame = geometry[plotFrame]
        let origin = frame.origin
        let relativeXPosition = location.x - origin.x
        
        if let date = chartProxy.value(atX: relativeXPosition, as: Date.self) {
            var nearestEntry = weightEntries.first
            var nearestDistance = Double.infinity
            
            
            for entry in weightEntries {
                let entryDate = entry.timestamp ?? Date()
                let distance = abs(entryDate.timeIntervalSince(date))
                if distance < nearestDistance {
                    nearestDistance = distance
                    nearestEntry = entry
                }
            }
            
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedEntry = nearestEntry
            }
        }
    }
    
    private func selectNearestEntryFallback(at location: CGPoint, geometry: GeometryProxy) {
        // Implementación alternativa para iOS 16.0
        let relativeX = location.x / geometry.size.width
        let index = Int(relativeX * Double(weightEntries.count))
        let clampedIndex = max(0, min(weightEntries.count - 1, index))
        
        if !weightEntries.isEmpty {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedEntry = weightEntries[clampedIndex]
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: 1.0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct WeightEntryRow: View {
    let entry: WeightEntry
    let weightManager: WeightDataManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "%.1f %@", weightManager.getDisplayWeight(entry.weight, in: weightManager.userSettings?.preferredUnit ?? "kg"), weightManager.userSettings?.preferredUnit ?? "kg"))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text(entry.timestamp?.formatted(date: .abbreviated, time: .shortened) ?? "")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "scalemass.fill")
                .foregroundColor(.teal)
                .font(.title3)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weight Recorded: \(String(format: "%.1f", weightManager.getDisplayWeight(entry.weight, in: weightManager.userSettings?.preferredUnit ?? "kg"))) \(weightManager.userSettings?.preferredUnit == "lb" ? "pounds" : "kilograms"), fecha: \(entry.timestamp?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown Date")")
    }
}

struct DetailedStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Enums

enum WeightTrend {
    case increasing
    case decreasing
    case stable
    
    var icon: String {
        switch self {
        case .increasing:
            return "arrow.up.right"
        case .decreasing:
            return "arrow.down.right"
        case .stable:
            return "arrow.right"
        }
    }
    
    var color: Color {
        switch self {
        case .increasing:
            return Color.yellow
        case .decreasing:
            return Color.green
        case .stable:
            return .gray
        }
    }
}

// MARK: - Detail Views
