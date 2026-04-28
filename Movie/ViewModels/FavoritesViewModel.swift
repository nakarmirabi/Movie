//
//  FavoritesViewModel.swift
//  Movie
//
//  Created by Rabi Nakarmi on 27/04/2026.
//

import Foundation

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published private(set) var favorites: [MovieResult] = []

    private let store: FavoritesStore
    private var observationTask: Task<Void, Never>?

    init(store: FavoritesStore = FavoritesStore()) {
        self.store = store
        favorites = store.favorites
        observationTask = Task { [weak self] in
            guard let self else { return }
            for await value in store.$favorites.values {
                self.favorites = value
            }
        }
    }

    deinit {
        observationTask?.cancel()
    }

    func isFavorite(id: Int) -> Bool {
        store.isFavorite(id: id)
    }

    func toggle(_ movie: MovieResult) {
        store.toggle(movie)
    }
}

