//
//  Event_BudgeterApp.swift
//  Event Budgeter
//
//  Created by Levi Greiner on 4/25/26.
//

import SwiftUI
import SwiftData

// MARK: - Schema Versions

enum AppSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Event.self, Person.self, EventPerson.self, PurchaseItem.self]
    }
}

enum AppSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Event.self, Person.self, EventPerson.self, PurchaseItem.self, GiftItem.self]
    }
}

// MARK: - Migration Plan

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [AppSchemaV1.self, AppSchemaV2.self] }

    // All V1→V2 changes are additive (new optional fields, new model), so lightweight migration suffices.
    static var stages: [MigrationStage] {
        [MigrationStage.lightweight(fromVersion: AppSchemaV1.self, toVersion: AppSchemaV2.self)]
    }
}

// MARK: - App Entry Point

@main
struct Event_BudgeterApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(AppSchemaV2.models)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: AppMigrationPlan.self,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
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
