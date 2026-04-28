//
//  APIConfig.swift
//  Movie
//
//  Created by Rabi Nakarmi on 26/04/2026.
//


import Foundation

enum APIConfig {
    static var tmdbCredential: String {
        if let plistToken = Bundle.main.object(forInfoDictionaryKey: "TMDB_ACCESS_TOKEN") as? String {
            let trimmed = plistToken.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, trimmed != "YOUR_TMDB_ACCESS_TOKEN" {
                return trimmed
            }
        }
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "TMDB_API_KEY") as? String {
            let trimmed = plistKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, trimmed != "YOUR_TMDB_API_KEY" {
                return trimmed
            }
        }
        if let envToken = ProcessInfo.processInfo.environment["TMDB_ACCESS_TOKEN"]?.trimmingCharacters(in: .whitespacesAndNewlines), !envToken.isEmpty {
            return envToken
        }
        if let env = ProcessInfo.processInfo.environment["TMDB_API_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines), !env.isEmpty {
            return env
        }
        return ""
    }

    static var isConfigured: Bool { !tmdbCredential.isEmpty }
}
