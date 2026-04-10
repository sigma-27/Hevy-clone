# Part 2 — Clone and install on iPhone 15 Pro

## Prerequisites

| Tool | Version | How to get it |
|------|---------|--------------|
| Mac | macOS 14 Sonoma+ | Required |
| Xcode | 15 or 16 | Mac App Store (free, ~7 GB) |
| Homebrew | any | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` |
| XcodeGen | any | `brew install xcodegen` |
| Git | any | Comes with Xcode Command Line Tools |
| USB cable | — | Lightning or USB-C to connect iPhone |

---

## Full install walkthrough

### 1 — Clone and switch to the dev branch

```bash
git clone https://github.com/sigma-27/hevy-clone.git
cd hevy-clone
git checkout claude/ios-gym-workout-app-ZmqpF
```

### 2 — Generate the app icon

```bash
swift tools/generate_icon.swift
# → Saved IronLog/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```

### 3 — Generate the Xcode project

```bash
xcodegen generate
# → Creates IronLog.xcodeproj (and embeds IronLogWidgetExtension)
```

### 4 — Open in Xcode

```bash
open IronLog.xcodeproj
```

### 5 — Connect your iPhone 15 Pro

Plug in via USB. Tap **Trust** on the iPhone if prompted.

### 6 — Set signing for both targets

In Xcode:

1. Click the **IronLog** project in the left sidebar
2. Select **IronLog** target → **Signing & Capabilities** → set **Team** to your Apple ID
3. Select **IronLogWidgetExtension** target → **Signing & Capabilities** → same Team

### 7 — Add required capabilities (for Live Activity / Dynamic Island)

Still in **Signing & Capabilities** for the **IronLog** target:

1. Click **+ Capability** → add **Background Modes** → tick **Background processing**
2. Click **+ Capability** → add **Push Notifications**

### 8 — Select your iPhone as the build target

In the Xcode toolbar, click the device selector (currently shows a simulator name) and choose your **iPhone 15 Pro**.

### 9 — Build and install

Press **Cmd+R** (or the ▶ play button).

- First build: ~2–3 min (SwiftData model compilation + 130-exercise seed)
- Subsequent builds: ~15 sec

### 10 — Trust the app on iPhone

The first time you open IronLog on a device signed with a free Apple ID:

```
Settings → General → VPN & Device Management
→ tap your Apple ID → Trust
```

**The app is now installed and ready.**

---

## Re-installing after the 7-day signing expiry

Free Apple ID certificates expire after 7 days. If the app badge shows "Unable to verify app":

1. Plug in your iPhone
2. Press **Cmd+R** in Xcode
3. Re-trust in Settings if prompted

Your workout data is stored in SwiftData on the device and is **never deleted** by a reinstall.

---

## Quick reference

| Task | Command / Location |
|------|--------------------|
| Regenerate Xcode project (after adding files) | `xcodegen generate` |
| Regenerate app icon | `swift tools/generate_icon.swift` |
| Run tests | `Cmd+U` in Xcode |
| Export your data | Profile tab → Backup & Restore → Export |
| View current branch | `git log --oneline` |

---

## Dynamic Island / Live Activity — first use

When you start a workout, iOS will ask permission to show Live Activities.  
Tap **Allow** (you can change this later in Settings → IronLog → Live Activities).

Once granted, the Dynamic Island shows:
- **Compact view** — flame icon + elapsed time (left) · current exercise (right)
- **Long-press** — expands to show set progress, rest timer bar, and two buttons:
  - **Complete Set** — marks the next incomplete set done and starts the rest timer
  - **Skip Rest** — cancels the rest timer immediately
- **Lock screen** — full card with the same controls

The elapsed timer and rest timer countdown update automatically — no battery drain from constant updates.
