import ChatGPTUI
import SwiftUI
import Testing
import UIKit

@testable import ChatGPTUIDemo

/// One light and one dark reference image for every `DemoScreen`.
/// Each case starts from the demo's own fixtures, so the images show exactly what the demo shows.
@MainActor @Suite(.serialized) struct ScreenSnapshotTests {
    nonisolated static let appearances: [UIUserInterfaceStyle] = [.light, .dark]

    @Test(arguments: DemoScreen.allCases, appearances)
    func screen(_ id: DemoScreen, appearance: UIUserInterfaceStyle) async throws {
        let state = ChatState()
        installDemoFixtures(state)
        applyDemoScreen(id, to: state, baseArguments: ["--ui-test"])
        state.appearance = appearance == .light ? "Light" : "Dark"
        try await Screen.assertSnapshot(
            demoChatView(state: state), named: id.rawValue, appearance: appearance,
            precision: Self.precision(for: id), testName: "screen")
    }

    /// Codex shows a running task's system activity indicator, which never stops spinning (about 85 pixels change
    /// every half second, measured). The library's GPU comparison reports that as roughly 0.2% of pixels, so this
    /// one screen allows 0.4%; every other screen keeps the strict default.
    static func precision(for id: DemoScreen) -> Double { id == .codex ? 0.996 : 0.999 }
}
