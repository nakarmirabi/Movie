//
//  CachedMoviesStore.swift
//  Movie
//
//  Created by Rabi Nakarmi on 26/04/2026.
//

import Foundation

actor CachedMoviesStore {
    static let shared = CachedMoviesStore()

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private struct DiskPayload: Codable, Sendable {
        var entries: [String: CachedSearchEntry]
    }

    struct CachedSearchEntry: Codable, Sendable {
        var query: String
        var movies: [MovieResult]
        var lastPageLoaded: Int
        var totalPages: Int
        var updatedAt: Date
    }

    init(fileManager: FileManager = .default, rootDirectory: URL? = nil) {
        let base = rootDirectory
            ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let dir = base.appendingPathComponent("Movie", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        self.fileURL = dir.appendingPathComponent("search_cache.json", isDirectory: false)
        encoder.outputFormatting = [.sortedKeys]
    }

    func normalizedKey(for query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    func loadEntry(for query: String) -> CachedSearchEntry? {
        let key = normalizedKey(for: query)
        guard let data = try? Data(contentsOf: fileURL),
              let payload = try? decoder.decode(DiskPayload.self, from: data) else { return nil }
        return payload.entries[key]
    }

    func upsert(
        query: String,
        movies: [MovieResult],
        lastPageLoaded: Int,
        totalPages: Int
    ) async throws {
        let key = normalizedKey(for: query)
        var payload: DiskPayload
        if let data = try? Data(contentsOf: fileURL), let existing = try? decoder.decode(DiskPayload.self, from: data) {
            payload = existing
        } else {
            payload = DiskPayload(entries: [:])
        }

        payload.entries[key] = CachedSearchEntry(
            query: query.trimmingCharacters(in: .whitespacesAndNewlines),
            movies: movies,
            lastPageLoaded: lastPageLoaded,
            totalPages: totalPages,
            updatedAt: Date()
        )

        let data = try encoder.encode(payload)
        try data.write(to: fileURL, options: [.atomic])
    }

    func allRecentMovies(limit: Int = 200) -> [MovieResult] {
        guard let data = try? Data(contentsOf: fileURL),
              let payload = try? decoder.decode(DiskPayload.self, from: data) else { return [] }

        let sorted = payload.entries.values.sorted { $0.updatedAt > $1.updatedAt }
        var seen = Set<Int>()
        var out: [MovieResult] = []
        for entry in sorted {
            for movie in entry.movies where seen.insert(movie.id).inserted {
                out.append(movie)
                if out.count >= limit { return out }
            }
        }
        return out
    }
}
