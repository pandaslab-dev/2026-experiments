//
//  SeaCreaturesApp.swift
//  SeaCreatures
//
//

import SwiftUI

@main
struct SeaCreaturesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 0.75, height: 0.5, depth: 0.5, in: .meters)
        WindowGroup(id: "creatureWindow", for: String.self) { $modelName in
            SeaCreatureDetailView(modelName: modelName ?? "ToyBiplane")
                .padding3D(.all, 250)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.5, height: 0.5, depth: 0.5, in: .meters)
    }
}
