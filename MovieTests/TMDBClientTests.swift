//
//  TMDBClientTests.swift
//  Movie
//
//  Created by Rabi Nakarmi on 26/04/2026.
//

import XCTest
@testable import Movie

final class TMDBClientTests: XCTestCase {
    override func tearDown() {
        MockURLProtocol.handler = nil
        URLProtocol.unregisterClass(MockURLProtocol.self)
        super.tearDown()
    }

    func testSearchMoviesDecodesPage() async throws {
        URLProtocol.registerClass(MockURLProtocol.self)
        MockURLProtocol.handler = { request in
            XCTAssertTrue(request.url?.absoluteString.contains("search/movie") == true)
            let json = """
            {"page":1,"results":[{"id":42,"title":"Hello","release_date":"2021-05-05","poster_path":"/p.jpg","overview":"Nice"}],"total_pages":3,"total_results":120}
            """
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, json.data(using: .utf8))
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)

        let client = MovieAPIClient(session: session, credential: "test-key")
        let page = try await client.searchMovies(query: "Hello", page: 1)

        XCTAssertEqual(page.page, 1)
        XCTAssertEqual(page.totalPages, 3)
        XCTAssertEqual(page.results.count, 1)
        XCTAssertEqual(page.results.first?.id, 42)
        XCTAssertEqual(page.results.first?.title, "Hello")
    }

    func testMissingAPIKeyThrows() async {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = MovieAPIClient(session: session, credential: "")

        do {
            _ = try await client.searchMovies(query: "x", page: 1)
            XCTFail("Expected error")
        } catch let error as MovieServiceError {
            XCTAssertEqual(error, .missingAPIKey)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
