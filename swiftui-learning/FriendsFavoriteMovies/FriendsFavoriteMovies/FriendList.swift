//
//  FriendList.swift
//  FriendsFavoriteMovies
//
//

import SwiftUI
import SwiftData

struct FriendList: View {
    @Query(sort: \Friend.name) private var friends: [Friend]
    @Environment(\.modelContext) private var context
    @State private var newFriend: Friend?
    
    var body: some View {
        NavigationSplitView {
            Group {
                if !friends.isEmpty {
                    List {
                        ForEach(friends) { friend in
                            NavigationLink(friend.name) {
                                FriendDetail(friend: friend)
                            }
                        }
                        .onDelete(perform: deleteFriends(indexes:))
                    }
                } else {
                    ContentUnavailableView("add some friends", systemImage: "person.and.person")
                }
            }
            .navigationTitle("friends")
            .toolbar {
                ToolbarItem {
                    Button("Add Friend", systemImage: "plus", action: addFriend)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            .sheet(item: $newFriend) { friend in
                NavigationStack {
                    FriendDetail(friend:friend, isNew: true)
                }
                .interactiveDismissDisabled()
            }
        } detail: {
            Text("select a friend")
                .navigationTitle("friend")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    
    private func addFriend() {
        let newFriend = Friend(name: "")
        context.insert(newFriend)
        self.newFriend = newFriend
    }
    
    private func deleteFriends(indexes: IndexSet) {
        for index in indexes {
            context.delete(friends[index])
        }
    }
}

#Preview {
    FriendList()
        .modelContainer(SampleData.shared.modelContainer)
}
