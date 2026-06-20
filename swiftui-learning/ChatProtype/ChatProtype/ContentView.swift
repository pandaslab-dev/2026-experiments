//
//  ContentView.swift
//  ChatProtype
//
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("bear chat")
                .fontWeight(Font.Weight.bold)
                .font(Font.system(size: 36))
            Text("ROAR")
                .padding()
                .background(Color.yellow, in: RoundedRectangle(cornerRadius: 8))
                .padding(.trailing, 255)
            Text("GRROAARRRR")
                .padding()
                .background(Color.teal, in: RoundedRectangle(cornerRadius: 8))
                .padding(.leading, 200)
            Text("ROARRR GRR")
                .padding()
                .background(Color.yellow, in: RoundedRectangle(cornerRadius: 8))
                .padding(.trailing, 200)
            Text("GRRRR GRRRRRGR rrgrr gRRROOAR")
                .padding()
                .background(Color.yellow, in: RoundedRectangle(cornerRadius: 8))
                .padding(.trailing, 25)
            Text("RrROARRRRRRRR")
                .padding()
                .background(Color.teal, in: RoundedRectangle(cornerRadius: 8))
                .padding(.leading, 175)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
