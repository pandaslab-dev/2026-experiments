//
//  Tile.swift
//  Alphabetizer
//
//
//

import Foundation

struct Vocabulary {
    let words: [String]

    /// - returns: `count` unique, random words from `words`, guaranteed unsorted
    func selectRandomWords(count: Int) -> [String] {
        var newWords = Array(words.shuffled().prefix(count))
        while newWords.sorted() == newWords {
            newWords.shuffle()
        }
        return newWords
    }
    
    //each word has an emoji
    static let icons: [String: String] = [
        "Bear": "🐻",
        "Duck": "🦆",
        "Frog": "🐸",
        "Fox": "🦊",
        "Goose": "🦆",
        "Lizard": "🦎",
        "Panda": "🐼",
        "Rabbit": "🐇",
        "Sheep": "🐑",
        "Crab": "🦀",
        "Jellyfish": "🐙",
        "Octopus": "🦑",
        "Whale": "🐋",
    ]
}

extension Vocabulary {
    static let landAnimals = Vocabulary(words: [
        "Bear",
        "Duck",
        "Frog",
        "Fox",
        "Goose",
        "Lizard",
        "Panda",
        "Rabbit",
        "Sheep",
    ])

    static let oceanAnimals = Vocabulary(words: [
        "Crab",
        "Jellyfish",
        "Octopus",
        "Whale",
    ])
}
