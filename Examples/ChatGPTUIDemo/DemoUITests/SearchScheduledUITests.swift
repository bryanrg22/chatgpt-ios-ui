import XCTest

final class SearchScheduledUITests: XCTestCase {
    @MainActor func testSearchAndScheduledPersistence() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test"]
        app.launch()
        app.buttons["sidebarButton"].tap()
        app.buttons["Search chats"].tapWhenSettled()
        let search = app.textFields["search.input"]
        XCTAssertTrue(search.waitForExistence(timeout: 3))
        search.tapToFocus()
        search.typeText("design")
        app.buttons["search.category.Images"].tap()
        capture("search-images")
        app.buttons["Clear search"].tap()
        app.buttons["Close search"].tapWhenSettled()
        app.buttons["Scheduled"].tapWhenSettled()
        XCTAssertTrue(app.buttons["schedule.new"].waitForExistence(timeout: 3))
        capture("scheduled")
        app.buttons["schedule.new"].tap()
        XCTAssertTrue(app.buttons["Cancel task"].waitForExistence(timeout: 3))
        app.buttons["Cancel task"].tap()
        XCTAssertFalse(app.staticTexts["Fixture task"].exists)
        app.buttons["schedule.new"].tap()
        let title = app.textFields["schedule.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        title.tapToFocus()
        title.typeText("Fixture task")
        let instructions = app.textViews["schedule.instructions"]
        instructions.tapToFocus()
        instructions.typeText("Summarize design notes")
        app.buttons["schedule.save"].tap()
        XCTAssertTrue(app.staticTexts["Fixture task"].waitForExistence(timeout: 3))
        app.buttons["Open sidebar"].tap()
        app.buttons["New chat"].tapWhenSettled()
        app.buttons["sidebarButton"].tapWhenSettled()
        app.buttons["Scheduled"].tapWhenSettled()
        XCTAssertTrue(app.staticTexts["Fixture task"].waitForExistence(timeout: 3))
    }
}
