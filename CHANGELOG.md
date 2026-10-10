# Changelog

All notable changes to this project are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html) as described in `docs/VERSIONING.md`. Until 1.0.0,
minor versions may change the public API; see each entry. Entries tagged `(visual)` change how a screen looks, and
each release notes how many screenshot references were re-recorded.

## [Unreleased]

### Changed

- **Breaking for exhaustive switches.** Every public action enum is now `@nonexhaustive`. An exhaustive `switch`
  over one of them no longer compiles; add `@unknown default` (or `default`). From now on a case added by a later
  release is a warning at that fallback rather than a build error. See `docs/VERSIONING.md`.
- The README now recommends `.upToNextMinor(from:)` while the package is 0.x, so updates deliver patches only.

### Added

- `docs/VERSIONING.md` and `docs/UPDATING.md`: what each version number promises, and how to update, pin, roll back
  and automate updates in an app.
- CI compares the public API with the latest release on every pull request; API changes need the `breaking` label.

## [0.1.0] - 2026-10-09

First release.

### Added

- `ChatGPTUI`: SwiftUI views and presentation state for the ChatGPT iPhone app's
  interface: chat and composer, sidebar, voice, camera, photos and video, Markdown
  with code and tables, settings, Codex, Your dot calls, Health, Finances, Space,
  Images, Work tasks, Sites, Projects, Plugins, Memory, Search and Scheduled.
  Light and dark appearance, Liquid Glass materials, no backend.
- `ChatGPTWidgets`: Home Screen widget views with typed deep links.
- A demo app (`Examples/ChatGPTUIDemo`) with fictional data, a WidgetKit
  extension and a `--screen <name>` launch argument for every catalogued screen.
- Tests: 153 unit tests, screenshot references for 40 screens in both appearances,
  31 UI tests and an accessibility audit with a recorded baseline, all run in CI.
- Documentation: integration guide, per-feature guides and fidelity records.

### Known limitations

- Several Settings and Customize sub-pages, the Codex task details, and the
  Health/Finances disconnected and error states are placeholders.
- Lock Screen widgets, Live Activities and Dynamic Island are not built.
- Text uses fixed sizes and does not follow the system text-size setting.

See the issue tracker for the current list.

[Unreleased]: https://github.com/bryanrg22/chatgpt-ios-ui/compare/0.1.0...HEAD
[0.1.0]: https://github.com/bryanrg22/chatgpt-ios-ui/releases/tag/0.1.0
