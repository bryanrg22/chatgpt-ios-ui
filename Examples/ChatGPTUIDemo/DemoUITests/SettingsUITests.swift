import XCTest

final class SettingsUITests: XCTestCase {
    @MainActor func testCapturedGeneralAndThemePickers() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test", "--general"]
        app.launch()
        XCTAssertTrue(app.buttons["settings.startScreen"].waitForExistence(timeout: 5))
        capture("general-captured-controls")
        app.buttons["settings.startScreen"].tap()
        XCTAssertTrue(app.buttons["Codex"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Chat"].exists)
        XCTAssertFalse(app.buttons["Work"].exists)
        capture("general-start-screen-menu")
        app.buttons["Codex"].tap()
        XCTAssertTrue(app.buttons["settings.startScreen"].label.contains("Codex"))
        app.buttons["settings.model"].tap()
        XCTAssertTrue(app.buttons["5.6 Sol"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["5.5"].exists)
        XCTAssertFalse(app.buttons["GPT-5.6 Sol"].exists)
        XCTAssertTrue(
            app.descendants(matching: .any).matching(
                NSPredicate(format: "label CONTAINS %@", "Choose the model version")
            ).firstMatch.exists)
        capture("general-model-menu")
        app.buttons["5.6 Sol"].tap()
        XCTAssertTrue(app.buttons["settings.model"].label.contains("5.6 Sol"))
        capture("general-model-selected")
        app.buttons["Back"].tap()
        XCTAssertTrue(app.buttons["Close settings"].waitForExistence(timeout: 3))
        func revealAccentRow() {
            for _ in 0..<5 {
                let row = app.buttons["settings.accent"]
                if row.isHittable && row.frame.maxY < app.frame.maxY - 90 { break }
                app.swipeUp()
            }
            XCTAssertLessThan(app.buttons["settings.accent"].frame.maxY, app.frame.maxY - 90)
        }
        revealAccentRow()
        app.buttons["settings.appearance"].tap()
        XCTAssertTrue(app.buttons["System"].waitForExistence(timeout: 3))
        capture("appearance-menu-dark")
        app.buttons["Light"].tap()
        XCTAssertTrue(app.buttons["settings.appearance"].label.contains("Light"))
        revealAccentRow()
        app.buttons["settings.accent"].tap()
        XCTAssertTrue(app.buttons["Blue"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Black"].exists)
        capture("accent-menu-light")
        app.buttons["Orange"].tap()
        XCTAssertTrue(app.buttons["settings.accent"].label.contains("Orange"))
        revealAccentRow()
        capture("accent-selected-orange")
        app.buttons["settings.accent"].tap()
        app.buttons["Blue"].tapWhenSettled()
        app.buttons["settings.appearance"].tapWhenSettled()
        app.buttons["Dark"].tapWhenSettled()
        revealAccentRow()
        capture("appearance-restored-dark")
        app.buttons["Close settings"].tap()
        XCTAssertTrue(app.buttons["sidebarButton"].waitForExistence(timeout: 3))
    }
    @MainActor func testSettingsAboutNavigationAndLightDark() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test", "--settings"]
        app.launch()
        XCTAssertTrue(app.buttons["Close settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["alexmorgan"].exists)
        capture("settings-root-dark")
        let notifications = app.buttons["settings.notifications"], voice = app.buttons["settings.voice"]
        for _ in 0..<5 {
            if voice.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(notifications.isHittable)
        XCTAssertTrue(voice.isHittable)
        XCTAssertLessThan(notifications.frame.minY, voice.frame.minY)
        capture("settings-app-order")
        let about = app.buttons["settings.about"]
        for _ in 0..<5 {
            if about.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(about.isHittable)
        about.tap()
        XCTAssertTrue(app.staticTexts["settings.about.version"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["settings.about.version"].label, "1.2026.267 (36747771815)")
        capture("about-dark")
        app.buttons["settings.about.terms"].tap()
        XCTAssertTrue(app.alerts["Link"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["https://example.com/terms"].exists)
        app.alerts["Link"].buttons["Done"].tap()
        app.buttons["settings.about.privacy"].tapWhenSettled()
        XCTAssertTrue(app.alerts["Link"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["https://example.com/privacy"].exists)
        app.alerts["Link"].buttons["Done"].tap()
        app.buttons["Back from About"].tapWhenSettled()
        XCTAssertTrue(app.buttons["Close settings"].waitForExistence(timeout: 3))
        app.buttons["Close settings"].tap()
        XCTAssertTrue(app.buttons["sidebarButton"].waitForExistence(timeout: 3))
        app.terminate()
        app.launchArguments = ["--ui-test", "--light", "--about"]
        app.launch()
        XCTAssertTrue(app.staticTexts["settings.about.appName"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["settings.about.appName"].label, "ChatGPT for iOS")
        capture("about-light")
        app.buttons["Back from About"].tap()
        XCTAssertTrue(app.buttons["Close settings"].waitForExistence(timeout: 3))
        capture("settings-root-light")
    }
}
