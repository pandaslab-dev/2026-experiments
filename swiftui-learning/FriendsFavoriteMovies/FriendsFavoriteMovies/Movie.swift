//
//  Movie.swift
//  FriendsFavoriteMovies
//
//

import Foundation
import SwiftData

@Model
class Movie {
    var title: String
    var releaseDate: Date
    var favoritedBy = [Friend]()
    
    init(title: String, releaseDate: Date) {
        self.title = title
        self.releaseDate = releaseDate
    }
    
    static let sampleData = [
        Movie(title: "fight club",
              releaseDate: Date(timeIntervalSinceReferenceDate: -39_571_200)),
        Movie(title: "the grand budapest hotel",
              releaseDate: Date(timeIntervalSinceReferenceDate: 415_689_600)),
        Movie(title: "300",
              releaseDate: Date(timeIntervalSinceReferenceDate: 195_705_600)),
        Movie(title: "the neverending story",
              releaseDate: Date(timeIntervalSinceReferenceDate: -518_284_800)),
        Movie(title: "labyrinth (1986)",
              releaseDate: Date(timeIntervalSinceReferenceDate: -457_142_400)),
        Movie(title: "speed racer",
              releaseDate: Date(timeIntervalSinceReferenceDate: 231_609_600)),
        Movie(title: "transformers",
              releaseDate: Date(timeIntervalSinceReferenceDate: 205_200_000)),
        
    ]
}
