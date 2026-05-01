# Developer Onboarding — EV Charging Tracker

For: developers picking up the codebase. Walks you from clone to running the app to merging a change.

For the App Store-facing project description, see `readme.md`. For agent rules, see `AGENTS.md`. For one-screen orientation, see `SUMMARY.md`.

## What it is

A native iOS app for electric-vehicle owners to log charging sessions, track non-charging expenses (maintenance, repair, carwash), schedule and track planned maintenance, store car documents and ideas, and analyze cost-per-km / kWh-per-100km / CO₂ saved over time. Single-user, offline. No accounts, no servers. Backups go to iCloud Drive (file-based, not CloudKit) and to a JSON file the user can share.

## Prerequisites

| Tool | Version |
|---|---|
| macOS | 14+ recommended |
| Xcode | latest stable; min iOS deployment target is 18.0 |
| Swift | 5.9+ |
| SwiftFormat / SwiftLint / Periphery | install via `./scripts/setup.sh` (uses Homebrew) |

## Initial setup

- [ ] Clone the repo into the workspace at `~/projects/ios/EVChargingTracker/` (paths in this doc are absolute from there).
- [ ] Run `./scripts/setup.sh` — installs SwiftFormat, SwiftLint, Periphery; creates `.env`.
- [ ] Open `EVChargingTracker.xcodeproj` in Xcode.
- [ ] Select the `EVChargingTracker` scheme + iPhone 17 Pro Max simulator. Build & run.
- [ ] On first launch you'll see the onboarding flow (language picker → intro pages → Skip/Finish).

The first launch creates `tesla_charging.sqlite3` inside the App Group container — see `BusinessLogic/Helpers/AppGroupContainer.swift`. Schema migrations run before any DB-backed UI mounts; warmup is in `EVChargingTrackerApp.swift:23-27`.

## Day-to-day commands

```bash
# Build (matches CI exactly)
xcodebuild -project EVChargingTracker.xcodeproj -scheme EVChargingTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build

# Run tests with coverage → ./build/TestResults.xcresult
./run_tests.sh

# Format
./scripts/run_format.sh

# Lint (strict)
./scripts/run_lint.sh

# Find unused code
./scripts/detect_unused_code.sh

# All of the above + tests
./scripts/run_all_checks.sh
```

`scripts/scripts.md` documents every script in detail.

## Repository layout

```
EVChargingTracker/
├── EVChargingTracker/    # App target — see EVChargingTracker/README.md
├── ShareExtension/       # Share Extension target — see ShareExtension/README.md
├── BusinessLogic/        # Shared by both targets — see BusinessLogic/README.md
├── EVChargingTrackerTests/   # Swift Testing
├── docs/                 # All non-trivial docs (cross-cutting + integrations)
├── ci_scripts/           # Xcode Cloud hooks
├── scripts/              # Setup/format/lint/test scripts (+ scripts.md)
├── .github/workflows/    # GitHub Actions: build.yml + swiftlint.yml
├── appstore/             # App Store metadata + release notes
├── features/             # Per-feature specs (legacy location, kept for now)
├── readme.md             # App Store-facing project description
├── AGENTS.md, SUMMARY.md, CLAUDE.md, REFERENCES.md, DEVELOPMENT.md
├── changelog.md, privacy-policy.md, appstore_page.md
└── EVChargingTracker.xcodeproj
```

## Key workflows

### Adding a feature

- [ ] If the feature is significant, draft a spec under `docs/plans/` (see `docs/plans/2026-04-30-second-screen-redesign.md` for an example) or `features/`.
- [ ] Add localization keys to **all** `EVChargingTracker/*.lproj/Localizable.strings` files (en, de, ru, kk, tr, uk, zh-Hans). Use `L("key")` to read them.
- [ ] If you need a new entity or column, add a migration: `docs/persistence.md`.
- [ ] If the feature is user-visible, add a row to `docs/features.md` with status `Implemented`.
- [ ] Run `./scripts/run_all_checks.sh` before pushing.

### Adding a database migration

- [ ] Create `BusinessLogic/Database/Migrations/Migration_YYYYMMDD_<Description>.swift`.
- [ ] Bump `latestVersion` in `BusinessLogic/Database/DatabaseManager.swift`.
- [ ] Add a `case <new version>:` branch in `migrateIfNeeded()`.
- [ ] If adding a column that's also created on fresh installs by the repository's `getCreateTableCommand()`, guard with a `columnExists` check (see `Migration_20260501_AddMeasurementSystemToCarsTable.swift` for the pattern).
- [ ] Update the schema table in `SUMMARY.md` and `docs/persistence.md`.

### Adding a localized string

- [ ] Add the key to `en.lproj/Localizable.strings` first.
- [ ] Add translations to `de.lproj`, `ru.lproj`, `kk.lproj`, `tr.lproj`, `uk.lproj`, `zh-Hans.lproj`.
- [ ] Use it: `Text(L("your.new.key"))`.
- [ ] Never `Text("Hardcoded English")`.

### Cutting a release

- [ ] Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in the Xcode project.
- [ ] Add a section to `changelog.md` (developer-facing).
- [ ] Add release notes to `appstore/releases.md` following the App Store voice (warm, conversational, 2–3 sentences max — see `CLAUDE.md`-era style guide preserved in `AGENTS.md` and `appstore/releases.md` itself).
- [ ] Push a PR to `develop`. CI runs SwiftLint + build (`.github/workflows/`).
- [ ] Merge to `develop`, then `develop` → `main` for production.
- [ ] Archive via Xcode (or Xcode Cloud); `ci_scripts/ci_post_clone.sh` injects Firebase secrets into `GoogleService-Info.plist` for cloud archive.

## Branches and CI

| Branch | Purpose | CI |
|---|---|---|
| `main` | Production (App Store) | n/a |
| `develop` | Integration / pre-release | PRs run SwiftLint + Swift Build (macos-latest) |
| feature branches | Individual changes | PR target is `develop` |

Source-of-truth CI files: `.github/workflows/build.yml`, `.github/workflows/swiftlint.yml`. Xcode Cloud post-clone: `ci_scripts/ci_post_clone.sh`.

## Conventional Commits

Follow Conventional Commits in commit messages: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`. The commit log is consumed by humans only; no automated semver.

## Where to look

| Need | File |
|---|---|
| Big-picture orientation | `SUMMARY.md` |
| Domain (cars, expenses, …) | `docs/domain.md` |
| When the build / archive breaks | `docs/diagnostics.md` |
| DB & migrations | `docs/persistence.md` |
| Backup feature | `docs/backup-and-restore.md` and `features/export_and_import.md` |
| Localization | `docs/localization.md` |
| Telemetry | `docs/analytics.md` |
| Notifications | `docs/notifications.md` |
| Build & signing | `docs/build-and-config.md` |
| Share Extension | `docs/integrations/share-extension.md` |
| iCloud backups | `docs/integrations/icloud-drive.md` |
| Firebase | `docs/integrations/firebase.md` |
| Workspace-wide rules | `../AGENTS.md`, `../ios-guidelines/*.md` |

## Useful links

- App Store: https://apps.apple.com/app/id6754165643
- Public site: https://evchargetracker.app
- Privacy policy: `privacy-policy.md`
- Roadmap: `docs/roadmap.md`
