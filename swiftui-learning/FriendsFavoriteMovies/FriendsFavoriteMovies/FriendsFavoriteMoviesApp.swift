//
//  FriendsFavoriteMoviesApp.swift
//  FriendsFavoriteMovies
//
//  Created by Andy Mills on 1/22/25.
//

import SwiftUI

@main
struct FriendsFavoriteMoviesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Movie.self, Friend.self])
    }
}
