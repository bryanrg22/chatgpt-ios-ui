import XCTest

final class MemoryUITests: XCTestCase {
    @MainActor func testMemorySummaryAndAbout() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test"]
        app.launch()
        app.buttons["sidebarButton"].tap()
        app.buttons["Settings"].tapWhenSettled()
        app.buttons["Memory"].tapWhenSettled()
        XCTAssertTrue(app.buttons["memory.options"].waitForExistence(timeout: 3))
        capture("memory")
        app.buttons["memory.options"].tap()
        app.buttons["About memory"].tapWhenSettled()
        XCTAssertTrue(app.buttons["memory.gotIt"].waitForExistence(timeout: 3))
        capture("memory-about")
        app.buttons["memory.gotIt"].tap()
        app.buttons["memory.options"].tapWhenSettled()
        app.buttons["Refresh summary"].tapWhenSettled()
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Updated just now")).firstMatch
                .waitForExistence(timeout: 3))
        app.buttons["Back"].tap()
        XCTAssertTrue(app.buttons["Close settings"].waitForExistence(timeout: 3))
    }
}
