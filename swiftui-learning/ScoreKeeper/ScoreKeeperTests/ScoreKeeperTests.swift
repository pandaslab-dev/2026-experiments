//
//  ScoreKeeperTests.swift
//  ScoreKeeperTests
//
//  Created by Andy Mills on 1/20/25.
//

import Testing
@testable import ScoreKeeper

struct ScoreKeeperTests {

    @Test("Reset Player Scores", arguments: [0, 10, 20])
    func resetScores(to newValue: Int) async throws {
        var scoreboard = Scoreboard(players: [
            Player(name: "big bear", score: 6),
            Player(name: "lil bear", score: 0),
        ])
        scoreboard.resetScores(to: newValue)
        
        for player in scoreboard.players {
            #expect(player.score == newValue)
        }
    }
    
    @Test("Highest score wins")
    func highestScoreWins() {
        let scoreboard = Scoreboard(
            players: [
                Player(name: "big bear", score: 6),
                Player(name: "lil bear", score: 0),
            ],
            state: .gameOver,
            doesHighestScoreWin: true
        )
        let winners = scoreboard.winners
        #expect(winners == [Player(name: "big bear", score: 6)])
    }
    
    @Test("Lowst score wins")
    func lowestScoreWins() {
        let scoreboard = Scoreboard(
            players: [
                Player(name: "big bear", score: 6),
                Player(name: "lil bear", score: 0),
            ],
            state: .gameOver,
            doesHighestScoreWin: false
        )
        let winners = scoreboard.winners
        #expect(winners == [Player(name: "lil bear", score: 0)])
    }
    
    

}
