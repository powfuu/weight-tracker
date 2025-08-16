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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
