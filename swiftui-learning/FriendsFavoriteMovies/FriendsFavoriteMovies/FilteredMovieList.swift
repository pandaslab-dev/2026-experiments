//
//  FilteredMovieList.swift
//  FriendsFavoriteMovies
//
//  Created by Andy Mills on 1/25/25.
//

import SwiftUI

struct FilteredMovieList: View {
    @State private var searchText = ""
    
    var body: some View {
        NavigationSplitView {
            MovieList(titleFilter: searchText)
                .searchable(text: $searchText)
        } detail : {
            Text("Select a movie")
                .navigationTitle("movie")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    FilteredMovieList()
        .modelContainer(SampleData.shared.modelContainer)
}
