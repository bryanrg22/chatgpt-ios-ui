# Interaction coverage

Static screenshots are one input. A matching skeleton must also reproduce visible changes caused by typing, pressing, selection, navigation, message completion, and dismissal. Record each transition independently; an implemented destination screen does not establish a verified animation into it.

Use the following record shape for implementation and comparison evidence:

```json
{
  "id": "composer.empty-to-text.light",
  "source": "new-chat/composer-empty",
  "trigger": "type a short fictional message",
  "destination": "new-chat/composer-nonempty",
  "theme": "light",
  "referenceEvidence": ["capture-filename.png"],
  "implementationEvidence": [],
  "referenceStatus": "observed",
  "implementationStatus": "unverified",
  "assertions": ["send action replaces idle voice action", "composer grows only when needed"],
  "knownGaps": ["transition timing has not been measured"]
}
```

Reference status: `unknown`, `capture-available`, `observed`, or `blocked`. Implementation status: `unverified` (implementation not yet inspected), `not-implemented`, `implemented-unverified`, `verified`, or `mismatch`. `verified` requires actually comparing the rendered skeleton and behavior with the reference under a documented configuration. If a state is unavailable on the reference account/device, record the limitation.

## Required state families

| Family | States/transitions to inspect |
|---|---|
| Composer | Empty -> typing -> multiline -> maximum height -> internal scrolling; clear text; keyboard enter/dismiss; attachment with/without text |
| Feature selection | Open picker; pressed row; selected icon/color/label; cancel; change selection; persistence across dismiss/reopen |
| Native surfaces | Attachment menu, sheets, nested sheets, context menu, dimming/background blur, touch-down glass, outside tap, swipe dismissal |
| Sending | Send action -> user bubble -> waiting/thinking -> streaming -> complete; stop; error; retry; input during response |
| Message actions | Long press; copy and confirmation feedback; selection; positive/negative rating and follow-up; retry; read-aloud play/pause/stop |
| Dictation | Start, permission/unavailable, elapsed time and levels, cancel, stop, processing, resulting transcript; empty/no-audio state |
| Voice conversation | Entry, listening, speaking, interruption, muted/unavailable, exit; list as unknown if not observed |
| Navigation | Sidebar open/close, search, selection, new chat, settings hierarchy, back gesture, sheet close, scroll position |
| Appearance | Light and dark, enabled/disabled, selected/unselected, reduced motion, text-size behavior |

For native controls, appearance and motion depend on OS version. Record timing from video if a motion match is claimed; guessed spring constants or a pair of still frames are not measured fidelity.

## Current evidence caveats

The initial collection used iPhone Mirroring with the software keyboard hidden. Measurements taken in the 393 × 852 point mirrored content area are specific to that condition, not universal layout constants. Silent dictation controls were visible, but microphone audio capture was unavailable through Mirroring. Simulated waveforms, transcripts, or playback are demo UI and must be marked as such.

## Live-reference findings added during this pass

The reference manifest contains transition records with filenames and observation notes. These are observations of the originals; they do not certify the current skeleton implementation.

| Interaction | Reference |
| --- | --- |
| Typed composer | Voice promotion hides; voice changes to send |
| Long draft in Mirroring | About 8 visible lines; approximately 248pt cap; expandable editor retains draft |
| Copy | Checkmark and toast |
| Positive rating | Selects and hides negative action |
| Negative feedback cancel | Selected negative rating remains; positive action hidden |
| Assistant long press | Response overflow actions were inspected separately |
| Read aloud | Top playback/replay bar with 1x, ±15, close; pause not observed |
| Silent dictation | Cancel X, dots, stop, blue send |
| Appearance restored to System | Returned to dark after Settings closed; light while still inside Settings |

A native menu is appropriate only if its actual rendered structure matches: a SwiftUI Menu trial produced different row heights, ordering, and icon treatment. Retain native material and interaction where suitable, and inspect custom content rather than assuming a system API guarantees fidelity.

Source app version observed in-app: ChatGPT **1.2026.267 (36747771815)**. This value identifies the captured build; it is not a promise that the reference will stay current. Mirroring could not provide live microphone input, so waveform behavior during speech and transcription results remain unverified.

## Search and Scheduled destinations

