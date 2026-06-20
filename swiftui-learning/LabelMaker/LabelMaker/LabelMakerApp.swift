//
//  LabelMakerApp.swift
//  LabelMaker
//
//  Created by Andy Mills on 1/26/25.
//

import SwiftUI

@main
struct LabelMakerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        
        WindowGroup(for: Label.self) { $label in
            LabelView(label: $label)
                .disabled(true)
        } defaultValue: {
            Label(text: "", cornerRadius: 20)
        }
        .windowResizability(.contentSize)
        .windowStyle(.plain)
    }
}
