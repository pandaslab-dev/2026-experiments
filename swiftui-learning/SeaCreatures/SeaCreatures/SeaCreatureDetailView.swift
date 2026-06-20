//
//  SeaCreatureDetailView.swift
//  SeaCreatures
//
//

import SwiftUI
import RealityKit
import RealityKitContent

struct SeaCreatureDetailView: View {
    let modelName: String
    @State private var horizontalRotation = CGFloat.zero
    @State private var verticalRotation = CGFloat.zero
    
    @State private var endHorizontalRotation = CGFloat.zero
    @State private var endVerticalRotation = CGFloat.zero
    
    var body: some View {
        Model3D(named: modelName, bundle: realityKitContentBundle)
            .rotation3DEffect(
                .degrees(horizontalRotation), axis: .y
            )
            .rotation3DEffect(
                .degrees(-verticalRotation), axis: .x
            )
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        horizontalRotation = value.translation.width + endHorizontalRotation
                        verticalRotation = value.translation.height + endVerticalRotation
                    })
                    .onEnded({ value in
                        endHorizontalRotation = horizontalRotation
                        endVerticalRotation = verticalRotation
                    })
            )
    }
}

#Preview {
    SeaCreatureDetailView(modelName: "SlugScene")
}
