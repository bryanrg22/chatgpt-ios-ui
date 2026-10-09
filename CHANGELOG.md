# Changelog

All notable changes to this project are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). Until 1.0.0, minor
versions may change the public API; see each entry.

## [Unreleased]

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
