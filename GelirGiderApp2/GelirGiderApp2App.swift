//
//  GelirGiderApp2App.swift
//  GelirGiderApp2
//
//  Created by Semih Tüzün on 9.01.2025.
//

import SwiftUI
import SwiftData

@main
struct GelirGiderApp2App: App {
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
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
