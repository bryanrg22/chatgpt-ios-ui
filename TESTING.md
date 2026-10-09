# Testing

Four test suites guard this project. CI runs all of them (see [`.github/workflows/ci.yml`](.github/workflows/ci.yml)).

| Suite | Location | What it checks | Runs on |
|---|---|---|---|
| Unit tests | `Tests/ChatGPTUITests` | Presentation state: sending, streaming, editing, navigation, feature workspaces, Markdown parsing | macOS host (`swift test`) |
| Screenshot tests | `Examples/ChatGPTUIDemo/SnapshotTests` | One light and one dark reference image for every screen in `DemoScreen` | iPhone 17 Pro simulator, iOS 27.0 |
| UI tests | `Examples/ChatGPTUIDemo/DemoUITests` | Real taps and typing through the demo app, one file per feature | iPhone 17 Pro simulator, iOS 27.0 |
| Accessibility audit | `Examples/ChatGPTUIDemo/DemoUITests/AccessibilityAuditUITests.swift` | Apple's accessibility audit on every `DemoScreen`, light and dark | iPhone 17 Pro simulator, iOS 27.0 |

## One list of screens

[`Examples/ChatGPTUIDemo/Shared/DemoScreen.swift`](Examples/ChatGPTUIDemo/Shared/DemoScreen.swift) names every screen the
demo can open directly. The same list drives three things:

- the demo app: `--screen <name>` opens that screen (for example `--screen settingsAbout --light`);
- the screenshot tests: one light and one dark image per case;
- the accessibility audit: one audit per case, in both appearances.

To add a screen, add a case to `DemoScreen` and describe how to open it in `configureDemoScreen` or
`demoLaunchArguments` in [`Demo/DemoFixtures.swift`](Examples/ChatGPTUIDemo/Demo/DemoFixtures.swift). Then record its
reference images and audit baseline as described below.

## Running the tests

Unit tests need no simulator:

```sh
swift test
```

Screenshot references are only valid on the exact simulator they were recorded on. Create it once:

```sh
xcrun simctl create "iPhone 17 Pro (iOS 27)" "iPhone 17 Pro" com.apple.CoreSimulator.SimRuntime.iOS-27-0
```

Then, from `Examples/ChatGPTUIDemo`:

```sh
xcodebuild test -project ChatGPTUIDemo.xcodeproj -scheme ChatGPTUIDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro (iOS 27)' -only-testing:ChatGPTUISnapshotTests
```

```sh
xcodebuild test -project ChatGPTUIDemo.xcodeproj -scheme ChatGPTUIDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro (iOS 27)' -only-testing:ChatGPTUIDemoUITests
```

## Screenshot tests

Each screen is rendered in a fresh, real window of the demo app, so Liquid Glass, materials and safe areas look the way
they do on device. Images are 1× (one pixel per point) 8-bit sRGB, which keeps the repository small while still catching
a one-point shift. A test fails when more than 0.1% of pixels differ visibly from the reference.

When a change is meant to alter how a screen looks:

1. Re-record with `TEST_RUNNER_SNAPSHOT_TESTING_RECORD=all` in front of the `xcodebuild test` command above.
2. Open every changed PNG under `SnapshotTests/__Snapshots__` and check it shows what you intended.
3. Commit the images together with the code change, and include before/after images in the pull request.

References in this repository are recorded by CI (Actions → CI → Run workflow → *Re-record every screenshot
reference*), so they match the CI machine exactly. Images recorded with a different Xcode or iOS version will not match.

Known, deliberate tolerances, both measured:

- The Codex screen shows a running task's system spinner, which never stops; that one screen allows 0.4% difference.
- Each capture waits 2 seconds before rendering, because Liquid Glass over a freshly shown card keeps adapting for
  about 1.5 seconds.

## Accessibility audit

[`AccessibilityAuditBaseline.txt`](Examples/ChatGPTUIDemo/DemoUITests/AccessibilityAuditBaseline.txt) lists every issue
the audit finds today, one per line: screen, appearance, issue and element. The test fails on any issue that is not in
the file, so a change cannot make accessibility worse. The file is also a to-do list: fix an issue, delete its line.

Most entries are fixed font sizes that ignore the system text size (Dynamic Type), small tap targets, and low contrast.
To regenerate the file after fixing issues, run the audit test with `TEST_RUNNER_ACCESSIBILITY_AUDIT_RECORD=1` and
review the diff before committing it.
