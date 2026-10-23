# AGENTS.md

## Agent skills

### Issue tracker

Issues live in GitHub Issues for `mpellicc/codex-reset-radar`, managed with the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

### Localization

Every user-facing string goes through a lookup and gets a value in every `.lproj`. Read `docs/agents/localization.md` before adding or changing any text the user sees or hears.

### Pull requests and releases

PR titles follow Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, ...): PRs are squash-merged with the title as the commit, and release-please builds the version and `CHANGELOG.md` from them. See README "Releasing".
