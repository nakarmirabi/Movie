//
//  SearchView.swift
//  Movie
//
//  Created by Rabi Nakarmi on 26/04/2026.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var pathMonitor: NetworkPathMonitor
    @StateObject private var popularViewModel = PopularMoviesViewModel()
    @StateObject private var searchViewModel = MovieSearchViewModel()
    @State private var query: String = ""

    private var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Movies")
                .searchable(text: $query, prompt: "Search by title")
                .onChange(of: query) { _, newValue in
                    searchViewModel.search(query: newValue, isOnline: pathMonitor.isConnected)
                    if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        popularViewModel.loadPopular(isOnline: pathMonitor.isConnected)
                    }
                }
                .onChange(of: pathMonitor.isConnected) { _, isOnline in
                    if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        if isOnline {
                            popularViewModel.loadPopular(isOnline: true)
                        } else {
                            popularViewModel.loadPopular(isOnline: false)
                        }
                    } else {
                        searchViewModel.search(query: query, isOnline: isOnline)
                    }
                }
                .onAppear {
                    popularViewModel.onAppear(isOnline: pathMonitor.isConnected)
                }
                .safeAreaInset(edge: .top) {
                    statusBanner
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isSearching {
            searchContent
        } else {
            popularContent
        }
    }

    @ViewBuilder
    private var popularContent: some View {
        if popularViewModel.movies.isEmpty, popularViewModel.isLoading {
            ProgressView("Searching…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if popularViewModel.movies.isEmpty {
            ContentUnavailableView(
                "Nothing to show yet",
                systemImage: "magnifyingglass",
                description: Text("Search for a movie title. When you’re online, popular movies load automatically.")
            )
            .accessibilityIdentifier("emptySearch")
        } else {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 160), spacing: 16, alignment: .top)],
                    spacing: 16
                ) {
                    ForEach(popularViewModel.movies) { movie in
                        NavigationLink(value: movie) {
                            MovieGridItemView(movie: movie)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            popularViewModel.loadNextPageIfNeeded(currentItem: movie, isOnline: pathMonitor.isConnected)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                if popularViewModel.isLoadingMore {
                    ProgressView()
                        .padding(.vertical, 16)
                }
            }
            .navigationDestination(for: MovieResult.self) { movie in
                MovieDetailView(movie: movie)
            }
            .accessibilityIdentifier("searchResultsGrid")
        }
    }

    @ViewBuilder
    private var searchContent: some View {
        if searchViewModel.movies.isEmpty, searchViewModel.isLoading {
            ProgressView("Searching…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if searchViewModel.movies.isEmpty {
            ContentUnavailableView(
                "Nothing to show yet",
                systemImage: "magnifyingglass",
                description: Text("Search for a movie title. When you’re online, popular movies load automatically.")
            )
            .accessibilityIdentifier("emptySearch")
        } else {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 160), spacing: 16, alignment: .top)],
                    spacing: 16
                ) {
                    ForEach(searchViewModel.movies) { movie in
                        NavigationLink(value: movie) {
                            MovieGridItemView(movie: movie)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            searchViewModel.loadNextPageIfNeeded(currentItem: movie, isOnline: pathMonitor.isConnected)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                if searchViewModel.isLoadingMore {
                    ProgressView()
                        .padding(.vertical, 16)
                }
            }
            .navigationDestination(for: MovieResult.self) { movie in
                MovieDetailView(movie: movie)
            }
            .accessibilityIdentifier("searchResultsGrid")
        }
    }

    @ViewBuilder
    private var statusBanner: some View {
        VStack(spacing: 8) {
            if !pathMonitor.isConnected {
                Label("You’re offline", systemImage: "wifi.slash")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(.orange.opacity(0.15))
                    .accessibilityIdentifier("offlineBanner")
            }

            if !isSearching, let message = popularViewModel.userMessage, !message.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Dismiss") {
                        popularViewModel.dismissMessage()
                    }
                    .font(.subheadline.weight(.semibold))
                }
                .padding(10)
                .background(Color.secondary.opacity(0.12))
                .accessibilityIdentifier("userMessageBanner")
            }

            if isSearching, let message = searchViewModel.userMessage, !message.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Dismiss") {
                        searchViewModel.dismissMessage()
                    }
                    .font(.subheadline.weight(.semibold))
                }
                .padding(10)
                .background(Color.secondary.opacity(0.12))
                .accessibilityIdentifier("userMessageBanner")
            }
        }
    }
}
#Preview {
    SearchView()
        .environmentObject(NetworkPathMonitor())
        .environmentObject(FavoritesViewModel())
}
