//
//  ContentView.swift
//  Movie
//
//  Created by Rabi Nakarmi on 26/04/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "heart") }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NetworkPathMonitor())
        .environmentObject(FavoritesViewModel())
}
