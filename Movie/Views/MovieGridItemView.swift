//
//  MovieGridItemView.swift
//  Movie
//
//  Created by Rabi Nakarmi on 26/04/2026.
//

import SwiftUI

struct MovieGridItemView: View {
    let movie: MovieResult

    var body: some View {
        VStack(spacing: 8) {
            AsyncPosterImage(url: movie.posterURL)
                .frame(maxWidth: .infinity)
                .aspectRatio(2 / 3, contentMode: .fit)
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)

            Text(movie.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("movieGridItem_\(movie.id)")
    }
}

