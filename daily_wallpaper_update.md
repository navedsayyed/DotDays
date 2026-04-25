# DotDays – Daily Wallpaper Update System

## Overview

DotDays uses a **two-layer approach** to ensure the wallpaper updates every day when the date changes, filling in one more dot on the calendar grid.

---

## Layer 1: Background Service (WorkManager)

**File:** [background_service.dart](file:///c:/Users/Naved%20Sayyed/Desktop/DotDays/lib/services/background_service.dart)

Uses Android's `WorkManager` via the `workmanager` Flutter package to run a periodic background task.

| Detail | Value |
|--------|-------|
| **Frequency** | Every **15 minutes** (Android's minimum for periodic tasks) |
| **Runs when app is closed?** | ✅ Yes — runs in a separate isolate |
| **Survives reboot?** | ✅ Yes — re-scheduled via `ensureScheduled()` on app launch |
| **Duplicates prevented?** | ✅ Yes — checks `wallpaper_last_update_day` key |

### What happens each time WorkManager fires:

1. **Check auto-update** — Is `autoUpdate` enabled? If not, exit early.
2. **Check onboarding** — Is onboarding complete? If not, exit early.
3. **Check if already updated today** — Compares current date string (`2026-4-25`) against saved `wallpaper_last_update_day`. If same, exit early.
4. **Read saved settings** from `SharedPreferences`:
   - Calendar type (Life / Year / Goal)
   - Date of birth & lifespan
   - Goal name, start date, end date
   - Dot color
   - Wallpaper location (lock screen, home screen, or both)
5. **Render a new wallpaper image** — `HeadlessWallpaperRenderer` draws the dot grid offscreen (no UI needed) with today's date filled in, saves it as a PNG file.
6. **Apply the wallpaper** — `WallpaperService` sets that PNG as the phone's lock/home screen wallpaper.
7. **Save today's date** as `wallpaper_last_update_day` to prevent duplicate updates.

### Key Methods:

- `BackgroundService.init()` — Initializes WorkManager
- `BackgroundService.scheduleDaily()` — Registers the periodic task (every 15 min)
- `BackgroundService.ensureScheduled()` — Re-schedules if needed (handles reboots)
- `BackgroundService.cancel()` — Cancels the periodic task

---

## Layer 2: App Launch Updater (Fallback)

**File:** [wallpaper_auto_updater.dart](file:///c:/Users/Naved%20Sayyed/Desktop/DotDays/lib/services/wallpaper_auto_updater.dart)

This is a **fallback** that runs when the user opens the app. It exists because aggressive battery optimization on phones (Xiaomi, Realme, Samsung, etc.) can kill WorkManager tasks.

### What it does:

Runs the **exact same logic** as the background service:
1. Check auto-update + onboarding status
2. Check if day changed (compare date key)
3. Re-render wallpaper + apply it
4. Save the update date

### When it runs:

Called in `main.dart` line 21, right after service initialization:
```dart
WallpaperAutoUpdater.checkAndUpdate();
```

---

## Layer 3: Battery Optimization

**File:** [battery_optimization_service.dart](file:///c:/Users/Naved%20Sayyed/Desktop/DotDays/lib/services/battery_optimization_service.dart)

Requests Android to **exempt DotDays from battery restrictions**, making it more likely that WorkManager tasks survive on aggressive OEMs.

- Checks if already exempted via `isIgnoringBatteryOptimization()`
- If not, requests exemption via `requestIgnoreBatteryOptimization()`

---

## App Startup Flow

**File:** [main.dart](file:///c:/Users/Naved%20Sayyed/Desktop/DotDays/lib/main.dart)

```
main()
  │
  ├── StorageService.init()              ← Initialize SharedPreferences
  ├── BackgroundService.init()           ← Initialize WorkManager
  ├── BackgroundService.ensureScheduled()← Re-schedule periodic task if needed
  ├── WallpaperAutoUpdater.checkAndUpdate() ← Immediate fallback check
  └── _requestBatteryOptimizationIfNeeded() ← Ask for battery exemption
```

---

## Rendering Pipeline

**File:** [headless_wallpaper_renderer.dart](file:///c:/Users/Naved%20Sayyed/Desktop/DotDays/lib/services/headless_wallpaper_renderer.dart)

The renderer draws the dot grid **without any UI** (headless):

1. Creates a `Canvas` + `PictureRecorder` at the device's screen resolution
2. Draws the background (solid black)
3. Calculates grid dimensions based on calendar type:
   - **Life Calendar:** 80 rows × (lifespan × 365 / 80) columns
   - **Year Calendar:** ~19 rows × ~19 columns (365 dots)
   - **Goal Calendar:** Dynamic based on goal duration
4. Fills dots up to "today" with the accent color (lived/passed dots)
5. Draws remaining dots in dim gray (future dots)
6. Highlights today's dot with a special color
7. Adds date/percentage text overlays
8. Saves the canvas as a **PNG file** to the app's temporary directory

**File:** [wallpaper_service.dart](file:///c:/Users/Naved%20Sayyed/Desktop/DotDays/lib/services/wallpaper_service.dart)

Uses the `wallpaper_manager_flutter` package to set the rendered PNG as:
- Lock screen only (`locationLockScreen`)
- Home screen only (`locationHomeScreen`)
- Both screens (`locationBothScreens`)

---

## Visual Summary

```
┌─────────────────────────────────────────────────────┐
│                   App Launch                         │
│  main.dart → StorageService.init()                   │
│           → BackgroundService.init()                 │
│           → BackgroundService.ensureScheduled()       │
│           → WallpaperAutoUpdater.checkAndUpdate()    │ ← Immediate fallback
│           → Request battery exemption                │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│            Background (every 15 min)                 │
│  WorkManager fires → callbackDispatcher()            │
│    → Day changed?                                    │
│      → YES: Render new wallpaper PNG (offscreen)     │
│           → Apply to lock/home screen                │
│           → Save "last update day"                   │
│      → NO:  Skip (already updated today)             │
└─────────────────────────────────────────────────────┘
```

---

## Key Files Reference

| File | Purpose |
|------|---------|
| [main.dart](file:///c:/Users/Naved%20Sayyed/Desktop/DotDays/lib/main.dart) | App entry point, initializes all services |
| [background_service.dart](file:///c:/Users/Naved%20Sayyed/Desktop/DotDays/lib/services/background_service.dart) | WorkManager periodic task (every 15 min) |
| [wallpaper_auto_updater.dart](file:///c:/Users/Naved%20Sayyed/Desktop/DotDays/lib/services/wallpaper_auto_updater.dart) | App-launch fallback updater |
| [headless_wallpaper_renderer.dart](file:///c:/Users/Naved%20Sayyed/Desktop/DotDays/lib/services/headless_wallpaper_renderer.dart) | Offscreen dot grid renderer → PNG |
| [wallpaper_service.dart](file:///c:/Users/Naved%20Sayyed/Desktop/DotDays/lib/services/wallpaper_service.dart) | Applies PNG as phone wallpaper |
| [battery_optimization_service.dart](file:///c:/Users/Naved%20Sayyed/Desktop/DotDays/lib/services/battery_optimization_service.dart) | Battery exemption request |
| [storage_service.dart](file:///c:/Users/Naved%20Sayyed/Desktop/DotDays/lib/services/storage_service.dart) | SharedPreferences wrapper for all settings |
