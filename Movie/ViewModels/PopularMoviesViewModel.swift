//
//  PopularMoviesViewModel.swift
//  Movie
//
//  Created by Rabi Nakarmi on 26/04/2026.
//

import Foundation

@MainActor
final class PopularMoviesViewModel: ObservableObject {
    @Published private(set) var movies: [MovieResult] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isLoadingMore: Bool = false
    @Published private(set) var userMessage: String?

    private let repository: MoviesRepository
    private let isRunningForPreviews = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"

    private var currentPage: Int = 0
    private var totalPages: Int = 0
    private var loadTask: Task<Void, Never>?
    private var nextPageTask: Task<Void, Never>?
    private var nextPageInFlight: Int?

    init(repository: MoviesRepository = MoviesRepository()) {
        self.repository = repository
    }

    func onAppear(isOnline: Bool) {
        guard movies.isEmpty else { return }

        if isRunningForPreviews {
            movies = [
                MovieResult(id: 1, title: "Preview Movie", releaseDate: "2024-01-01", posterPath: nil, overview: "This is sample data used only in Xcode previews."),
                MovieResult(id: 2, title: "Another Preview", releaseDate: "2023-07-11", posterPath: nil, overview: "Scroll to see pagination UI."),
            ]
            currentPage = 1
            totalPages = 3
            return
        }

        if isOnline {
            loadPopular(isOnline: true)
        } else {
            Task { await loadCachedOnLaunch() }
        }
    }

    func loadPopular(isOnline: Bool) {
        cancelWork()
        loadTask = Task {
            isLoading = true
            isLoadingMore = false
            userMessage = nil
            defer { isLoading = false }

            if isRunningForPreviews { return }

            movies = []
            currentPage = 0
            totalPages = 0

            if !isOnline {
                await loadCachedOrEmpty()
                return
            }

            guard APIConfig.isConfigured else {
                userMessage = MovieServiceError.missingAPIKey.errorDescription
                return
            }

            do {
                let page = try await repository.fetchPopularPage(1)
                try Task.checkCancellation()
                movies = Self.dedupPreservingOrder(page.results)
                currentPage = page.page
                totalPages = page.totalPages
            } catch is CancellationError {
                return
            } catch {
                await applyFallbackCache(error: error)
            }
        }
    }

    func loadNextPageIfNeeded(currentItem: MovieResult?, isOnline: Bool) {
        guard isOnline, !isLoading, !isLoadingMore else { return }
        guard let last = movies.last, currentItem?.id == last.id else { return }
        guard currentPage < totalPages else { return }

        let next = currentPage + 1
        guard nextPageInFlight != next else { return }
        nextPageInFlight = next
        isLoadingMore = true

        nextPageTask?.cancel()
        nextPageTask = Task {
            defer {
                isLoadingMore = false
                nextPageInFlight = nil
            }
            do {
                guard APIConfig.isConfigured else {
                    userMessage = MovieServiceError.missingAPIKey.errorDescription
                    return
                }
                let page = try await repository.fetchPopularPage(next)
                try Task.checkCancellation()
                movies = Self.mergeUnique(existing: movies, new: page.results)
                currentPage = page.page
                totalPages = page.totalPages
            } catch is CancellationError {
                return
            } catch {
                userMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    func dismissMessage() {
        userMessage = nil
    }

    private func loadCachedOnLaunch() async {
        if let cachedPopular = await repository.loadCachedPopular() {
            movies = Self.dedupPreservingOrder(cachedPopular.movies)
            currentPage = cachedPopular.lastPageLoaded
            totalPages = cachedPopular.totalPages
            userMessage = "You’re offline — showing cached popular movies."
            return
        }

        let recent = await repository.allRecentMovies()
        if !recent.isEmpty {
            movies = Self.dedupPreservingOrder(recent)
            userMessage = "You’re offline — showing movies from your recent searches."
        } else {
            userMessage = "You’re offline and there’s nothing cached yet. Go online once to load popular movies and cache results."
        }
    }

    private func loadCachedOrEmpty() async {
        if let cached = await repository.loadCached(query: "popular") {
            movies = Self.dedupPreservingOrder(cached.movies)
            currentPage = cached.lastPageLoaded
            totalPages = cached.totalPages
            userMessage = "You’re offline — showing cached popular movies."
        } else {
            movies = []
            currentPage = 0
            totalPages = 0
            userMessage = "You’re offline — no cached popular movies yet."
        }
    }

    private func applyFallbackCache(error: Error) async {
        if let cached = await repository.loadCached(query: "popular") {
            movies = Self.dedupPreservingOrder(cached.movies)
            currentPage = cached.lastPageLoaded
            totalPages = cached.totalPages
            userMessage = "Couldn’t refresh results, so I’m showing cached data. \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)"
        } else {
            movies = []
            userMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func cancelWork() {
        loadTask?.cancel()
        nextPageTask?.cancel()
        nextPageInFlight = nil
    }

    private static func dedupPreservingOrder(_ input: [MovieResult]) -> [MovieResult] {
        var seen = Set<Int>()
        var out: [MovieResult] = []
        out.reserveCapacity(input.count)
        for item in input where seen.insert(item.id).inserted {
            out.append(item)
        }
        return out
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

