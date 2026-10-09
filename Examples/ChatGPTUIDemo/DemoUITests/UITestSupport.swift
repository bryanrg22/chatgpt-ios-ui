import XCTest

/// Helpers shared by every UI test case.
extension XCTestCase {
    @MainActor func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
