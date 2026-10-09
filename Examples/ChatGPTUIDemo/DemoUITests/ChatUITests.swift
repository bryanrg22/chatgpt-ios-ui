import XCTest

final class ChatUITests: XCTestCase {
    @MainActor func testReferenceScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test"]
        app.launch()
        XCTAssertTrue(app.buttons["attachmentMenu"].waitForExistence(timeout: 5))
        XCTAssertLessThanOrEqual(app.textViews["messageComposer"].frame.height, 32)
        capture("home")
        app.buttons["attachmentMenu"].tap()
        capture("attachment-menu")
        app.tap()
        app.buttons["sidebarButton"].tap()
        capture("sidebar")
        app.buttons["Settings"].tap()
        capture("settings")
    }
    @MainActor func testConversationFeedbackAndDictation() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test", "--conversation"]
        app.launch()
        XCTAssertTrue(app.buttons["Good response"].waitForExistence(timeout: 5))
        capture("conversation-dark")
        app.buttons["Good response"].tap()
        XCTAssertFalse(app.buttons["Bad response"].exists)
        app.buttons["Good response"].tap()
        XCTAssertTrue(app.buttons["Bad response"].exists)
        app.buttons["Bad response"].tap()
        XCTAssertTrue(app.buttons["Close feedback"].waitForExistence(timeout: 3))
        capture("feedback")
        app.buttons["Close feedback"].tap()
        XCTAssertFalse(app.buttons["Good response"].exists)
        app.buttons["Bad response"].tap()
        XCTAssertTrue(app.buttons["Good response"].exists)
        app.buttons["Dictate"].tap()
        XCTAssertTrue(app.buttons["Stop dictation"].waitForExistence(timeout: 3))
        capture("dictation-silent")
        app.buttons["Stop dictation"].tap()
        XCTAssertTrue(app.buttons["Dictate"].exists)
        app.buttons["More response actions"].tap()
        capture("response-menu")
        app.buttons["Read Aloud"].tap()
        XCTAssertTrue(app.buttons["Close player"].waitForExistence(timeout: 3))
        capture("read-aloud")
        app.buttons["Close player"].tap()
    }
    @MainActor func testLightAndExpandedDraft() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test", "--light", "--conversation"]
        app.launch()
        XCTAssertTrue(app.buttons["Good response"].waitForExistence(timeout: 5))
        capture("conversation-light")
        app.terminate()
        app.launchArguments = ["--ui-test", "--long-draft"]
        app.launch()
        XCTAssertTrue(app.buttons["Expand composer"].waitForExistence(timeout: 5))
        XCTAssertLessThanOrEqual(app.textViews["messageComposer"].frame.height, 186)
        XCTAssertGreaterThan(app.textViews["messageComposer"].frame.height, 150)
        capture("composer-long")
        app.buttons["Expand composer"].tap()
        XCTAssertTrue(app.buttons["Collapse composer"].waitForExistence(timeout: 3))
        capture("composer-expanded")
        app.buttons["Collapse composer"].tap()
        XCTAssertTrue(app.buttons["Expand composer"].waitForExistence(timeout: 3))
    }
    @MainActor func testComposeSendCancelAndDrawer() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test"]
        app.launch()
        let composer = app.textViews["messageComposer"]
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["composerPrimaryButton"].label, "Start voice")
        composer.tap()
        composer.typeText("Hello")
        XCTAssertEqual(app.buttons["composerPrimaryButton"].label, "Send message")
        app.buttons["composerPrimaryButton"].tap()
        XCTAssertEqual(app.buttons["composerPrimaryButton"].label, "Stop response")
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3))
        app.buttons["composerPrimaryButton"].tap()
        let idle = NSPredicate(format: "label == %@", "Start voice")
        expectation(for: idle, evaluatedWith: app.buttons["composerPrimaryButton"])
        waitForExpectations(timeout: 3)
        app.buttons["sidebarButton"].tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 3))
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["Close settings"].waitForExistence(timeout: 3))
    }
}
