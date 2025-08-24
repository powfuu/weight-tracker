//
//  AchievementsView.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import SwiftUI

struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var gamificationManager = GamificationManager.shared
    @StateObject private var weightManager = WeightDataManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    @State private var selectedTab = 0
    @State private var animationProgress: Double = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Selector
                tabSelector
                
                // Content
                TabView(selection: $selectedTab) {
                    achievementsTab
                        .tag(0)
                    
                    statisticsTab
                        .tag(1)
                }
                #if os(iOS)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                #endif
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(localizationManager.localizedString(for: LocalizationKeys.achievementsAndStats))
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(localizationManager.localizedString(for: LocalizationKeys.close)) {
                    HapticFeedback.light()
                    dismiss()
                }
                .foregroundColor(.teal)
            }
        }
        .onAppear {
            Task {
                await gamificationManager.checkForNewAchievements(weightManager: weightManager)
            }
            withAnimation(AnimationConstants.smoothEase.delay(0.2)) {
                animationProgress = 1.0
            }
        }
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(title: localizationManager.localizedString(for: LocalizationKeys.achievements), isSelected: selectedTab == 0) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedTab = 0
                }
                HapticFeedback.light()
            }
            
            TabButton(title: localizationManager.localizedString(for: LocalizationKeys.statistics), isSelected: selectedTab == 1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedTab = 1
                }
                HapticFeedback.light()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var achievementsTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if gamificationManager.achievements.isEmpty {
                    emptyAchievementsView
                } else {
                    ForEach(Array(AchievementType.allCases.enumerated()), id: \.element) { index, achievementType in
                        let achievement = gamificationManager.achievements.first { $0.type == achievementType }
                        
                        AchievementCard(
                            achievement: achievement,
                            type: achievementType,
                            isUnlocked: achievement != nil
                        )
                        .appearWithDelay(Double(index) * 0.1)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }
    
    private var statisticsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Streak Section
                streakSection
                
                // Motivational Stats
                motivationalStatsSection
                
                // Progress Overview
                progressOverviewSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }
    
    private var emptyAchievementsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.circle")
                .font(.system(size: 60))
                .foregroundColor(.teal.opacity(0.6))
            
            Text(localizationManager.localizedString(for: LocalizationKeys.startJourney))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(localizationManager.localizedString(for: LocalizationKeys.startJourneyDesc))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text(localizationManager.localizedString(for: LocalizationKeys.currentStreak))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(gamificationManager.currentStreak.currentStreak)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                    
                    Text(localizationManager.localizedString(for: LocalizationKeys.consecutiveDays))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("\(localizationManager.localizedString(for: LocalizationKeys.best)): \(gamificationManager.currentStreak.longestStreak)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if gamificationManager.currentStreak.isActiveToday {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(localizationManager.localizedString(for: LocalizationKeys.todayCompleted))
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                            Text(localizationManager.localizedString(for: LocalizationKeys.logToday))
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            Text(gamificationManager.currentStreak.localizedMotivationalMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private var motivationalStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.teal)
                
                Text(localizationManager.localizedString(for: LocalizationKeys.motivationalStats))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(gamificationManager.getMotivationalStats(), id: \.title) { stat in
                    MotivationalStatCard(stat: stat)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private var progressOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text(localizationManager.localizedString(for: LocalizationKeys.overallProgress))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            let unlockedCount = gamificationManager.achievements.count
            let totalCount = AchievementType.allCases.count
            let progress = Double(unlockedCount) / Double(totalCount)
            
            VStack(spacing: 12) {
                HStack {
                    Text(localizationManager.localizedString(for: LocalizationKeys.unlockedAchievements))
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(unlockedCount)/\(totalCount)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .teal))
                    .scaleEffect(y: 2)
                
                Text("\(Int(progress * 100))% \(localizationManager.localizedString(for: LocalizationKeys.completed))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .teal : .secondary)
                
                Rectangle()
                    .fill(isSelected ? .teal : Color.clear)
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct AchievementCard: View {
    let achievement: Achievement?
    let type: AchievementType
    let isUnlocked: Bool
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(isUnlocked ? type.color.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isUnlocked ? type.color : .gray)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(type.localizedTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isUnlocked ? .primary : .gray)
                
                Text(type.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(isUnlocked ? .secondary : .gray.opacity(0.6))
                    .lineLimit(2)
                
                if let achievement = achievement {
                    Text("\(localizationManager.localizedString(for: LocalizationKeys.unlocked)): \(achievement.unlockedDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(type.color)
                        .environment(\.locale, localizationManager.currentLanguage.locale)
                }
            }
            
            Spacer()
            
            // Status
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(type.color)
            } else {
                Image(systemName: "lock.circle.fill")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isUnlocked ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

struct MotivationalStatCard: View {
    let stat: MotivationalStat
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: stat.icon)
                .font(.title2)
                .foregroundColor(stat.color)
            
            Text(stat.value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(stat.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(stat.subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(stat.color.opacity(0.1))
        )
    }
}