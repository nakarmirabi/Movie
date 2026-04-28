//
//  FavoritesStore.swift
//  Movie
//
//  Created by Rabi Nakarmi on 26/04/2026.
//

import Foundation

final class FavoritesStore: ObservableObject {
    @Published private(set) var favorites: [MovieResult] = []

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileManager: FileManager = .default) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let dir = base.appendingPathComponent("Movie", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        self.fileURL = dir.appendingPathComponent("favorites.json", isDirectory: false)
        encoder.outputFormatting = [.sortedKeys]
        load()
    }

    func isFavorite(id: Int) -> Bool {
        favorites.contains { $0.id == id }
    }

    func toggle(_ movie: MovieResult) {
        if let idx = favorites.firstIndex(where: { $0.id == movie.id }) {
            favorites.remove(at: idx)
        } else {
            favorites.insert(movie, at: 0)
        }
        persist()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([MovieResult].self, from: data) else {
            favorites = []
            return
        }
        favorites = decoded
    }

    private func persist() {
        guard let data = try? encoder.encode(favorites) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
