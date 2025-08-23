//
//  LanguageTestView.swift
//  Weight Progress Tracker
//
//  Created for debugging language persistence issues
//

import SwiftUI
import CoreData

struct LanguageTestView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var currentStoredLanguage: String = "No encontrado"
    @State private var refreshTrigger = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Prueba de Idioma")
                .font(.title)
                .padding()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Idioma actual en LocalizationManager:")
                    .font(.headline)
                Text(localizationManager.currentLanguage.rawValue)
                    .foregroundColor(.blue)
                
                Text("Idioma guardado en Core Data:")
                    .font(.headline)
                Text(currentStoredLanguage)
                    .foregroundColor(.green)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            VStack(spacing: 15) {
                Text("Cambiar idioma:")
                    .font(.headline)
                
                ForEach(SupportedLanguage.allCases, id: \.self) { language in
                    Button(action: {
                        // Idioma cambiado
                        localizationManager.setLanguage(language)
                        
                        // Esperar un poco y luego verificar
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            checkStoredLanguage()
                        }
                    }) {
                        HStack {
                            Text(language.flag)
                            Text(language.displayName)
                            Spacer()
                            if localizationManager.currentLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(localizationManager.currentLanguage == language ? Color.blue.opacity(0.2) : Color.clear)
                        .cornerRadius(8)
                    }
                    .foregroundColor(.primary)
                }
            }
            
            Button("Actualizar Estado") {
                checkStoredLanguage()
                refreshTrigger.toggle()
            }
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Spacer()
        }
        .padding()
        .onAppear {
            checkStoredLanguage()
        }
        .onChange(of: refreshTrigger) { _ in
            // Forzar actualización de la vista
        }
    }
    
    private func checkStoredLanguage() {
        do {
            let userSettings = try UserSettings.current(in: viewContext)
            currentStoredLanguage = userSettings.preferredLanguage ?? "nil"
            // Idioma en Core Data obtenido
        } catch {
            currentStoredLanguage = "Error: \(error.localizedDescription)"
            // Error obteniendo idioma
        }
    }
}

#Preview {
    LanguageTestView()
        .environmentObject(LocalizationManager.shared)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}