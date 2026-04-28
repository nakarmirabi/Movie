//
//  MovieDetailView.swift
//  Movie
//
//  Created by Rabi Nakarmi on 26/04/2026.
//

import SwiftUI

struct MovieDetailView: View {
    let movie: MovieResult
    @EnvironmentObject private var favorites: FavoritesViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncPosterImage(url: movie.posterURL)
                    .frame(maxWidth: 240)
                    .frame(maxHeight: 360)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 8) {
                    Text(movie.title)
                        .font(.title2.weight(.semibold))
                        .accessibilityIdentifier("detailTitle")

                    Text(movie.displayReleaseDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("detailReleaseDate")

                    Text("Overview")
                        .font(.headline)
                        .padding(.top, 4)

                    Text(movie.overview?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? (movie.overview ?? "") : "No overview available.")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("detailOverview")
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    favorites.toggle(movie)
                } label: {
                    Image(systemName: favorites.isFavorite(id: movie.id) ? "heart.fill" : "heart")
                }
                .accessibilityIdentifier("favoriteButton")
            }
        }
    }
}

#Preview {
    NavigationStack {
        MovieDetailView(
            movie: MovieResult(
                id: 101,
                title: "Example Movie",
                releaseDate: "2022-10-10",
                posterPath: nil,
                overview: "Preview overview text."
            )
        )
    }
    .environmentObject(FavoritesViewModel())
}
