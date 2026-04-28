//
//  FavoritesView.swift
//  Movie
//
//  Created by Rabi Nakarmi on 26/04/2026.
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var favorites: FavoritesViewModel

    var body: some View {
        NavigationStack {
            Group {
                if favorites.favorites.isEmpty {
                    ContentUnavailableView(
                        "No favorites yet",
                        systemImage: "heart",
                        description: Text("Add favorites from a movie’s detail page. They’re saved locally on this device.")
                    )
                    .accessibilityIdentifier("emptyFavorites")
                } else {
                    List(favorites.favorites) { movie in
                        NavigationLink(value: movie) {
                            MovieRowView(movie: movie)
                        }
                    }
                    .listStyle(.plain)
                    .navigationDestination(for: MovieResult.self) { movie in
                        MovieDetailView(movie: movie)
                    }
                    .accessibilityIdentifier("favoritesList")
                }
            }
            .navigationTitle("Favorites")
        }
    }
}

#Preview {
    FavoritesView()
        .environmentObject(FavoritesViewModel())
}
