//
//  MovieSearchViewModel.swift
//  Movie
//
//  Created by Rabi Nakarmi on 26/04/2026.
//

import Foundation

@MainActor
final class MovieSearchViewModel: ObservableObject {
    @Published private(set) var movies: [MovieResult] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isLoadingMore: Bool = false
    @Published private(set) var userMessage: String?

    private let repository: MoviesRepository
    private let isRunningForPreviews = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"

    private var query: String = ""
    private var currentPage: Int = 0
    private var totalPages: Int = 0
    private var loadTask: Task<Void, Never>?
    private var nextPageTask: Task<Void, Never>?
    private var nextPageInFlight: Int?

    init(repository: MoviesRepository = MoviesRepository()) {
        self.repository = repository
    }

    func search(query: String, isOnline: Bool) {
        loadTask?.cancel()
        loadTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }

            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            self.query = trimmed

            if trimmed.isEmpty {
                movies = []
                currentPage = 0
                totalPages = 0
                userMessage = nil
                return
            }

            await loadFirstPage(isOnline: isOnline)
        }
    }

    func loadNextPageIfNeeded(currentItem: MovieResult?, isOnline: Bool) {
        guard !query.isEmpty else { return }
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
                let page = try await repository.fetchSearchPage(query: query, page: next)
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

    private func loadFirstPage(isOnline: Bool) async {
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
            let page = try await repository.fetchSearchPage(query: query, page: 1)
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

    private func loadCachedOrEmpty() async {
        if let cached = await repository.loadCached(query: query) {
            movies = Self.dedupPreservingOrder(cached.movies)
            currentPage = cached.lastPageLoaded
            totalPages = cached.totalPages
            userMessage = "You’re offline — showing cached results for “\(cached.query)”."
        } else {
            movies = []
            currentPage = 0
            totalPages = 0
            userMessage = "You’re offline — no cached results for this search."
        }
    }

    private func applyFallbackCache(error: Error) async {
        if let cached = await repository.loadCached(query: query) {
            movies = Self.dedupPreservingOrder(cached.movies)
            currentPage = cached.lastPageLoaded
            totalPages = cached.totalPages
            userMessage = "Couldn’t refresh results, so I’m showing cached data. \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)"
        } else {
            movies = []
            userMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
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

