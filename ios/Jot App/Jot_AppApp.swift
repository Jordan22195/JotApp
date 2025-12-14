//
//  Jot_AppApp.swift
//  Jot App
//
//  Created by Jordan Roth on 12/12/25.
//

import SwiftUI
import CoreData

@main
struct Jot_AppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
