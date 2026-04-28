//
//  MovieAPIClient.swift
//  Movie
//
//  Created by Rabi Nakarmi on 26/04/2026.
//

import Foundation

struct MovieAPIClient {
    private let session: URLSession
    private let credential: String
    private let usesBearer: Bool
    private let timeout: TimeInterval

    init(session: URLSession? = nil, credential: String = APIConfig.tmdbCredential, timeout: TimeInterval = 15) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = timeout
            configuration.timeoutIntervalForResource = timeout
            self.session = URLSession(configuration: configuration)
        }
        self.credential = credential
        self.usesBearer = credential.count > 40 || credential.contains(".") || credential.hasPrefix("eyJ")
        self.timeout = timeout
    }

    func popularMovies(page: Int) async throws -> MovieResponseModel {
        guard !credential.isEmpty else { throw MovieServiceError.missingAPIKey }

        let url = try makeURL(
            path: MovieAPIEndpoints.Path.popularMovies,
            queryItems: [URLQueryItem(name: MovieAPIEndpoints.QueryKey.page, value: String(page))]
        )
        let request = makeRequest(url: url)
        return try await fetch(request, as: MovieResponseModel.self)
    }

    func searchMovies(query: String, page: Int) async throws -> MovieResponseModel {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw MovieServiceError.emptyQuery }

        guard !credential.isEmpty else { throw MovieServiceError.missingAPIKey }

        let url = try makeURL(
            path: MovieAPIEndpoints.Path.searchMovie,
            queryItems: [
                URLQueryItem(name: MovieAPIEndpoints.QueryKey.query, value: trimmed),
                URLQueryItem(name: MovieAPIEndpoints.QueryKey.page, value: String(page)),
                URLQueryItem(name: MovieAPIEndpoints.QueryKey.includeAdult, value: "false"),
            ]
        )
        let request = makeRequest(url: url)
        return try await fetch(request, as: MovieResponseModel.self)
    }

    private func makeURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
        var items = queryItems
        if !usesBearer {
            items.insert(URLQueryItem(name: MovieAPIEndpoints.QueryKey.apiKey, value: credential), at: 0)
        }
        guard let url = MovieAPIEndpoints.url(path: path, queryItems: items) else { throw MovieServiceError.invalidURL }
        return url
    }

    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        if usesBearer {
            request.setValue("Bearer \(credential)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func fetch<T: Decodable>(_ request: URLRequest, as: T.Type) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            throw NSError(
                domain: "MovieService",
                code: urlError.errorCode,
                userInfo: [NSLocalizedDescriptionKey: "Network error: \(urlError.localizedDescription)"]
            )
        } catch {
            throw NSError(
                domain: "MovieService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unexpected network error: \(error.localizedDescription)"]
            )
        }
        guard let http = response as? HTTPURLResponse else {
            throw MovieServiceError.httpStatus(-1)
        }
        guard (200 ... 299).contains(http.statusCode) else {
            if let envelope = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data),
               let message = envelope.statusMessage, !message.isEmpty {
                throw NSError(domain: "MovieService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            }
            throw MovieServiceError.httpStatus(http.statusCode)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw MovieServiceError.decodingFailed
        }
    }
}

actor MoviesRepository {
    private let client: MovieAPIClient
    private let cache: CachedMoviesStore

    init(client: MovieAPIClient = MovieAPIClient(), cache: CachedMoviesStore = .shared) {
        self.client = client
        self.cache = cache
    }

    func fetchPopularPage(_ page: Int) async throws -> MovieResponseModel {
        let response = try await client.popularMovies(page: page)
        let existing = await cache.loadEntry(for: "popular")?.movies ?? []
        let merged = (page <= 1) ? response.results : Self.mergeUnique(existing: existing, new: response.results)
        try await cache.upsert(query: "popular", movies: merged, lastPageLoaded: response.page, totalPages: response.totalPages)
        return response
    }

    func fetchSearchPage(query: String, page: Int) async throws -> MovieResponseModel {
        let response = try await client.searchMovies(query: query, page: page)
        let existing = await cache.loadEntry(for: query)?.movies ?? []
        let merged = (page <= 1) ? response.results : Self.mergeUnique(existing: existing, new: response.results)
        try await cache.upsert(query: query, movies: merged, lastPageLoaded: response.page, totalPages: response.totalPages)
        return response
    }

    func loadCachedPopular() async -> CachedMoviesStore.CachedSearchEntry? {
        await cache.loadEntry(for: "popular")
    }

    func loadCached(query: String) async -> CachedMoviesStore.CachedSearchEntry? {
        await cache.loadEntry(for: query)
    }

    func allRecentMovies(limit: Int = 200) async -> [MovieResult] {
        await cache.allRecentMovies(limit: limit)
    }

    private static func mergeUnique(existing: [MovieResult], new: [MovieResult]) -> [MovieResult] {
        guard !new.isEmpty else { return existing }
        var seen = Set(existing.map(\.id))
        var out = existing
        out.reserveCapacity(existing.count + new.count)
        for item in new where seen.insert(item.id).inserted {
            out.append(item)
        }
        return out
    }
}

