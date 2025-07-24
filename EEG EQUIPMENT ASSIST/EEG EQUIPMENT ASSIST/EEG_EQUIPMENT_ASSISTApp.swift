//
//  EEG_EQUIPMENT_ASSISTApp.swift
//  EEG EQUIPMENT ASSIST
//
//  Created by Abhay Kadambi on 7/23/25.
//

import SwiftUI
import SwiftData

@main
struct EEG_EQUIPMENT_ASSISTApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
