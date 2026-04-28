//
//  MovieResponseModel.swift
//  Movie
//
//  Created by Rabi Nakarmi on 26/04/2026.
//

import Foundation

struct MovieResponseModel: Codable, Sendable {
    let page: Int
    let results: [MovieResult]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct MovieResult: Codable, Sendable, Identifiable, Hashable {
    let id: Int
    let title: String
    let releaseDate: String?
    let posterPath: String?
    let overview: String?

    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case releaseDate = "release_date"
        case posterPath = "poster_path"
    }
}

extension MovieResult {
    var posterURL: URL? {
        guard let posterPath, !posterPath.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p")!
            .appendingPathComponent("w342")
            .appendingPathComponent(posterPath.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }

    var displayReleaseDate: String {
        guard let releaseDate, !releaseDate.isEmpty else { return "—" }
        return releaseDate
    }
}

struct ServiceErrorResponse: Decodable, Sendable {
    let statusMessage: String?

    enum CodingKeys: String, CodingKey {
        case statusMessage = "status_message"
    }
}

enum MovieServiceError: LocalizedError, Equatable {
    case missingAPIKey
    case invalidURL
    case httpStatus(Int)
    case decodingFailed
    case emptyQuery

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add `TMDB_ACCESS_TOKEN` (recommended) or `TMDB_API_KEY` in Info.plist, or set the matching environment variable."
        case .invalidURL:
            return "Could not build a valid request URL."
        case .httpStatus(let code):
            return "The movie service returned an error (HTTP \(code))."
        case .decodingFailed:
            return "Could not read the response from the movie service."
        case .emptyQuery:
            return "Enter a movie title to search."
        }
    }
}

