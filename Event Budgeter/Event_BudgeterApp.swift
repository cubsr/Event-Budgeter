//
//  Event_BudgeterApp.swift
//  Event Budgeter
//
//  Created by Levi Greiner on 4/25/26.
//

import SwiftUI
import SwiftData

// MARK: - App Entry Point

@main
struct Event_BudgeterApp: App {
    // Bump this any time the schema changes in a non-backward-compatible way during dev.
    // On launch, if the stored version differs, the store is wiped before the container opens.
    private static let devSchemaVersion = 2

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Event.self,
            Person.self,
            EventPerson.self,
            PurchaseItem.self,
            GiftIdea.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        // Dev-mode store reset: if the schema version stamp doesn't match, wipe first.
        let storedVersion = UserDefaults.standard.integer(forKey: "devSchemaVersion")
        if storedVersion != devSchemaVersion {
            try? FileManager.default.removeItem(at: modelConfiguration.url)
            UserDefaults.standard.set(devSchemaVersion, forKey: "devSchemaVersion")
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            try? FileManager.default.removeItem(at: modelConfiguration.url)
            return try! ModelContainer(for: schema, configurations: [modelConfiguration])
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }
}
