//
//  MovieDetail.swift
//  FriendsFavoriteMovies
//
//

import SwiftUI

struct MovieDetail: View {
    @Bindable var movie: Movie
    let isNew: Bool
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    init(movie: Movie, isNew: Bool = false) {
        self.movie = movie
        self.isNew = isNew
    }
    
    var sortedFriends: [Friend] {
        movie.favoritedBy.sorted { first, second in
            first.name < second.name
        }
    }
    
    var body: some View {
        Form {
            TextField("movie title", text: $movie.title)
            
            DatePicker("release date", selection: $movie.releaseDate, displayedComponents: .date)
            
            if !movie.favoritedBy.isEmpty {
                Section("Favorited By") {
                    ForEach(sortedFriends) { friend in
                        Text(friend.name)
                    }
                }
            }
        }
        .navigationTitle(isNew ? "new movie" : "movie")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        context.delete(movie)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MovieDetail(movie: SampleData.shared.movie)
    }
}

#Preview("New Movie") {
    NavigationStack {
        MovieDetail(movie: SampleData.shared.movie, isNew: true)
    }
}
