# ChatGPT iOS UI skeleton

An **unofficial, independent SwiftUI interface study** with an offline demo. Not affiliated with, endorsed by, or distributed by OpenAI. ChatGPT and OpenAI names belong to their respective owners.

This is a starting implementation based on observed October 7–8, 2026 app screens. It is **not a complete or pixel-certified replica**. See [reference coverage](REFERENCE_COVERAGE.md) for the distinction between observed screens, approximations, and unobserved destinations.

## Run

Requires Xcode 26.4 or newer, Swift 6.2+, iOS 26+. Open `Examples/ChatGPTUIDemo/ChatGPTUIDemo.xcodeproj`, choose the `ChatGPTUIDemo` scheme and an iOS simulator, then Run. The running demo needs no account, API key, network, microphone, photos, or camera permissions. A first build resolves the pinned official Swift Markdown dependency over the network. Sending a message produces a local simulated response. Voice and read-aloud are presentation previews. Dictation starts with the observed silent waveform; the host may supply waveform levels and transcript text.

The demo project is generated from `Examples/ChatGPTUIDemo/project.yml` using [XcodeGen](https://github.com/yonaskolb/XcodeGen) 2.45.4. The generated project is committed, so you only need XcodeGen after editing `project.yml`:

```sh
cd Examples/ChatGPTUIDemo
xcodegen generate
```

Unit tests run on the Mac without a simulator:

```sh
swift test
```

Screenshot tests, UI tests and the accessibility audit run on an iPhone 17 Pro simulator with iOS 27.0. See [TESTING.md](TESTING.md).

## Integrate

Add this directory or your published repository as a Swift package, import `ChatGPTUI`, and own a `ChatState` at your app boundary:

```swift
@State private var chat = ChatState()

var body: some View {
    ChatGPTView(state: chat)
        .onAppear {
            chat.onAction = { action in
                // Handle send/stop/attachments/model/navigation in your own host.
                // For send, capture chat.responseID before starting an async task.
            }
        }
}
```

The UI has no networking or automation dependency. `send()` supplies a response identity. Apply incremental text with `updateResponse(id:text:finished:)`. Stopped or superseded response IDs are rejected. Retry emits `retry(originalID:responseID:)`: the original ID identifies the requested turn, and the new response ID identifies the replacement stream. Removed turns lose their feedback/copy/player state. Editing carries that message’s attachments; cancellation restores the previous draft and its attachments. The host implements copy/share/read-aloud actions; the demo implements pasteboard copying and synthetic text streaming. UI-owned state covers drafts, selections, routes, and feedback. The host can supply message arrays and profile labels.

`Sources/ChatGPTUI` contains the reusable interface and presentation state. `Examples/ChatGPTUIDemo` is the demo app, with deliberately separate fake behavior in `Demo`, its widget extension in `WidgetDemo`, and its screenshot and UI tests. `Tests` checks state transitions on macOS without a simulator; UI code is iOS-only.

## Contributing

Include the app version, iOS version, device size, text size, appearance, before/after screenshots, and the transition being matched. Never commit screenshots containing private chat titles, contact information, or account data. Capture motion for transitions; a single screenshot does not establish animation fidelity. Keep implementation separate from backend integrations.

Do not add a font, logo, or extracted asset without permission to redistribute it. See [asset provenance](ASSETS.md). Source code is available under the [MIT License](LICENSE). Bundled third-party assets and dependencies keep their own terms; see [asset provenance](ASSETS.md).

The camera panel accepts any SwiftUI preview through `ChatGPTView(state:cameraPreview:)` or `CameraPanel` directly. The shipped synthetic paper preview contains no reference-photo pixels and requests no permissions. Camera actions are presentation events; the host owns real capture. Camera opening and Chat/Work selection use provisional native animation because reference durations/easing have not been measured.

Voice presentation is owned by `chat.voice`. `setVoice(true)` first opens the captured chooser; `startVoice()` emits `beginVoice`, and later entries resume the selected profile directly. Closing the chooser emits no audio-start action. Mute, profile/language selection, draft edits/submission, and end emit host actions. The sidebar emits a `voiceNavigation` intent while preserving the session. Captured attachment, sharing, live-camera and effort actions use `chat.voice.onAction`. Media requests do not activate devices: the host supplies `isSharingScreen`, `variant`, and `showsLiveCamera` after its own result. The demo explicitly supplies local preview outcomes. `transcript` is caller-owned and determines the compact orb layout; `orbDiameter` optionally accepts a finite host-provided diameter. The captured current/classic variants control settings, gauge and sharing controls. The camera preview passed to `ChatGPTView` also supplies the full-screen live-video preview. The demo produces no audio. Only the captured Breeze profile is included; hosts can supply additional `VoiceProfile` values and language entries.

Codex and Your dot are independent presentation states at `chat.codex` and `chat.dot`, each with its own typed `onAction` callback. They preserve local tasks/messages across navigation, accept host updates, and perform no connections or calls themselves. Their captured pages are interactive; uncaptured destination details are identified as reference gaps.

Health and Finance presentation states are exposed at `chat.health` and `chat.finance`, with typed `FeatureWorkspaceAction` callbacks. Open them through Customize. Health starts at the captured feature introduction and local setup; Finance defaults to empty host data. The executable installs explicit fictional fixtures for both workspaces. Setup/provider choices emit intents and never perform authentication or read personal data. Disconnected/loading/error whole-workspace variants are still reference gaps; see `REFERENCE_COVERAGE.md`.

Finance and Health hosts can replace `chat.finance.data` (`FinancePresentationData`) and `chat.health.data` (`HealthPresentationData`) at any time without resetting drafts, selected tabs, or setup progress. Finance data includes spending period/total/categories/chart fractions, dashboard values, account groups/rows, chat summaries, and credit-provider display data. `transactions` and `currencyCode` are independently writable. Health data includes introduction/activity metrics with chart samples, provider identities/connection display, and chat summaries. Provider chooser status is keyed by provider ID in `providerStatus`. Empty arrays remain empty; package views never substitute sample records. Account/chat selections emit `.openAccount(id)` / `.openChat(id)`; providers emit `.connectProvider(id)`.

`beginCashChat()` inserts only the user request and emits `.startChat`; the host appends assistant messages to `chatMessages`. The demo's response and all feature sample values live in `Demo/ChatGPTDemoApp.swift`. Finite chart samples are bounded before layout; these presentation limits are not financial or medical calculations.

The app now also embeds a separate offline WidgetKit demo extension. Import `ChatGPTWidgets` for its public presentation data, SwiftUI views, and typed navigation URLs. See [WIDGETS.md](WIDGETS.md) for observed families, host integration, native verification, and the tall-family SDK limitation.

Space uses `chat.space`, with empty default items, host-owned load state, and typed `SpaceAction` callbacks. `ChatGPTView(state:spaceImageProvider:)` resolves supplied item keys into local SwiftUI images; the same parameter is available with the camera-preview initializer. The demo supplies fictional item labels, while missing images remain visible placeholders. Search, tabs, layout, filters and favorites are local presentation state. Uncaptured creation/edit/deletion destinations emit host intents. See [Space coverage](SPACE_REFERENCE.md).

Connected Dot calls and delivery receipts are explicitly supplied by the host. The package starts no timer or real call. [Dot integration](DOT_REFERENCE.md) documents connected elapsed time, mute/end events, call-summary messages, receipt ordering, native text selection, and visibly labeled system-call previews. Those previews do not register an ActivityKit Live Activity or CallKit session.

Chat media uses immutable `ChatMedia` identities, opaque image keys and optional host-supplied video duration. Pass `mediaImageProvider` and `mediaVideoProvider` to `ChatGPTView` to resolve those keys into local images or moving views. Populate `chat.photoPicker.items` yourself; the package never reads the device photo library. Sending carries selected media in both the user message and typed send action. Sent videos default to the captured paused Play card. Hosts may set `chat.videoCardPresentations[id] = .hostPreview` to use their supplied moving view; this does not start playback or infer an autoplay policy. The shared full-screen viewer forwards favorite/download/edit/resize/eraser or video-fit intents. The demo supplies original generated garden artwork and a silent procedural moving fixture. See [media coverage](MEDIA_REFERENCE.md).

Assistant rich text uses the official Swift Markdown parser and a separate SF-themed `ChatGPTMarkdownView`. The host handles `ChatAction.markdown` for copy/link/image/unsupported-content intents. No HTML execution, remote-image fetching or code execution occurs. See [Markdown behavior and limits](MARKDOWN_REFERENCE.md).

Explore expands inside the sidebar. Sites starts a Work draft with typed context; Projects exposes transactional name/icon/memory settings and a guarded host creation intent. Loaded directory content is injectable in the standalone destination views. See [Explore coverage](EXPLORE_REFERENCE.md).

Images uses an empty host-owned template catalog at `chat.images` and an `imagesArtwork` view resolver. The demo installs original generated gallery fixtures ([provenance and prompts](GALLERY_ARTWORK.md)). Try emits a typed request; the offline demo alone supplies the subsequent Work task/questions. See [Work task integration](WORK_TASK_REFERENCE.md).

Settings account and About metadata live at `chat.settings.account` and `chat.settings.about`, with empty defaults. Supply app/version/build and legal URLs, then handle `chat.settings.onAction` for typed route and legal-link requests. No browser opens automatically. Existing `chat.username`, `displayName`, and `email` forward to the account model. The executable supplies its fictional profile and captured reference-version display explicitly. See [Settings coverage](SETTINGS_REFERENCE.md).
