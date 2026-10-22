# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-10-22

### Added

- Menu bar app that watches [codex-resets.com](https://codex-resets.com) and notifies you when a
  Codex usage reset is announced, and again if its time changes.
- Radar icon in the menu bar, followed by a countdown (`45m`, `9h`, `3d`, `due`) while a dated
  reset is pending.
- Panel with the pending reset (type, local date and time, relative time, announcement text and
  link to the post), the last reset, the average interval and the last check time.
- Polling on launch, every 15 minutes, after the Mac wakes and on demand, using `If-None-Match`
  to skip unchanged responses. Errors show in the panel and never notify.
- Launch at login toggle.
- App icon and menu bar glyph.
- `scripts/build-app.sh` to build a universal (Apple Silicon and Intel), ad-hoc signed app and
  zip it for sharing.
- MIT license for the code.

[Unreleased]: https://github.com/mpellicc/codex-reset-radar/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/mpellicc/codex-reset-radar/releases/tag/v0.1.0
