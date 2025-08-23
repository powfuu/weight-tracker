//
//  TestLocalization.swift
//  Weight Progress Tracker
//
//  Test file for debugging localization
//

import Foundation
import SwiftUI

struct TestLocalizationView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Current Language: \(localizationManager.currentLanguage.rawValue)")
            Text("Display Name: \(localizationManager.currentLanguage.displayName)")
            
            Divider()
            
            Text("Testing goal_progress_title:")
            Text(localizationManager.localizedString(for: LocalizationKeys.goalProgressTitle) ?? "Goal Progress")
                .font(.headline)
                .foregroundColor(.blue)
            
            Text("Direct test:")
            Text(localizationManager.localizedString(for: "goal_progress_title") ?? "Goal Progress")
                .font(.headline)
                .foregroundColor(.green)
            
            Divider()
            
            Text("Available languages:")
            ForEach(SupportedLanguage.allCases, id: \.self) { language in
                Button(language.displayName) {
                    localizationManager.setLanguage(language)
                }
                .foregroundColor(language == localizationManager.currentLanguage ? .blue : .primary)
            }
        }
        .padding()
    }
}

#Preview {
    TestLocalizationView()
}