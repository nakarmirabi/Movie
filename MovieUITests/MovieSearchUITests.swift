//
//  MovieSearchUITests.swift
//  Movie
//
//  Created by Rabi Nakarmi on 26/04/2026.
//

import XCTest

final class MovieUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsSearchTab() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Search"].exists)
        XCTAssertTrue(app.tabBars.buttons["Favorites"].exists)
    }

    func testSearchFieldExists() throws {
        let app = XCUIApplication()
        app.launch()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
    }
}
