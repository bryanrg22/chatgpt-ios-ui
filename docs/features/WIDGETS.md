# WidgetKit demo

The Xcode app embeds the separate `ChatGPTDemoWidgets` WidgetKit extension. The reusable `ChatGPTWidgets` SwiftPM product contains immutable, Codable host presentation data, typed deep links, and public renderers; it does not import the chat application or access a network, microphone, camera, or account.

The extension supplies an explicit offline snapshot through `TimelineProvider`, with `.never` refresh policy. Replace the demo provider with your own timeline/storage integration. No App Group or hidden shared preferences are required for the offline demo. Public shortcut/task arrays default empty. A Codex usage widget renders only the two-line placeholder captured in the original gallery; a loaded-usage design has not been observed.

| Kind | Native families registered | Reference coverage |
| --- | --- | --- |
| Codex usage | Small, medium | Two placeholder lines; no inferred loaded data |
| ChatGPT | Small, medium | Ask pill, camera/voice; medium also photos/dictation |
| ChatGPT shortcuts | Small, medium | Two or four shortcut tiles; injected configuration |
| Codex tasks | Medium, large | One/four host-supplied task rows, running indicator |

The ninth captured gallery position is a tall eight-row task widget. `ChatWidgetSize.tall` implements its presentation, but this extension cannot register its family with the installed iOS 26.4 SDK: that SDK marks `WidgetFamily.systemExtraLargePortrait` unavailable on iOS. Apple's newer beta documentation lists iOS support. Registration and native tall-gallery verification remain pending a compatible SDK; no private/raw-value workaround is used. Gallery perspective and carousel animations belong to iOS and are not painted into widget content.

Each control uses a native `Link`, plus one background `widgetURL`. Current Apple documentation supports multiple links in small and larger families. `ChatWidgetRoute` validates the owned `chatgpt-ui-demo://widget/…` scheme, destination, and optional Codex task UUID. The demo's `onOpenURL` routes to local presentation only. A task not present in the app cannot fabricate a result; the host must synchronize IDs. Photos emits a host attachment intent and opens the local tools surface. These demo destinations are functional UI choices, not evidence of the original app's post-tap routing.

The task running indicator is a bounded static arc. The original spinner motion is not established, and the offline timeline does not pretend to execute tasks.

Shortcut configuration sheets, loaded/error usage, light/tinted/clear rendering fidelity, Lock Screen widgets, controls, and Live Activities have not been captured and are not claimed. Native system appearance treatment is retained. The SVG knot is reused from the parent repository's existing ChatGPTLogo asset; see `THIRD_PARTY_NOTICES.md` for provenance limits.

Native verification on the dedicated iOS 27 simulator: all eight registered pages were opened in the actual Home Screen widget gallery and their screenshots inspected. An installed small ChatGPT widget exposed three independent controls; Camera, Voice, and Ask each opened its corresponding local surface. Tests do not add widgets to the physical phone. The combined `testNativeWidgetGalleryAndSmallLinks` passed on October 8, 2026 (165.647 seconds, including two native Springboard animation waits). This verifies local navigation and gallery registration, not original-app post-tap behavior.

Apple primary references checked October 8, 2026:

- [Creating a widget extension](https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension)
- [Linking to specific app scenes](https://developer.apple.com/documentation/widgetkit/linking-to-specific-app-scenes-from-your-widget-or-live-activity)
- [Adding widget interactivity](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities)
- [Extra-large portrait family](https://developer.apple.com/documentation/widgetkit/widgetfamily/systemextralargeportrait)
