//
//  WeightUnitSelector.swift
//  Weight Progress Tracker
//
//  Created by Weight Progress Tracker on 2024.
//

import SwiftUI

struct WeightUnitSelector: View {
    @Binding var selectedUnit: WeightUnit
    
    var body: some View {
        VStack(spacing: 20) {
            // Título
            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.selectUnit))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.selectUnitDesc))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Selector de unidades
            HStack(spacing: 16) {
                ForEach([WeightUnit.kilograms, WeightUnit.pounds], id: \.self) { unit in
                    WeightUnitCard(
                        unit: unit,
                        isSelected: selectedUnit == unit,
                        action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedUnit = unit
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

struct WeightUnitCard: View {
    let unit: WeightUnit
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Icono
                Image(systemName: "scalemass")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(isSelected ? .white : .teal)
                
                // Nombre de la unidad
                Text(unit.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .primary)
                
                // Descripción
                Text(unit.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [Color.teal, Color.teal.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
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

// Extensión para WeightUnit
extension WeightUnit {
    var displayName: String {
        switch self {
        case .kilograms:
            return LocalizationManager.shared.localizedString(for: LocalizationKeys.kg)
        case .pounds:
            return LocalizationManager.shared.localizedString(for: LocalizationKeys.lb)
        }
    }
    
    var description: String {
        switch self {
        case .kilograms:
            return LocalizationManager.shared.localizedString(for: LocalizationKeys.kgDesc)
        case .pounds:
            return LocalizationManager.shared.localizedString(for: LocalizationKeys.lbDesc)
        }
    }
}

#Preview {
    WeightUnitSelector(
        selectedUnit: .constant(.kilograms)
    )
    .padding()
}