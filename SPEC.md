# Codex Reset Radar — v1 spec

A macOS menu bar app that tells you when a Codex usage reset has been announced.
It does one job: watch [codex-resets.com](https://codex-resets.com) and notify.

## Scope (v1)

- Announcements only. The AI "watch" forecast from the API is ignored.
- No backend, no accounts. Each Mac polls the public API directly.
- Distributed as an ad-hoc signed `.app` in a zip. No Apple Developer account,
  so colleagues approve it once via System Settings → Privacy & Security → Open Anyway.

## Data source

`GET https://codex-resets.com/api/v1/status` (free, no key, OpenAPI at `/api/openapi.json`).

Fields used:

- `data.scheduled_reset`: `id`, `reset_type` (`regular` | `banked`), `announced_at`,
  `scheduled_for` (nullable), `text`, `source.url`. Null when nothing is pending.
  A passed `scheduled_for` does not mean the reset happened.
- `data.latest_reset.announced_at`: the last reset that landed.
- `data.stats.avg_interval_days`.

Terms: the data must be credited with a link to codex-resets.com wherever it is shown.

**Update check.** On launch and then once a day the app asks
`GET https://api.github.com/repos/mpellicc/codex-reset-radar/releases/latest` for the newest
release. Its `tag_name` (without the leading `v`) is compared with the app's
`CFBundleShortVersionString` as `MAJOR.MINOR.PATCH`. Versions that don't have that shape, such as
`dev` when run outside the `.app` or a prerelease suffix, never offer an update. A failed check
is silent. It never notifies, downloads or installs anything.

## Behaviour

**Polling.** On launch, every 15 minutes, after the Mac wakes, and on "Refresh".
Sends `If-None-Match` with the last ETag. Errors are shown in the panel and retried
on the next poll; they never notify.

**Notification.** Sent when `scheduled_reset` has a non-null `scheduled_for` in the
future and either its `id` was never notified, or it was notified with a different
`scheduled_for` (title then says "rescheduled"). Notified `id → scheduled_for` pairs
are kept in `UserDefaults`, capped at 50. Clicking the notification opens the source post.

**Menu bar.** Radar icon. When a dated reset is pending, the icon is followed by a
countdown: `45m`, `9h`, `3d`, or `due` once the time has passed.

**Panel.**

- Pending reset: type, local date and time, relative time, the announcement text,
  link to the post. With no date: "time not given yet". Past due: "waiting for it to land".
- Otherwise: "No reset announced".
- Last reset (relative) and average interval.
- Last checked time, error if the last poll failed.
- When the update check found a newer release: "Version X available — Download", linking to
  the release page.
- Launch at login toggle, "Data from codex-resets.com" link, Quit.

## Tech

- Swift + SwiftUI `MenuBarExtra`, macOS 13+, Swift Package with no dependencies.
- `LSUIElement` (no Dock icon), `UserNotifications`, `SMAppService` for login item.
- `scripts/build-app.sh` builds a universal binary, assembles the `.app`,
  ad-hoc signs it and zips it into `dist/`.

## Out of scope for v1

Watch forecast, Slack, installing updates (the app only checks for them), settings beyond
launch at login.
