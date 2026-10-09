# Dot presentation and host integration

Dot is an offline UI surface. Typed `DotUIAction` callbacks are requests to a host, not microphone, networking, remote-control or CallKit operations. `DotPresentationState` owns drafts, reply selection, local controls and messages; each instance is isolated.

## Connected calls

A host supplies connection and time explicitly:

```swift
state.dot.applyCallPresentation(.init(
    phase: .connected, elapsedSeconds: 38, microphoneMuted: false
))
```

The package does not start a timer, connect a call, request microphone access, activate an audio session or invoke ActivityKit. `beginCall`, `endCall`, `toggleMute` and `toggleSpeaker` emit their corresponding typed actions. Applying host state does not echo an action, and elapsed seconds are clamped to zero. Ending the local call closes its presentation; the host decides whether to append a call summary or report delivery.

```swift
let summary = DotMessage(text: "", isUser: true,
    kind: .callEnded(durationSeconds: 443), receipt: .delivered)
state.dot.append(summary)
state.dot.updateReceipt(.read, for: summary.id)
```

Receipts belong to outgoing messages. A stale Delivered event or an older upsert cannot downgrade Read. Local Send produces no delivery receipt until a host acknowledgement. The source screenshots establish Delivered; the user reported the later Read transition, but its pixels and timing are still unmeasured. There is no simulated vendor delay.

## System call previews

`DotSystemCallPreview(presentation:style:onAction:)` draws a compact or expanded reference panel in an ordinary app view, with a visible **System call preview · No active call** caption. This is neither a real Dynamic Island nor a Live Activity. Buttons emit typed mute/end intents. No personal Home Screen content is used as a background.

The captured system panel is compatible in appearance with native call UI, but screenshots do not reveal its underlying framework. For a genuine system-call demonstration, a separate host adapter could translate begin/end/mute intents to CallKit transactions and map provider events back to `applyCallPresentation`. Do not treat that adapter as implemented. Apple manages an audio session for CallKit; recording-free source code does not establish that the system avoids audio activation, indicators or permission behavior. Device verification is required before enabling a native demo. [Apple CallKit](https://developer.apple.com/documentation/callkit), [Apple's distinction between system services and custom ActivityKit UI](https://developer.apple.com/news/?id=qpqf1gru).

## Menus and text selection

Assistant text supports the observed reaction strip and Copy / Select text / Reply menu. Call summaries use only Copy / Reply, with a phone glyph and formatted elapsed duration. More reactions is a host intent; its expanded picker remains unobserved. Select text uses an inline native `UITextView` with selection handles and the system edit menu; the available system actions depend on the runtime rather than a fabricated toolbar. Copy uses the visible summary/text, and Reply preserves the existing draft.

## Evidence limits

Connected full and minimized calls, compact/expanded system panels, selected mute's white background/red glyph, ended-call summary and Delivered receipt are captured. Blue blur is procedural and remains an approximation. Call transition motion, exact blur texture, separate minimal Dynamic Island and Lock Screen UI remain unverified. The two later supplied recordings show the computer viewer rather than call expansion; see the computer motion audit below. The existing calling/failure/computer behavior remains separate. All sample text is fictional; private screenshots are not distributed.

State tests cover explicit connected updates, negative/long durations, duplicate start/end, no fabricated summary or receipt, stale receipt events/upserts, assistant receipt rejection, summary copy/reply, and reaction eligibility. The final two affected simulator UI tests passed (35.871s and 9.381s). Exported screenshots were inspected: connected/muted calls, summary receipts and the real native selection toolbar were visible. The toolbar exposes system MenuItem actions rather than ordinary buttons.

## Computer motion audit

The supplied October 7 recordings ending `23-52-04_1` (14.395 seconds) and `23-52-34_1` (23.672 seconds) were inspected as complete contact sheets. Both show Your dot’s computer. The former includes opening from the menu, a connecting state, the loaded desktop and keyboard; the latter begins with the viewer open and shows gesture-like zoom/pan, keyboard and browser changes. Neither contains a call panel. Gesture input coordinates are absent, so changing desktop scale is not evidence of an automatic timed expansion.

The opening scalar is the close-X glyph's vertical center, normalized by full video height (2556 pixels). A 60 Hz dense sample gives the following values; estimated uncertainty is ±2 pixels and one sample (16.7 ms). Tap time and the first offscreen frame are not established.

| Recording time | Center y / screen height |
| --- | --- |
| 4.0000 s | 0.9628 |
| 4.0833 s | 0.4824 |
| 4.1833 s | 0.1980 |
| 4.2833 s | 0.1268 |
| 4.3833 s | 0.1092 |
| 4.5000 s | 0.10485, stable |

The first visible-to-stable span is approximately 0.50 seconds, without a sampled overshoot. This does not establish a universal duration across devices or system versions. At rest the combined computer icon/title is centered: its visible bounds span x308–874 on the 1180-pixel video, midpoint591 versus screen midpoint590. Reference frames remain private and are excluded from this package.

The unchanged native `fullScreenCover` was recorded on the iPhone 17 Pro simulator and compared using remaining travel `(y - restingY) / screenHeight`. After aligning at 60% remaining travel, reference versus simulator elapsed times are: 30%: 58/61 ms; 10%: 136/140 ms; 3%: 220/223 ms; 1%: 289/314 ms. The largest sampled difference is 25 ms, near the combined capture/sample tolerance; no custom curve is justified by this recording. Native presentation is retained. This is scalar agreement, not pixel identity: device safe areas, icon shapes, text weight, synthetic desktop and loading state differ. The simulator label is visible earlier during the cover entrance than in the recording; this audit does not establish that title-fade timing. The supplied clip starts in Connecting; the offline test uses an explicitly supplied ready desktop. Keyboard geometry and user-driven zoom were not fitted to a timed animation.

The existing Dot send/reply/call/computer UI regression passed again (27.363s), preserving draft state through the call and viewer and exercising keyboard dismissal. No Swift source or state behavior changed in this motion audit, so no new state tests or replacement build were needed.
