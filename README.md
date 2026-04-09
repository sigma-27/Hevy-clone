# IronLog

A complete personal iOS workout tracking app — a Hevy clone without social features. Built with SwiftUI + SwiftData for iOS 17+ (iPhone 15 Pro).

## Features

- **Workout Logging** — Real-time workout tracking, sets with weight/reps/RPE, rest timer, superset support
- **Exercise Library** — 130+ built-in exercises, custom exercise creation, search and filter by muscle group
- **Routines** — Create and manage workout routines/templates, schedule to days of week
- **History** — Full workout history, calendar heatmap, workout detail view
- **Statistics** — Per-exercise 1RM progression charts, personal records, body weight log, progress photos
- **Settings** — kg/lbs toggle, rest timer defaults, 1RM formula selection (Epley/Brzycki/Lander), plate calculator
- **Backup & Restore** — Export/import JSON backup to Files, AirDrop, or Google Drive

## Setup

### Prerequisites

- Mac with Xcode 15 or later
- iPhone 15 Pro (or compatible simulator)
- [xcodegen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

### Steps

```bash
# 1. Clone the repo
git clone https://github.com/sigma-27/hevy-clone.git
cd hevy-clone

# 2. Generate the Xcode project
xcodegen generate

# 3. Open in Xcode
open IronLog.xcodeproj

# 4. Select your iPhone as the target device
# 5. Build and run (Cmd+R)
```

> **Note:** For running on a physical device you need to set a Development Team in project settings (any free Apple ID works for personal use).

## Architecture

```
IronLog/
├── App/              # App entry point, tab navigation, global state
├── Models/           # SwiftData @Model classes (9 models)
├── ViewModels/       # @Observable view models
├── Views/            # SwiftUI views organized by feature
│   ├── Dashboard/    # Home screen
│   ├── Workout/      # Active workout tracking
│   ├── Exercises/    # Exercise library
│   ├── Routines/     # Routine management
│   ├── History/      # Workout history
│   ├── Statistics/   # Charts and stats
│   ├── Settings/     # App settings
│   └── Components/   # Reusable UI components
├── Services/         # Business logic (seeder, timer, export)
├── Utilities/        # Pure functions (weight converter, 1RM calc, plate calc)
└── Resources/        # exercises.json (130+ exercises), assets
```

**Stack:** SwiftUI · SwiftData · Swift Charts · UserNotifications · PhotosUI  
**Architecture:** MVVM · `@Observable` · offline-first · zero external dependencies  
**Storage:** Local SwiftData (SQLite). Backup via JSON export.

## Data Storage

All data is stored locally on your device using SwiftData. There is no iCloud sync or server-side component. Use **Backup & Restore** (Profile → Backup & Restore) to export your data as a JSON file and keep it safe.

## Development

```bash
# Generate project after adding/removing files
xcodegen generate

# Run tests
Cmd+U in Xcode
```

## License

Personal use only.
