//
//  MovieAPIEndpoints.swift
//  Movie
//
//  Created by Rabi Nakarmi on 26/04/2026.
//

import Foundation

enum MovieAPIEndpoints {
    static let apiBaseURL = URL(string: "https://api.themoviedb.org/3")!
    static let imageBaseURL = URL(string: "https://image.tmdb.org/t/p")!

    enum Path {
        static let searchMovie = "search/movie"
        static let popularMovies = "movie/popular"
    }

    enum QueryKey {
        static let apiKey = "api_key"
        static let query = "query"
        static let page = "page"
        static let includeAdult = "include_adult"
    }

    static func url(path: String, queryItems: [URLQueryItem]) -> URL? {
        var components = URLComponents(url: apiBaseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        return components?.url
    }
}

