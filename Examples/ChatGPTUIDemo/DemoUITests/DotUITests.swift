import XCTest

final class DotUITests: XCTestCase {
    @MainActor func testDotNativeTextSelection() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test", "--dot-summary"]
        app.launch()
        app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "One last reminder:")).firstMatch.press(
            forDuration: 0.8)
        app.buttons["Select text"].tap()
        let selected = app.textViews.matching(NSPredicate(format: "identifier BEGINSWITH %@", "dot.message."))
            .firstMatch
        XCTAssertTrue(selected.waitForExistence(timeout: 3))
        capture("dot-selection-before-touch")
        XCTAssertTrue(app.menuItems["Copy"].waitForExistence(timeout: 3))
        app.menuItems["Copy"].tap()
        capture("dot-selection-after-copy")
    }
    @MainActor func testDotConnectedSummarySelectionAndPreview() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test", "--dot-connected"]
        app.launch()
        XCTAssertTrue(app.staticTexts["0:38"].waitForExistence(timeout: 3))
        capture("dot-connected-full")
        XCTAssertEqual(app.buttons["Mute dot call"].value as? String, "Off")
        app.buttons["Mute dot call"].tap()
        XCTAssertEqual(app.buttons["Mute dot call"].value as? String, "On")
        capture("dot-connected-muted")
        app.buttons["Minimize dot call"].tap()
        capture("dot-connected-minimized")
        app.buttons["Expand dot call"].tap()
        app.buttons["End dot call"].tap()
        XCTAssertTrue(app.buttons["dot.menu"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["Call ended"].exists)
        let assistant = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "One last reminder:"))
            .firstMatch
        assistant.press(forDuration: 0.8)
        app.buttons["Select text"].tap()
        XCTAssertTrue(
            app.textViews.matching(NSPredicate(format: "identifier BEGINSWITH %@", "dot.message.")).firstMatch
                .waitForExistence(timeout: 3))
        capture("dot-native-selection")
        XCTAssertTrue(app.menuItems["Copy"].waitForExistence(timeout: 3))
        app.terminate()
        app.launchArguments = ["--ui-test", "--dot-summary"]
        app.launch()
        XCTAssertTrue(app.staticTexts["7:23 · Call ended"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Delivered"].exists)
        capture("dot-call-summary-delivered")
        app.staticTexts["7:23 · Call ended"].press(forDuration: 0.8)
        XCTAssertTrue(app.buttons["Copy"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Reply"].exists)
        XCTAssertFalse(app.buttons["Select text"].exists)
        capture("dot-call-summary-menu")
        app.buttons["Reply"].tap()
        app.buttons["Cancel dot reply"].tap()
        app.terminate()
        app.launchArguments = ["--ui-test", "--dot-summary", "--dot-read"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Read"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["Delivered"].exists)
        capture("dot-call-summary-read")
        app.terminate()
        app.launchArguments = ["--ui-test", "--dot-connected", "--dot-system-preview"]
        app.launch()
        XCTAssertTrue(app.buttons["Mute system call preview"].waitForExistence(timeout: 3))
        capture("dot-system-call-previews")
        app.buttons["Mute system call preview"].tap()
        XCTAssertEqual(app.buttons["Mute system call preview"].value as? String, "On")
        capture("dot-system-call-previews-muted")
    }
    @MainActor func testDotSendReplyCallAndComputer() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test"]
        app.launch()
        app.buttons["sidebarButton"].tap()
        app.buttons["Your dot"].tap()
        XCTAssertTrue(app.buttons["dot.menu"].waitForExistence(timeout: 3))
        capture("dot-home")
        let field = app.textFields["dot.composer"]
        field.tap()
        field.typeText("Please review the garden checklist.")
        app.buttons["Send dot message"].tap()
        XCTAssertTrue(app.staticTexts["Please review the garden checklist."].waitForExistence(timeout: 3))
        app.staticTexts["Please review the garden checklist."].press(forDuration: 0.8)
        XCTAssertTrue(app.buttons["Reply"].waitForExistence(timeout: 3))
        capture("dot-message-menu")
        app.buttons["Reply"].tap()
        field.tap()
        field.typeTextVerified("Keep this draft")
        app.buttons["Cancel dot reply"].tap()
        XCTAssertTrue((field.value as? String ?? "").contains("Keep this draft"))
        app.buttons["Call dot"].tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.keyboards.firstMatch)
        waitForExpectations(timeout: 3)
        capture("dot-calling")
        app.buttons["End dot call"].tap()
        XCTAssertTrue(app.buttons["dot.menu"].waitForExistence(timeout: 3))
        app.buttons["dot.menu"].tap()
        capture("dot-menu")
        app.buttons["Your dot’s computer"].tap()
        XCTAssertTrue(app.buttons["Close dot computer"].waitForExistence(timeout: 3))
        capture("dot-computer")
        app.buttons["Show computer keyboard"].tap()
        capture("dot-computer-keyboard")
        app.buttons["Close dot computer"].tap()
        XCTAssertTrue((field.value as? String ?? "").contains("Keep this draft"))
    }
    @MainActor func testFailedDotCallAndClassicVoiceEndpoints() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test", "--dot-failed"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Call failed"].waitForExistence(timeout: 3))
        capture("dot-failed-minimized")
        app.buttons["Try again"].tap()
        XCTAssertTrue(app.staticTexts["Calling…"].waitForExistence(timeout: 3))
        capture("dot-calling-minimized")
        app.buttons["End dot call"].tap()
        XCTAssertTrue(app.buttons["dot.menu"].waitForExistence(timeout: 3))
        app.terminate()
        app.launchArguments = ["--ui-test", "--voice-classic"]
        app.launch()
        XCTAssertTrue(app.buttons["voice.end"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["voice.settings"].exists)
        capture("voice-classic-idle")
        app.buttons["Voice attachments"].tap()
        app.buttons["Share screen"].tap()
        XCTAssertTrue(app.buttons["voice.sharing"].waitForExistence(timeout: 3))
        capture("voice-classic-idle-sharing")
        app.buttons["voice.end"].tap()
        XCTAssertTrue(app.buttons["composerPrimaryButton"].waitForExistence(timeout: 3))
    }
}
