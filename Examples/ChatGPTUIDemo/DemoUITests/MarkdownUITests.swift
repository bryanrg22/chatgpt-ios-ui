import XCTest

final class MarkdownUITests: XCTestCase {
    @MainActor func testRoundedInlineCodeSelectionAndLinkBothAppearances() {
        let app = XCUIApplication()
        for appearance in ["dark", "light"] {
            app.launchArguments = ["--ui-test", "--inline-code"] + (appearance == "light" ? ["--light"] : [])
            app.launch()
            let text = app.textViews["markdown.inlineCode"].firstMatch
            XCTAssertTrue(text.waitForExistence(timeout: 5))
            XCTAssertTrue((text.value as? String ?? "").contains("Use print(\"Hello!\") as a code example."))
            capture("inline-code-" + appearance)
            text.coordinate(withNormalizedOffset: CGVector(dx: 0.20, dy: 0.13)).press(forDuration: 0.8)
            XCTAssertTrue(app.menuItems["Copy"].waitForExistence(timeout: 3))
            capture("inline-code-selection-" + appearance)
            app.menuItems["Copy"].tap()
            let link = app.links["garden guide"]
            XCTAssertTrue(link.waitForExistence(timeout: 3))
            link.tap()
            XCTAssertTrue(app.alerts["Link"].waitForExistence(timeout: 3))
            XCTAssertTrue(app.staticTexts["https://example.com/garden-guide"].exists)
            app.alerts["Link"].buttons["Done"].tap()
            app.terminate()
        }
    }
    @MainActor func testTableCodeAlignmentWrappingSelectionAndScrollBothAppearances() {
        let app = XCUIApplication()
        for appearance in ["dark", "light"] {
            app.launchArguments = ["--ui-test", "--table-code"] + (appearance == "light" ? ["--light"] : [])
            app.launch()
            func cell(_ value: String) -> XCUIElement {
                app.textViews.matching(NSPredicate(format: "value == %@", value)).firstMatch
            }
            let mint = cell("mint guide"), water = cell("water_seedlings_gently"), sun = cell("morning_sunlight")
            XCTAssertTrue(mint.waitForExistence(timeout: 5))
            XCTAssertTrue(water.exists)
            XCTAssertTrue(sun.exists)
            XCTAssertLessThan(mint.frame.midX, water.frame.midX)
            XCTAssertLessThan(water.frame.midX, sun.frame.midX)
            XCTAssertGreaterThan(water.frame.height, cell("basil").frame.height)
            capture("table-code-" + appearance)
            mint.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.2)).press(forDuration: 0.8)
            XCTAssertTrue(app.menuItems["Copy"].waitForExistence(timeout: 3))
            capture("table-code-selection-" + appearance)
            app.menuItems["Copy"].tap()
            app.links["guide"].tapWhenSettled()
            XCTAssertTrue(app.alerts["Link"].waitForExistence(timeout: 3))
            app.alerts["Link"].buttons["Done"].tap()
            let wide = app.scrollViews.matching(identifier: "markdown.table").element(boundBy: 1)
            let last = cell("eight")
            XCTAssertGreaterThan(last.frame.maxX, app.frame.maxX)
            wide.swipeLeft()
            XCTAssertLessThanOrEqual(last.frame.maxX, app.frame.maxX)
            XCTAssertTrue(last.isHittable)
            capture("table-code-scrolled-" + appearance)
            app.terminate()
        }
    }
    @MainActor func testMarkdownCodeLinkAndSelection() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test", "--markdown"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Garden notes"].waitForExistence(timeout: 3))
        capture("markdown-heading-list")
        app.swipeUp()
        XCTAssertTrue(app.buttons["markdown.code.copy"].waitForExistence(timeout: 3))
        capture("markdown-code-table")
        app.buttons["markdown.code.copy"].tap()
        XCTAssertEqual(app.buttons["markdown.code.copy"].label, "Code copied")
        let link = app.links["garden guide"]
        XCTAssertTrue(link.waitForExistence(timeout: 3))
        link.tap()
        XCTAssertTrue(app.alerts["Link"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["https://example.com/garden-guide"].exists)
        app.buttons["Done"].tap()
        app.staticTexts["markdown.code.content"].press(forDuration: 0.8)
        capture("markdown-code-selection")
        XCTAssertTrue(app.menuItems["Copy"].waitForExistence(timeout: 3))
    }
}
