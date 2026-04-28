//
//  MovieApp.swift
//  Movie
//
//  Created by Rabi Nakarmi on 26/04/2026.
//

import SwiftUI

@main
struct MovieApp: App {
    @StateObject private var pathMonitor = NetworkPathMonitor()
    @StateObject private var favorites = FavoritesViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(pathMonitor)
                .environmentObject(favorites)
                .onAppear {
                    pathMonitor.start()
                }
        }
    }
}

