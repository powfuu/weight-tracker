//
//  LanguageSelector.swift
//  Weight Progress Tracker
//
//  Created by Weight Progress Tracker on 2024.
//

import SwiftUI

struct LanguageSelector: View {
    @Binding var selectedLanguage: SupportedLanguage
    @ObservedObject var localizationManager: LocalizationManager
    
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
    
    var body: some View {
        VStack(spacing: 20) {
            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.selectLanguageDesc))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Lista de idiomas
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(languages, id: \.self) { language in
                    LanguageCard(
                        language: language,
                        isSelected: selectedLanguage == language,
                        action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedLanguage = language
                                localizationManager.setLanguage(language)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
            
            Spacer(minLength: 20)
        }
        .padding(.top, 20)
    }
}

struct LanguageCard: View {
    let language: SupportedLanguage
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Emoji de bandera
                Text(language.flag)
                    .font(.system(size: 32))
                
                // Nombre del idioma
                Text(language.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Código del idioma
                Text(language.locale.identifier.uppercased())
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [Color.teal, Color.teal.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.teal : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(
                color: isSelected ? Color.teal.opacity(0.3) : Color.black.opacity(0.1),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}



#Preview {
    LanguageSelector(
        selectedLanguage: .constant(.english),
        localizationManager: LocalizationManager.shared
    )
    .padding()
    .background(Color.black)
}