The captured Search empty/results screens and Scheduled Active/Paused lists, delete menu, New task form, Repeat picker, and Time picker now have corresponding local UI in `AdditionalDestinations.swift`. Search queries operate on fictional fixtures. Task creation, edits, and deletion update in-memory fixtures only; no notification, automation, or server job is created.

Deeper Search filter/result details, task-icon selection, custom interval, end-date choice, and existing-task editor navigation currently use functional native demo presentations. Their original-app layouts were not captured when this implementation was written, so they remain fidelity gaps. The Completed tab's empty appearance is also provisional. The destinations are integrated: compilation and Search/Scheduled interaction tests passed, including task persistence after navigation.

Direct camera reference supplements: eight user-supplied native iPhone PNGs (`IMG_6693.PNG`–`IMG_6700.PNG`) were verified from their PNG headers at 1179 × 2556 pixels. The supplied @3x scale corresponds to 393 × 852 points. See `REFERENCE_CAPTURE_GUIDE.md` for private-archive handling; camera interaction validation is recorded in `VALIDATION.md`.

Search/Scheduled state review: saved and deleted task fixtures plus the selected tab are now owned by `ChatState` and survive destination navigation. Search query and category persist together; whitespace-only input remains the empty state. Canceled editors are isolated value copies; saving trims and validates content and replaces an existing task by identity. Seven regression tests cover these cases; these regression tests remain included in the package suite; current counts are recorded in the snapshot validation report. These verify state behavior, not pixel fidelity.

Memory summary now uses directly captured summary/menu/About-panel layouts and fictional text of comparable density. Refresh/delete affect only local presentation state; deletion confirmation and disabled-memory appearance are provisional because no real memory was changed to inspect them. Learn more emits a host navigation intent; its external destination remains uncaptured. About panel, refresh and back navigation passed the integrated Memory UI check. Later Mirroring captures have different window sizes, now recorded per file in the manifest rather than assuming the initial window geometry applies to all frames.

Plugins catalog, Gmail-style detail, settings, and the four permission choices now follow direct references. Permission selections, installation flags, and connected-account rows are local presentation state only; no external permission, sign-in, or service access occurs. Brand logos use documented system-symbol approximations. Prompt examples and account details are fictional. Extra installed-list layouts, add-account/read-action dialogs, and post-removal states are functional local demos whose exact original layouts remain unverified. Try in chat prepares a draft; it does not send a message.

ChatGPT voice now has separate Breeze chooser, idle, settings, and language-menu captures; these establish neither speaking states nor timing, because Mac Mirroring cannot supply microphone audio. Its silent dictation reference remains a separate surface. The desktop 994 × 224 waveform still has a 50px observed peak in one frame, not a measured cap or mobile point value.

## Your dot and Codex expansion

Your dot now has separate conversation bubbles, reply focus, reaction/menu controls, computer access menu, call presentation, and an injectable computer viewer. Calling/failure panel geometry comes from native stills, not the file `chatgpt-dot-calling.png` (which is a Mirroring microphone alert). Two private recordings establish computer-viewer zoom/pan and keyboard placement; they do not show call transitions. Call failure and computer connection states are host-supplied, with no invented fixed timeout. Native menu APIs are used for the computer menu; attachment and message reaction layouts use custom content with native material because the observed arrangement differs from ordinary SwiftUI menu rows. Scoped Dot/Codex interaction and rendered checks passed; complete visual and motion parity remains unverified.

Codex task responses and activity labels can be updated by the host through `updateTask`; task submission, stop, and pairing emit typed intents. No remote process is executed by the UI package. See `ROUTE_COVERAGE.md` for the remaining whole-app routes.

## Feature workspace checkpoint — October 8

Finances: connected Dashboard/Chats/Accounts/Transactions, Accounts/Plaid/Credit score/Manual accounts sheet, Cash-to-chat, five date filters, and local dashboard customization have source references. Health: feature setup, its condition search, connected Home, empty Chats, Records connection prompt, Accounts, provider chooser and Active conditions have references. Local implementation passed its feature state tests and integrated Finance/Health/empty-data UI checks, followed by the provider-binding rerun. Reusable defaults are empty and demonstration data is injected. Canceling Health setup restores preexisting selections, completing commits once, and canceling dashboard customization discards the value copy. No real account, medical or financial connection is performed. Finance disconnected/error and whole-workspace loading/failure remain uncovered; provider status strings are not proof of those layouts.

