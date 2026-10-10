import XCTest

final class SpaceUITests: XCTestCase {
    @MainActor func testSpaceTabsSearchImageAndFavorites() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test"]
        app.launch()
        app.buttons["sidebarButton"].tap()
        app.buttons["Space"].tapWhenSettled()
        XCTAssertTrue(app.buttons["Space options"].waitForExistence(timeout: 3))
        capture("space-suggested")
        app.buttons["space.tab.Favorites"].tap()
        XCTAssertTrue(app.staticTexts["Save your favorites"].exists)
        capture("space-favorites-empty")
        app.buttons["space.tab.Suggested"].tap()
        app.buttons["Space options"].tapWhenSettled()
        app.buttons["List"].tapWhenSettled()
        capture("space-list")
        let search = app.textFields["space.search"]
        search.tapToFocus()
        search.typeText("Garden")
        XCTAssertFalse(app.buttons["Planting guide"].exists)
        app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@ AND identifier BEGINSWITH %@", "Garden design", "space.item.")
        ).firstMatch.tap()
        XCTAssertTrue(app.buttons["Close Space image"].waitForExistence(timeout: 3))
        capture("space-image")
        app.buttons["Space image options"].tap()
        app.buttons["Add to Favorites"].tapWhenSettled()
        app.buttons["Close Space image"].tapWhenSettled()
        app.buttons["space.tab.Favorites"].tapWhenSettled()
        XCTAssertFalse(app.staticTexts["Save your favorites"].exists)
        capture("space-favorites")
        app.buttons["Space options"].tap()
        app.buttons["Filter"].tapWhenSettled()
        capture("space-filters")
        app.buttons["PDFs"].tap()
        XCTAssertTrue(app.staticTexts["No results"].waitForExistence(timeout: 3))
    }
}
