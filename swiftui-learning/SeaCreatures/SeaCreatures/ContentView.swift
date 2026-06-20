//
//  ContentView.swift
//  SeaCreatures
//
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    
    @Environment(\.openWindow) private var openWindow
    @State private var selectedCreature: SeaCreature?
    
    private var seaCreatures = [
        SeaCreature(name: "clam", modelName: "ClamScene"),
        SeaCreature(name:"fish", modelName: "FishScene"),
        SeaCreature(name:"slug", modelName: "SlugScene"),
        SeaCreature(name:"starfish", modelName: "StarfishScene"),
    ]
    
    var body: some View {
        NavigationSplitView {
            List(seaCreatures) { creature in
                Button(action: {
                    selectedCreature = creature
                }, label: {
                    Text(creature.name)
                })
            }
            .navigationTitle("sea creatures")
        } detail : {
            if let selectedCreature {
                Model3D(named: selectedCreature.modelName, bundle: realityKitContentBundle)
                    .navigationTitle(selectedCreature.name)
                    .toolbar {
                        Button(action: {
                            openWindow(id: "creatureWindow", value: selectedCreature.modelName)
                        }, label: {
                            Text("View \(selectedCreature.name)")
                        })
                    }
            } else {
                Text("select a sea creature")
            }
        }
        .frame(minWidth: 700, minHeight: 700)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
