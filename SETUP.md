# Part 1 — What you need to do to complete the app

These are the steps only you can do — they require your Mac, Apple ID, or physical device.

---

## Step 1 — Generate the app icon (5 min)

The icon is fully designed in code. Run this once from the repo root on your Mac:

```bash
swift tools/generate_icon.swift
```

This saves `AppIcon.png` into `IronLog/Resources/Assets.xcassets/AppIcon.appiconset/`.  
Without it the app compiles fine but shows a blank icon.

To tweak the design, edit `tools/generate_icon.swift` and re-run.

---

## Step 2 — Add your Apple ID to Xcode (2 min)

You do **not** need a paid developer account. A free Apple ID lets you install on your own device (7-day signing window).

1. Open **Xcode → Settings → Accounts**
2. Click **+** → **Apple ID** → sign in

---

## Step 3 — Set your Development Team (1 min)

After running `xcodegen generate` and opening `IronLog.xcodeproj`:

1. Click the **IronLog** project in the navigator (top of the left sidebar)
2. Select the **IronLog** target → **Signing & Capabilities**
3. Set **Team** to your Apple ID
4. Repeat for the **IronLogWidgetExtension** target

Xcode generates a provisioning profile automatically.

---

## Step 4 — Enable Live Activities capability (2 min)

The Live Activity / Dynamic Island feature requires a capability that must be added in Xcode:

1. Select the **IronLog** target → **Signing & Capabilities**
2. Click **+ Capability**
3. Add **Background Modes** → enable **Background processing**
4. Add **Push Notifications** *(needed for Live Activities even without a server)*

> **Note:** If Xcode shows a signing error after adding capabilities, just re-select your Team in the same tab.

---

## Step 5 — Trust your Mac on iPhone (one-time)

Plug in your iPhone. A dialog appears: **"Trust This Computer?"** → tap **Trust**.

---

## Step 6 — Trust the app on iPhone (first install only)

Because you use a free Apple ID (not the App Store), iOS requires you to approve your own certificate:

1. **Settings → General → VPN & Device Management**
2. Tap your Apple ID under **Developer App**
3. Tap **Trust "your@email.com"** → **Trust**

The app opens normally after this. You repeat this step only if the 7-day certificate expires (just rebuild from Xcode to renew it — your data is never wiped).

---

## Step 7 — Optional: Re-sign after 7 days

Free Apple ID certificates expire every 7 days. If the app stops launching:

1. Plug in your iPhone
2. Press **Cmd+R** in Xcode
3. Done — data is preserved

To avoid this entirely, upgrade to a paid Apple Developer account ($99/year).

---

## Summary checklist

- [ ] Run `swift tools/generate_icon.swift` to generate the app icon
- [ ] Add your Apple ID in Xcode → Settings → Accounts
- [ ] Set Development Team for both targets (IronLog + IronLogWidgetExtension)
- [ ] Add Background Modes + Push Notifications capabilities
- [ ] Trust Mac on iPhone (first time)
- [ ] Trust developer cert on iPhone (first install)
