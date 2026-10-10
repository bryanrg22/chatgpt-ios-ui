import XCTest

final class CodexUITests: XCTestCase {
    @MainActor func testCodexTaskAndConnectionFlow() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test"]
        app.launch()
        app.buttons["sidebarButton"].tap()
        app.buttons["Codex"].tapWhenSettled()
        XCTAssertTrue(app.buttons["codex.menu"].waitForExistence(timeout: 3))
        capture("codex-home")
        app.buttons["New Codex task"].tap()
        let field = app.textFields["codex.composer"]
        field.tapToFocus()
        field.typeText("Create a garden guide")
        app.buttons["Send Codex message"].tap()
        XCTAssertTrue(app.buttons["Stop Codex task"].waitForExistence(timeout: 3))
        capture("codex-running")
        app.buttons["Stop Codex task"].tap()
        field.tapToFocus()
        field.typeTextVerified("Add a planting checklist")
        app.buttons["Send Codex message"].tap()
        app.buttons["Stop Codex task"].tapWhenSettled()
        app.buttons["Back to Codex"].tapWhenSettled()
        XCTAssertTrue(
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Create a garden guide")).firstMatch
                .waitForExistence(timeout: 3))
        app.buttons["codex.menu"].tap()
        capture("codex-menu")
        app.buttons["Settings"].tap()
        capture("codex-settings")
        app.buttons["Close Codex settings"].tap()
        app.buttons["codex.menu"].tapWhenSettled()
        app.buttons["Add connection"].tapWhenSettled()
        XCTAssertTrue(app.buttons["Pair manually instead"].waitForExistence(timeout: 3))
        capture("codex-scanner")
        app.buttons["Pair manually instead"].tap()
        let code = app.textFields["codex.pairing-code"]
        XCTAssertTrue(code.waitForExistence(timeout: 3))
        code.tapToFocus()
        code.typeText("SAMPLE-CODE")
        capture("codex-manual-pairing")
        app.buttons["Cancel"].tap()
        app.buttons["Close connection scanner"].tapWhenSettled()
    }
}
