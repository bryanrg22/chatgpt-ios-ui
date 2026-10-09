# ChatGPT iOS UI

A reusable SwiftUI UI skeleton inspired by ChatGPT for iPhone. Explore chat, media, rich text and native Liquid Glass controls in an offline demo, then connect your own model and services. Light and dark presentations are included; full app parity is still a work in progress.

[![CI](https://github.com/bryanrg22/chatgpt-ios-ui/actions/workflows/ci.yml/badge.svg)](https://github.com/bryanrg22/chatgpt-ios-ui/actions/workflows/ci.yml)
![Swift 6.2](https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white)
![iOS 26+](https://img.shields.io/badge/iOS-26%2B-000000?logo=apple&logoColor=white)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

<p align="center">
  <img src="docs/images/banner.png" alt="Five screens of the recreation: the home screen, a Markdown answer, the voice chooser, Finances and Codex" width="100%">
</p>

> [!NOTE]
> **Unofficial.** This project is not affiliated with, endorsed by, or sponsored by OpenAI. ChatGPT is a trademark of OpenAI. The recreation follows ChatGPT for iOS version 1.2026.267, observed in October 2026.

[Run the demo](#try-the-demo) · [Integrate](docs/INTEGRATION.md) · [Contribute](CONTRIBUTING.md) · [Report a mismatch](https://github.com/bryanrg22/chatgpt-ios-ui/issues/new/choose)

## Light and dark

<table>
  <tr><th>Light</th><th>Dark</th></tr>
  <tr>
    <td><img src="Examples/ChatGPTUIDemo/SnapshotTests/__Snapshots__/ScreenSnapshotTests/screen.chatConversation-light.png" width="260" alt="ChatGPT UI skeleton conversation in light mode"></td>
    <td><img src="Examples/ChatGPTUIDemo/SnapshotTests/__Snapshots__/ScreenSnapshotTests/screen.chatConversation-dark.png" width="260" alt="ChatGPT UI skeleton conversation in dark mode"></td>
  </tr>
</table>

These are screenshots of this project's demo with fictional messages, not captures of the official app. The banner above shows more feature areas. Browse the [screen catalog](Examples/ChatGPTUIDemo/Shared/DemoScreen.swift) and [coverage notes](docs/fidelity/ROUTE_COVERAGE.md) for what is implemented, approximate or still TODO.

## What's inside

- **`ChatGPTUI`** — SwiftUI views and presentation state for the app: chat and composer, sidebar, voice, camera, photos and video, rich Markdown with code and tables, settings, Codex, Your dot calls, Health, Finances, Space, Images, Work tasks, Sites, Projects, Plugins, Memory, Search and Scheduled.
- **`ChatGPTWidgets`** — Home Screen widget views with deep links.
- **A demo app** in [`Examples/ChatGPTUIDemo`](Examples/ChatGPTUIDemo) with fictional data, a real WidgetKit extension, and a `--screen <name>` shortcut that opens any of the 40 catalogued screens directly.
- **Four test suites** — unit, screenshot, UI and accessibility. CI always checks format, project sync, unit tests and the iOS 26 SDK build. Simulator suites run automatically for public repositories; while private, they require a manual Actions run. See [TESTING.md](TESTING.md).

The package draws the interface and keeps presentation state only. It makes no network calls, needs no API keys, and never touches the microphone, camera or photo library: your app supplies all of that.

## Requirements

- Xcode 26.4 or newer (the screenshot references are recorded with Xcode 27.0)
- iOS 26 or newer
- Swift 6.2

## Try the demo

```sh
git clone https://github.com/bryanrg22/chatgpt-ios-ui.git
cd chatgpt-ios-ui
open Examples/ChatGPTUIDemo/ChatGPTUIDemo.xcodeproj
```

Choose the `ChatGPTUIDemo` scheme and an iPhone simulator, then press Run. The first build resolves package dependencies over the network. Running the demo requires no account or API key. For screenshot comparisons, use the exact configuration in [TESTING.md](TESTING.md), rather than any available simulator.

Sending a message streams a canned local reply. To jump to a screen, add a launch argument in the scheme, for example `--screen codex` or `--screen settingsAbout --light`. Every name is listed in [`Shared/DemoScreen.swift`](Examples/ChatGPTUIDemo/Shared/DemoScreen.swift).

## Use it in your app

Add the package in Xcode (**File → Add Package Dependencies…**) with this repository's URL, or in `Package.swift`:

```swift
.package(url: "https://github.com/bryanrg22/chatgpt-ios-ui", branch: "main")
```

Then own a `ChatState`, show `ChatGPTView`, and answer the actions it sends you. This example streams a reply from your own backend:

```swift
import ChatGPTUI
import SwiftUI

struct ContentView: View {
    @State private var chat = ChatState()
    @State private var reply: Task<Void, Never>?

    var body: some View {
        ChatGPTView(state: chat)
            .onAppear { chat.onAction = handle }
    }

    private func handle(_ action: ChatAction) {
        switch action {
        case .send(let text, _, _, _, _):
            guard let id = chat.responseID else { return }  // set by the UI just before .send
            reply = Task {
                var answer = ""
                do {
                    for try await chunk in MyBackend.stream(prompt: text) {  // your API client
                        answer += chunk
                        chat.updateResponse(id: id, text: answer)  // full text so far
                    }
                } catch {
                    answer += "\n\n(Something went wrong.)"
                }
                chat.updateResponse(id: id, text: answer, finished: true)
            }
        case .stop:
            reply?.cancel()
        default:
            break
        }
    }
}
```

## How it works

Data flows in one direction, and the package never decides what happens next:

```text
your app ──data──▶ ChatState ──▶ ChatGPTView ──user taps──▶ ChatAction ──▶ your handler ──▶ your backend
    ▲                                                                                         │
    └──────────────────────── updateResponse, messages, feature data ◀─────────────────────────┘
```

- **State in.** `ChatState` and its feature states (`chat.voice`, `chat.codex`, `chat.finance`, …) hold what the screens show. Set them from your data.
- **Actions out.** Every button that would need a server, a device or the system emits a typed action instead: send, stop, retry, attach, connect a provider, open a link.
- **Stale replies are ignored.** Each response has an ID. Updates for a stopped or replaced response are dropped, so a slow network can't overwrite a newer answer.

The [integration guide](docs/INTEGRATION.md) covers every feature area: voice, camera, media, Markdown, Codex, Your dot, Health, Finances, Space, Images, Settings and widgets.

## What's covered

| Area | Status |
|---|---|
| Chat, composer, conversation actions, sidebar | ✅ Built |
| Voice chooser, session, settings, sharing, live camera | ✅ Built (silent; no audio) |
| Camera, photo picker, image and video viewer | ✅ Built (your app supplies the media) |
| Markdown, code blocks, tables, inline code | ✅ Built |
| Codex, Your dot, Work tasks, Images, Sites, Projects, Space, Plugins, Memory, Search, Scheduled | ✅ Built, with some sub-pages still placeholders |
| Health and Finances | ✅ Built; disconnected and error states not yet captured |
| Settings: General, Personalization, About | ✅ Built; several deeper pages are placeholders |
| Home Screen widgets | ✅ Built as a real WidgetKit extension |
| Lock Screen, Live Activities, Dynamic Island, system call UI | ⬜ Not yet |

Placeholders show a clear "not built yet" notice instead of pretending to work. The full record of what was captured from the real app, and how closely each screen matches it, is in [docs/fidelity](docs/fidelity/ROUTE_COVERAGE.md).

## Project layout

```text
Sources/ChatGPTUI/          The interface: views and presentation state
Sources/ChatGPTWidgets/     Widget views and deep links
Tests/ChatGPTUITests/       Unit tests (run on the Mac with `swift test`)
Examples/ChatGPTUIDemo/     Demo app, widget extension, screenshot and UI tests
docs/                       Integration guide, feature guides, fidelity records
```

## Help keep it current

- **Found a visual mismatch?** [Open a mismatch report](https://github.com/bryanrg22/chatgpt-ios-ui/issues/new?template=1-ui-mismatch.yml) with the route, reproduction steps, app version, device/iOS, appearance and a reference screenshot or video.
- **The real app changed?** [Suggest an update](https://github.com/bryanrg22/chatgpt-ios-ui/issues/new?template=2-app-update.yml). Keep one screen or flow per issue.
- **Something crashes or fails to build?** [Report a bug](https://github.com/bryanrg22/chatgpt-ios-ui/issues/new?template=3-bug.yml) with a minimal reproduction and logs.
- **Want to fix it?** Read [CONTRIBUTING.md](CONTRIBUTING.md). A visual PR includes **reference → before → after** evidence in both appearances where applicable. Motion changes need recordings and measured timing; CI screenshots alone cannot verify motion or official-app parity.

The maintainer compares the evidence, checks the test results, and reviews the code before approving a PR. [The review guide](docs/REVIEW_GUIDE.md) explains the acceptance checklist and how to review screenshot updates. Keep all reference captures free of personal information.

Looking for the other skeleton? [Claude iOS UI](https://github.com/bryanrg22/claude-ios-ui).

## License

The source code is available under the [MIT License](LICENSE). Bundled fonts, artwork and dependencies keep their own terms; see [ASSETS.md](THIRD_PARTY_NOTICES.md) and [Swift-Markdown-LICENSE.txt](Sources/ChatGPTUI/Resources/Swift-Markdown-LICENSE.txt).
