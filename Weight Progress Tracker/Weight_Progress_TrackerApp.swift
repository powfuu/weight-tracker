//
//  Weight_Progress_TrackerApp.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import SwiftUI

@main
struct Weight_Progress_TrackerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.dark) // Forzamos el tema oscuro globalmente
                .background(
                    Color(.systemBackground)
                        .ignoresSafeArea()
                )
        }
    }
}