Home Screen widgets, Lock Screen Live Activities, and Dynamic Island each require separate references and coverage. Dot Calling/Call failed is an in-app panel; its screenshots do not establish any WidgetKit or ActivityKit surface.

## Dot connected call and message additions — October 8

The latest private references distinguish connected expanded/minimized in-app calls from compact/expanded system call panels above Home Screen. System selected mute uses a white control and red crossed microphone. No underlying ActivityKit implementation is proven. Reusable Dot state now accepts explicit host connection/time/mute snapshots; a separately labeled ordinary-view system preview emits intents without starting CallKit, audio or network activity. The native CallKit boundary and remaining Lock Screen/minimal/motion gaps are recorded in `WIDGET_REFERENCE.md`.

Assistant message long press shows reactions plus Copy / Select text / Reply. An outgoing ended-call summary has a phone glyph, duration, Call ended text and only Copy / Reply. Native text selection is now implemented in place with UIKit. Delivered is visible in screenshots. The user reported Delivered → Read; no Read screenshot or timing measurement is available. Receipt progression is host-driven and monotonic; local sends do not invent delivery or a vendor delay. State tests and two final affected UI checks passed. Native selected-text toolbar was visually verified and its Copy menu item exercised; no custom translation/share toolbar was substituted.

## Sent images and shared image viewer — October 8

ChatGPT source captures show a sent image approximately 185 × 191 points; the native Copy-only long-press preview is approximately 211 × 216 points. No transition duration was measured. The full-screen viewer places the image at the same center and size with controls shown or hidden; the status bar is absent in both captures. The top menu contains Add to Favorites, and bottom tools are Edit, Resize and Remove (eraser). Private originals are never demo assets.

`ChatMedia` supplies stable identity and an opaque image key, and hosts resolve SwiftUI images. Chat and Space now share `MediaViewer`; controls overlay the complete-viewport image rather than changing its layout. Local favorites and chrome visibility are presentation state. Download, editing, resizing and erasing emit typed host intents, with no invented successful result. Native SwiftUI Menu, aspect-fit image rendering and status-bar control follow Apple's supported presentation APIs. The nonfavorite source state is captured; removing a favorite is local reversible skeleton behavior pending its own source reference.

## Motion evidence limits

The Chat/Work recording's first post-click sample is 1360ms after the sampling start; the click returned at 590ms, and later samples span 1510–2534ms. The first saved frame already has Work selected. It verifies the endpoints only and cannot establish transition duration, easing, overshoot or intermediate layout. Native default transitions and any matched-geometry timing remain provisional. Camera transition duration/easing also has no measured source recording. No interaction coverage entry establishes exact motion parity without its own sampled evidence.

## Video media

Eight private ChatGPT references cover recent-video selection, duration labels, composer poster, an initially clipped sent card, and the fullscreen movie viewer. Unlike images, this viewer retains the status bar and has only top Close/Fit controls. The recording's embedded Dot buttons are not viewer controls. The file called player-controls shows a tapped movie frame, not a transport bar. Fit's effect, play/pause, timeline and inline autoplay/pause policy remain unverified. The collector reported looping; no timing or audio behavior was measured. The skeleton presents host-supplied moving content and emits a fit request without inventing an editor or playback service.

Image and video open/close currently use native/default presentation; vendor easing, interactive dismissal and gesture timing are unmeasured. A later complete paused-card capture establishes about 120 × 240 points and a 40-point outlined central Play affordance. Earlier changing-frame cards lacked that overlay; the autoplay/pause policy remains unmeasured. No original movie, camera-roll photo or other private capture is included in the export.

## Bounded phase2 checkpoint

Explore/Sites/Projects/Images/Work and Settings subpages now have scoped local-state and rendered interaction checks. The 150-test independent snapshot is historical; later verified counts are recorded in the current snapshot validation report. No count establishes all-route UI or motion parity. Work answers and statuses remain host-fed intents. See `ROUTE_COVERAGE.md` and each child Settings guide for exact scope. Private captures never become distribution assets.

## Active polish boundary

The current user-authorized pass covers existing media/text/voice states, icons, light/dark appearance and reference-measured animation. Remaining feature pages and system surfaces are deferred TODOs. Newly captured Customize pages are private future references, not delivered routes. The previous 150-test independent export remains a historical checkpoint and predates the now-frozen syntax/table/inline-code and existing-presentation refinements. All remaining gaps are TODO.
