//
//  FirstWeightInput.swift
//  Weight Progress Tracker
//
//  Created by Weight Progress Tracker on 2024.
//

import SwiftUI

struct FirstWeightInput: View {
    @Binding var currentWeight: String
    let selectedUnit: WeightUnit
    @FocusState private var isTextFieldFocused: Bool
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Función para validar el peso
    func validateWeight() -> Bool {
        // Verificar si el campo está vacío
        if currentWeight.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alertTitle = LocalizationManager.shared.localizedString(forKey: LocalizationKeys.emptyWeightField)
            alertMessage = LocalizationManager.shared.localizedString(forKey: LocalizationKeys.emptyWeightFieldDesc)
            showingAlert = true
            return false
        }
        
        // Intentar convertir a Double
        guard let weight = Double(currentWeight.replacingOccurrences(of: ",", with: ".")) else {
            alertTitle = LocalizationManager.shared.localizedString(forKey: LocalizationKeys.invalidWeightData)
            alertMessage = LocalizationManager.shared.localizedString(forKey: LocalizationKeys.invalidWeightDataDesc)
            showingAlert = true
            return false
        }
        
        // Verificar rango (1-600)
        if weight < 1 || weight > 600 {
            alertTitle = LocalizationManager.shared.localizedString(forKey: LocalizationKeys.weightOutOfRange)
            alertMessage = LocalizationManager.shared.localizedString(forKey: LocalizationKeys.weightOutOfRangeDesc)
            showingAlert = true
            return false
        }
        
        return true
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Título
            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.firstWeightDesc))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Input de peso
            VStack(spacing: 16) {
                // Campo de entrada principal
                HStack {
                    Image(systemName: "scalemass.fill")
                        .font(.title2)
                        .foregroundColor(.teal)
                        .scaleEffect(isTextFieldFocused ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused)
                    
                    TextField(
                        LocalizationManager.shared.localizedString(for: LocalizationKeys.enterWeight),
                        text: $currentWeight
                    )
                    .keyboardType(.decimalPad)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .font(.system(size: 24, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .focused($isTextFieldFocused)
                    .animation(nil, value: isTextFieldFocused)
                    .preferredColorScheme(.dark)
                    .onChange(of: currentWeight) { newValue in
                        // Normalizar comas a puntos para compatibilidad con separadores decimales
                        let normalizedValue = newValue.replacingOccurrences(of: ",", with: ".")
                        if normalizedValue != newValue {
                            currentWeight = normalizedValue
                        }
                    }
                    
                    Text(selectedUnit.displayName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.teal)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.teal.opacity(isTextFieldFocused ? 0.2 : 0.1))
                                .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused)
                        )
                        .scaleEffect(isTextFieldFocused ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black)
                        .shadow(
                            color: isTextFieldFocused ? Color.teal.opacity(0.3) : Color.black.opacity(0.1),
                            radius: isTextFieldFocused ? 8 : 2,
                            x: 0,
                            y: isTextFieldFocused ? 4 : 1
                        )
                        .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isTextFieldFocused ? Color.teal : Color.teal.opacity(0.3),
                            lineWidth: isTextFieldFocused ? 3 : 1
                        )
                        .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused)
                )
                .scaleEffect(isTextFieldFocused ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused)
                
                // Información adicional
                if !currentWeight.isEmpty {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        
                        Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.firstWeightInfo))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            
            // Sugerencias de peso
            WeightSuggestions(
                selectedUnit: selectedUnit,
                onWeightSelected: { weight in
                    currentWeight = LocalizationManager.shared.formatWeight(weight)
                }
            )
            
            Spacer(minLength: 20)
        }
        .padding(.top, 20)
        .alert(alertTitle, isPresented: $showingAlert) {
            Button(LocalizationManager.shared.localizedString(forKey: LocalizationKeys.ok)) {
                showingAlert = false
            }
        } message: {
            Text(alertMessage)
        }
    }
}

struct WeightSuggestions: View {
    let selectedUnit: WeightUnit
    let onWeightSelected: (Double) -> Void
    
    private var suggestions: [Double] {
        switch selectedUnit {
        case .kilograms:
            return [50.0, 60.0, 70.0, 80.0, 90.0, 100.0, 120.0, 140.0, 180.0]
        case .pounds:
            return [110.0, 130.0, 150.0, 170.0, 190.0, 220.0, 265.0, 310.0, 395.0]
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text(LocalizationManager.shared.localizedString(for: LocalizationKeys.quickSelect))
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(suggestions, id: \.self) { weight in
                        Button(action: {
                            onWeightSelected(weight)
                        }) {
                            Text("\(weight, specifier: "%.0f") \(selectedUnit.displayName)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.teal)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.teal.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.teal.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    FirstWeightInput(
        currentWeight: .constant(""),
        selectedUnit: .kilograms
    )
    .padding()
    .background(Color.black)
}
