import XCTest

final class WidgetUITests: XCTestCase {
    /// Native integration test. Installs one offline demo widget only when it is absent.
    @MainActor func testNativeWidgetGalleryAndSmallLinks() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test"]
        app.launch()
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let existingWidget = springboard.icons.matching(identifier: "Chat UI Demo").matching(
            NSPredicate(format: "value == %@", "Widget")
        ).firstMatch.exists
        let icon = springboard.icons.matching(identifier: "Chat UI Demo").matching(
            NSPredicate(format: "value != %@", "Widget")
        ).firstMatch
        XCTAssertTrue(icon.waitForExistence(timeout: 5))
        icon.press(forDuration: 1.2)
        springboard.buttons["Edit Home Screen"].tap()
        springboard.buttons["Edit"].tap()
        springboard.buttons["Add Widget"].tap()
        let galleryApp = springboard.cells["Chat UI Demo"]
        if !galleryApp.waitForExistence(timeout: 10) {
            // On a freshly created simulator the gallery can open before WidgetKit lists a just-installed extension;
            // searching for it asks the gallery to look the provider up.
            let search = springboard.searchFields["Search Widgets"]
            XCTAssertTrue(search.waitForExistence(timeout: 5))
            search.tap()
            search.typeText("Chat UI Demo")
        }
        XCTAssertTrue(galleryApp.waitForExistence(timeout: 30))
        galleryApp.tap()
        for index in 1...8 {
            XCTAssertTrue(
                springboard.pageIndicators.matching(NSPredicate(format: "value == %@", "page \(index) of 8")).firstMatch
                    .waitForExistence(timeout: 3))
            capture("widget-gallery-" + String(index))
            if index < 8 { springboard.swipeLeft() }
        }
        if existingWidget {
            springboard.buttons["close"].tap()
            XCUIDevice.shared.press(.home)
        } else {
            for _ in 0..<5 { springboard.swipeRight() }
            springboard.buttons[" Add Widget"].tap()
        }
        if springboard.buttons["Done"].exists { springboard.buttons["Done"].tap() }
        XCTAssertTrue(springboard.buttons["Camera"].firstMatch.waitForExistence(timeout: 5))
        capture("widget-small-installed")
        springboard.buttons["Camera"].firstMatch.tap()
        XCTAssertTrue(app.buttons["camera.shutter"].waitForExistence(timeout: 5))
        capture("widget-link-camera")
        XCUIDevice.shared.press(.home)
        springboard.buttons["Voice"].firstMatch.tap()
        XCTAssertTrue(app.buttons["voice.start"].waitForExistence(timeout: 5))
        capture("widget-link-voice")
        app.buttons["Close voice chooser"].tap()
        XCUIDevice.shared.press(.home)
        springboard.buttons["Ask ChatGPT"].firstMatch.tap()
        XCTAssertTrue(app.buttons["composerPrimaryButton"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["camera.shutter"].exists)
        capture("widget-link-chat")
    }
}
