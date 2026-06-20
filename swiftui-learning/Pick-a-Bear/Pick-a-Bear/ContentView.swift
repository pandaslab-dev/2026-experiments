//
//  ContentView.swift
//  Pick-a-Bear
//
//

import SwiftUI

struct ContentView: View {
    @State private var names: [String] = ["brown bear", "polar bear", "chicago bear", "black bear", "panda bear", "lil bear"]
    @State private var nameToAdd = ""
    @State private var pickedName = ""
    @State private var shouldRemovePickedname = false
    
    var body: some View {
        VStack {
            VStack(spacing: 8) {
                Image(systemName: "teddybear")
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)
                Text("pick-a-bear")
            }
            .font(.title)
            .bold()
            
            Text(pickedName.isEmpty ? " " : pickedName)
                .font(.title2)
                .bold()
                .foregroundStyle(.tint)
            
            List {
                ForEach(names, id: \.description) { name in
                    Text(name)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            TextField("Add Name", text: $nameToAdd)
                .autocorrectionDisabled()
                .onSubmit {
                    if !nameToAdd.isEmpty {
                        names.append(nameToAdd)
                        nameToAdd = ""
                    }
                }
            
            Divider()
            
            Toggle("Remove When Picked", isOn: $shouldRemovePickedname)
                
            
            Button {
                if let randomName = names.randomElement() {
                    pickedName = randomName
                    
                    if shouldRemovePickedname {
                        names.removeAll { name in
                            return (name == randomName)
                        }
                    }
                } else {
                    pickedName = " "
                }
            } label: {
                Text("Pick Random Bear")
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    
            }
    
            .buttonStyle(.borderedProminent)
            .font(.title2)
            
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
