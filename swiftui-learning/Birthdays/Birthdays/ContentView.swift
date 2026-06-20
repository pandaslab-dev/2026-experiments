//
//  ContentView.swift
//  Birthdays
//
//  Created by Andy Mills on 1/20/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Friend.birthday) private var friends: [Friend]
    @Environment(\.modelContext) private var context
    
    @State private var newName = ""
    @State private var newDate = Date.now
    
    var body: some View {
        NavigationStack {
            List(friends) { friend in
                HStack {
                    if friend.isBirthdayToday {
                        Image(systemName: "birthday.cake")
                    }
                    
                    Text(friend.name)
                        .bold(friend.isBirthdayToday)
                    
                    Spacer()
                    Text(friend.birthday, format: .dateTime.month(.wide).day().year())
                }
            }
            .navigationTitle("bear birthdays")
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .center, spacing: 20) {
                    Text("new birthday")
                        .font(.headline)
                    DatePicker(selection: $newDate, in: Date.distantPast...Date.now, displayedComponents: .date) {
                        TextField("Name", text: $newName)
                            .textFieldStyle(.roundedBorder)
                    }
                    Button("save") {
                        let newFriend = Friend(name: newName, birthday: newDate)
                        context.insert(newFriend)
                        
                        newName = ""
                        newDate = .now
                    }
                    .bold()
                }
                .padding()
                .background(.bar)
            }
            .task {
                context.insert(Friend(name: "baby bear", birthday: .now))
                context.insert(Friend(name: "1969 bear", birthday: Date(timeIntervalSince1970: 0)))
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Friend.self, inMemory: true)
}
