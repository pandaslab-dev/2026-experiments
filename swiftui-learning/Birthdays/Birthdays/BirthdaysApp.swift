//
//  BirthdaysApp.swift
//  Birthdays
//
//  Created by Andy Mills on 1/20/25.
//

import SwiftUI
import SwiftData

@main
struct BirthdaysApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Friend.self)
        }
    }
}
