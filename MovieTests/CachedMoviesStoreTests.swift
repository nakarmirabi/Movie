//
//  CachedMoviesStoreTests.swift
//  Movie
//
//  Created by Rabi Nakarmi on 26/04/2026.
//

import XCTest
@testable import Movie

final class CachedMoviesStoreTests: XCTestCase {
    func testUpsertAndLoadRoundTrip() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let store = CachedMoviesStore(rootDirectory: root)
        let movie = MovieResult(id: 7, title: "Cached", releaseDate: "2019-01-01", posterPath: "/a.png", overview: "Overview")

        try await store.upsert(query: "Cached", movies: [movie], lastPageLoaded: 1, totalPages: 5)
        let entry = await store.loadEntry(for: "cached")
        XCTAssertEqual(entry?.movies.count, 1)
        XCTAssertEqual(entry?.movies.first?.id, 7)
        XCTAssertEqual(entry?.lastPageLoaded, 1)
        XCTAssertEqual(entry?.totalPages, 5)
    }
}
