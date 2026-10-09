import XCTest

final class PluginsUITests: XCTestCase {
    @MainActor func testPluginPermissionAndTryInChat() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test"]
        app.launch()
        app.buttons["sidebarButton"].tap()
        app.buttons["Settings"].tap()
        app.buttons["Plugins"].tap()
        XCTAssertTrue(app.buttons["plugins.row.gmail"].waitForExistence(timeout: 3))
        capture("plugins")
        app.buttons["plugins.row.gmail"].tap()
        capture("plugin-detail")
        app.buttons["plugins.settings"].tap()
        app.buttons["plugins.permissions"].tap()
        capture("plugin-permissions")
        app.buttons["plugins.permission.Allow read actions"].tap()
        XCTAssertTrue(app.buttons["plugins.resetPermission"].isEnabled)
        app.buttons["plugins.resetPermission"].tap()
        XCTAssertFalse(app.buttons["plugins.resetPermission"].isEnabled)
        app.buttons["Back"].tap()
        app.buttons["Back"].tap()
        app.buttons["plugins.tryInChat"].tap()
        XCTAssertTrue(app.textViews["messageComposer"].waitForExistence(timeout: 3))
        XCTAssertTrue((app.textViews["messageComposer"].value as? String ?? "").contains("@Gmail"))
    }
}
