//
//  Friend.swift
//  FriendsFavoriteMovies
//
//

import Foundation
import SwiftData

@Model
class Friend {
    var name: String
    var favoriteMovie: Movie?
    
    init(name: String) {
        self.name = name
    }
    
    static let sampleData = [
        Friend(name: "big bear"),
        Friend(name: "lil bear"),
        Friend(name: "jesse"),
        Friend(name: "owl"),
        Friend(name: "raven"),
        Friend(name: "dalton"),
        Friend(name: "meep")
    ]
}
