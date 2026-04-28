//
//  MovieRowView.swift
//  Movie
//
//  Created by Rabi Nakarmi on 26/04/2026.
//

import SwiftUI

struct MovieRowView: View {
    let movie: MovieResult

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncPosterImage(url: movie.posterURL)
                .frame(width: 56, height: 84)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(movie.displayReleaseDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("movieCell_\(movie.id)")
    }
}
