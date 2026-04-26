# DotDays — Technical Documentation

> **Version:** 2.0.0 · **Platform:** Android · **Framework:** Flutter 3.5+  
> **Last Updated:** April 2026

---

## Table of Contents

1. [What is DotDays?](#1-what-is-dotdays)
2. [How It Works (Simple Explanation)](#2-how-it-works-simple-explanation)
3. [App Architecture](#3-app-architecture)
4. [Project Structure](#4-project-structure)
5. [User Flows](#5-user-flows)
6. [Calendar Types](#6-calendar-types)
7. [State Management](#7-state-management)
8. [Navigation System](#8-navigation-system)
9. [Wallpaper System (Core Engine)](#9-wallpaper-system-core-engine)
10. [Background Update System](#10-background-update-system)
11. [OEM Survival Strategy](#11-oem-survival-strategy)
12. [Settings & Configuration](#12-settings--configuration)
13. [Design System](#13-design-system)
14. [Android Native Layer](#14-android-native-layer)
15. [Data Storage](#15-data-storage)
16. [Dependencies](#16-dependencies)
17. [Build & Release](#17-build--release)
18. [Troubleshooting](#18-troubleshooting)

---

## 1. What is DotDays?

DotDays is an Android app that turns your phone wallpaper into a **visual timeline of your life**. It displays a grid of dots where:

- **White dots** = days/weeks you've already lived
- **Orange dot** = today
- **Dark dots** = your remaining time

The wallpaper **updates automatically every day** at midnight, filling in one more dot. It's a daily reminder that time is passing and every day matters.

### The Core Idea

Imagine your entire life as a grid of dots on your phone wallpaper. Every morning when you unlock your phone, you see one more dot filled in. That's DotDays.

---

## 2. How It Works (Simple Explanation)

```
User opens app → Chooses calendar type → Enters details → Sets wallpaper
                                                              ↓
                                              Every midnight, automatically:
                                              1. Render new dot grid (one more dot filled)
                                              2. Save as PNG image
                                              3. Set as phone wallpaper
```

### The Daily Update Cycle

1. **Midnight hits** → Android WorkManager or AlarmManager triggers
2. **Engine checks** → "Has the date changed since last update?"
3. **If yes** → Render a new wallpaper PNG with today's dot filled in
4. **Apply** → Set the PNG as the phone's home/lock screen wallpaper
5. **Record** → Save timestamp, success status, trigger source

### Three Safety Layers

| Layer | Mechanism | When It Runs |
|-------|-----------|-------------|
| **Primary** | WorkManager (24hr periodic) | Every 24 hours, aligned to midnight |
| **Backup** | AlarmManager (exact alarm) | Exactly at midnight |
| **Fallback** | App Launch Check | Every time user opens the app |

If any layer fails, the others catch it. The user's wallpaper always stays up to date.

---

## 3. App Architecture

```
┌─────────────────────────────────────────────────────────┐
│                        UI Layer                          │
│  Features: Home, Onboarding, Settings, Wallpaper Preview │
│  Widgets: DotGrid, WallpaperCanvas, AppButton            │
├─────────────────────────────────────────────────────────┤
│                    State Management                      │
│  Riverpod: AppSettingsProvider (StateNotifier)            │
├─────────────────────────────────────────────────────────┤
│                     Navigation                           │
│  GoRouter with query-parameter-based back navigation     │
├─────────────────────────────────────────────────────────┤
│                    Service Layer                          │
│  WallpaperUpdateEngine  │  HeadlessWallpaperRenderer     │
│  BackgroundService      │  AlarmService                  │
│  WallpaperService       │  BatteryOptimizationService    │
│  StorageService         │  DateService                   │
├─────────────────────────────────────────────────────────┤
│                   Android Native                         │
│  MainActivity.kt  │  BootReceiver.kt                     │
│  Method Channels: battery, device                        │
└─────────────────────────────────────────────────────────┘
```

### Key Design Principles

- **Deterministic Rendering** — Wallpaper is always computed from `current_date + user_settings`. Never depends on cached state for correctness.
- **Idempotent Updates** — The update function can be called 100 times safely. It only does work when the date has actually changed.
- **Atomic State** — Success state is only saved AFTER the wallpaper is successfully applied. A failure never corrupts the tracking data.
- **Graceful Degradation** — Every background service is wrapped in try-catch. If alarms fail, WorkManager continues. If WorkManager fails, app launch catches it.

---

## 4. Project Structure

```
lib/
├── main.dart                          # App entry point, service initialization
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # All keys, names, defaults
│   └── theme/
│       ├── app_colors.dart            # Color palette
│       └── app_theme.dart             # Material theme configuration
├── features/
│   ├── home/
│   │   └── home_screen.dart           # Main screen (3 tabs: Home, Set, Settings)
│   ├── onboarding/
│   │   ├── welcome_screen.dart        # First-time welcome
│   │   ├── choose_type_screen.dart    # Select calendar type
│   │   └── success_screen.dart        # Wallpaper set confirmation
│   ├── life/
│   │   ├── life_input_screen.dart     # Enter date of birth
│   │   └── life_stats_screen.dart     # Life calendar preview + stats
│   ├── year/
│   │   └── year_preview_screen.dart   # Year progress preview + stats
│   ├── goal/
│   │   ├── goal_input_screen.dart     # Enter goal details
│   │   └── goal_preview_screen.dart   # Goal progress preview + stats
│   ├── wallpaper/
│   │   ├── wallpaper_canvas.dart      # Interactive dot grid widget
│   │   └── wallpaper_preview_screen.dart  # Full preview + set wallpaper
│   └── settings/
│       └── settings_screen.dart       # App settings + debug info
├── routes/
│   └── app_router.dart                # GoRouter configuration + routes
├── services/
│   ├── storage_service.dart           # SharedPreferences wrapper
│   ├── wallpaper_update_engine.dart   # Central update logic (THE BRAIN)
│   ├── background_service.dart        # WorkManager scheduling
│   ├── alarm_service.dart             # AlarmManager exact midnight trigger
│   ├── wallpaper_auto_updater.dart    # App-launch fallback updater
│   ├── headless_wallpaper_renderer.dart  # Offscreen PNG renderer
│   ├── wallpaper_service.dart         # Apply PNG as system wallpaper
│   ├── battery_optimization_service.dart # Battery exemption requests
│   └── date_service.dart              # Date calculation helpers
└── shared/
    ├── models/
    │   ├── app_settings.dart          # Settings data class
    │   └── calendar_type.dart         # Life/Year/Goal enum
    ├── providers/
    │   └── app_settings_provider.dart # Riverpod state notifier
    └── widgets/
        ├── app_button.dart            # Reusable button widget
        ├── app_widgets.dart           # Settings toggle, color selector
        ├── dot_grid.dart              # Dot grid display widget
        └── misc_widgets.dart          # Chip widgets, settings rows

android/app/src/main/
├── AndroidManifest.xml                # Permissions + receivers
└── kotlin/com/example/dotdays/
    ├── MainActivity.kt                # Method channels (battery, device)
    └── BootReceiver.kt                # Reboot handler
```

---

## 5. User Flows

### First-Time Onboarding

```
Welcome Screen
    ↓
Choose Calendar Type (Life / Year / Goal)
    ↓
Input Screen (DOB / Goal details)
    ↓
Preview Screen (see the dot grid)
    ↓
Wallpaper Preview (full-screen preview)
    ↓ "Set as Wallpaper"
Success Screen → Home Screen
```

### Daily Usage (After Setup)

```
User unlocks phone → sees updated wallpaper (one more dot filled)
                   → opens app to see stats/details (optional)
```

### Changing Calendar Type

```
Home Screen → "Set" tab → Edit button
    ↓
Choose Type Screen
    ↓
Input Screen → Preview → Wallpaper Preview → Set
```

### Navigation (Back Button Flow)

Every screen accepts an optional `from` query parameter. This creates a navigation chain:

```
Home → Life Stats → Wallpaper Preview
       ↑ back        ↑ back (goes to Life Stats, NOT Home)
```

The `from` parameter stores the encoded URL of the previous screen, ensuring the back button always returns to the exact previous screen in the sequence.

---

## 6. Calendar Types

### Life Calendar

| Property | Value |
|----------|-------|
| **What it shows** | Every week of your entire life as a dot |
| **Grid** | 52 columns × (lifespan) rows |
| **Input needed** | Date of birth, expected lifespan |
| **Dot meaning** | Each dot = 1 week |
| **Stats shown** | X% of life lived, weeks remaining |

### Year Calendar

| Property | Value |
|----------|-------|
| **What it shows** | Every day of the current year |
| **Grid** | 15 columns × ~25 rows |
| **Input needed** | None (uses current date) |
| **Dot meaning** | Each dot = 1 day |
| **Stats shown** | X days left, X% of year done |
| **Leap year** | Automatically uses 366 dots |

### Goal Calendar

| Property | Value |
|----------|-------|
| **What it shows** | Progress toward a custom goal |
| **Grid** | 15 columns × dynamic rows |
| **Input needed** | Goal name, start date, end date |
| **Dot meaning** | Each dot = 1 day of the goal period |
| **Stats shown** | X days left, X% complete |

---

## 7. State Management

### Technology: Riverpod (StateNotifier)

```
AppSettingsProvider (StateNotifier<AppSettings>)
    │
    ├── calendarType: CalendarType (life/year/goal)
    ├── dateOfBirth: DateTime?
    ├── lifespan: int (default: 80)
    ├── goalName: String?
    ├── goalStart: DateTime?
    ├── goalEnd: DateTime?
    ├── autoUpdate: bool (default: true)
    ├── lockScreen: bool (default: true)
    ├── showDayCounter: bool (default: false)
    ├── livedDotColor: Color (default: white)
    └── onboardingComplete: bool
```

### How It Works

1. On app start, `AppSettingsNotifier` loads all values from `SharedPreferences`
2. UI watches `appSettingsProvider` via `ref.watch()` — auto-rebuilds on change
3. When user changes a setting, the notifier:
   - Saves to `SharedPreferences` (persistent)
   - Updates the in-memory state (instant UI update)

### Data Flow

```
User taps "change lifespan"
    ↓
notifier.setLifespan(85)
    ↓
StorageService.setLifespan(85)  ← saves to SharedPreferences
    ↓
state = state.copyWith(lifespan: 85)  ← triggers UI rebuild
    ↓
All widgets watching appSettingsProvider auto-rebuild
```

---

## 8. Navigation System

### Technology: GoRouter

### Route Map

| Route | Screen | Parameters |
|-------|--------|-----------|
| `/` | Welcome Screen | — |
| `/choose-type` | Choose Type | — |
| `/change-type` | Choose Type (from Home) | `?from=` |
| `/life-input` | Life Input | `?from=` |
| `/life-stats` | Life Stats | `?from=` |
| `/year-preview` | Year Preview | `?from=` |
| `/goal-input` | Goal Input | `?from=` |
| `/goal-preview` | Goal Preview | `?from=` |
| `/wallpaper-preview` | Wallpaper Preview | `?from=` |
| `/success` | Success | — |
| `/home` | Home Screen | `?tab=0/1/2` |
| `/settings` | Settings | — |

### Back Navigation Pattern

Instead of relying on `Navigator.pop()` (which is unreliable with flat route structures), DotDays uses a **URL parameter chain**:

```dart
// When navigating from Life Stats to Wallpaper Preview:
context.go('/wallpaper-preview?from=${Uri.encodeComponent('/life-stats?from=/home')}');

// When user presses Back on Wallpaper Preview:
context.go(Uri.decodeComponent(from)); // Goes to /life-stats?from=/home
```

This ensures back navigation always returns to the correct previous screen, even in deep flows.

### Initial Route Logic

```
App starts → GoRouter checks '/' route
    ↓
Is onboarding complete?
    ├── YES → redirect to /home
    └── NO  → show Welcome Screen
```

---

## 9. Wallpaper System (Core Engine)

This is the most important part of the app. It's responsible for rendering and applying the wallpaper.

### Architecture

```
┌─────────────────────────────────────────────┐
│         WallpaperUpdateEngine               │
│         (THE BRAIN)                          │
│                                              │
│  performUpdate(trigger, force)               │
│    1. Check preconditions                    │
│    2. Check if day changed                   │
│    3. Read user settings                     │
│    4. Call HeadlessWallpaperRenderer          │
│    5. Call WallpaperService.applyWallpaper    │
│    6. Save state atomically                  │
└──────────┬──────────────────┬───────────────┘
           │                  │
           ▼                  ▼
┌──────────────────┐  ┌──────────────────┐
│ HeadlessRenderer │  │ WallpaperService  │
│ (Canvas → PNG)   │  │ (PNG → Wallpaper) │
└──────────────────┘  └──────────────────┘
```

### HeadlessWallpaperRenderer

Renders the dot grid **without any UI** (no widget tree needed). This is critical because it must work in a background isolate (WorkManager) where there's no Flutter UI.

**How it works:**

1. Creates a `Canvas` + `PictureRecorder` at 1080×2340 resolution
2. Fills background (pure black `#08090B`)
3. Calculates safe area padding (top 28%, sides 13.6%) to match the on-screen preview
4. Draws the dot grid based on calendar type:
   - **Year:** 15 columns, 365/366 dots
   - **Life:** 52 columns, (lifespan × 52) dots
   - **Goal:** 15 columns, (goal duration) dots
5. Colors each dot:
   - Past/lived → white (or custom color)
   - Today → orange (#FF6B35)
   - Future → dark gray (#2A2D35)
6. Draws stats text below the grid
7. Converts to PNG bytes → saves to app documents directory

**Key detail:** The renderer uses the same proportions as `WallpaperCanvas` (the interactive widget) so the preview and the actual wallpaper look identical.

### WallpaperService

Uses `wallpaper_manager_flutter` package to set the rendered PNG as the system wallpaper:

| Location Code | What It Sets |
|--------------|-------------|
| `1` | Home screen only |
| `2` | Lock screen only |
| `3` | Both screens |

### Update Flow (Step by Step)

```
1. performUpdate(trigger: "workmanager") is called
2. Check: Is auto-update enabled? → NO → skip
3. Check: Is onboarding complete? → NO → skip
4. Check: Has date changed since last update? → NO → skip
5. Check: Has timezone changed? → If yes, force update
6. Read all user settings from SharedPreferences
7. Call HeadlessWallpaperRenderer.render(calendarType, dob, ...)
8. Renderer draws dots on canvas → saves PNG file
9. Call WallpaperService.applyWallpaper(file, location)
10. If success:
    - Save wallpaper_last_update_day = "2026-04-25"
    - Save wallpaper_last_update_ts = 1745544000000
    - Save wallpaper_last_update_success = true
    - Save wallpaper_last_update_trigger = "workmanager"
    - Save wallpaper_consecutive_failures = 0
    - Save wallpaper_last_timezone = "IST"
11. If failure:
    - Increment wallpaper_consecutive_failures
    - Save success = false
    - DO NOT update last_update_day (so next trigger retries)
```

### Why This Design?

- **Deterministic:** Output is always `f(today, settings)`. Never depends on previous state.
- **Idempotent:** Safe to call 100 times. Only renders if date actually changed.
- **Atomic:** State is saved only on success. Failure never corrupts data.
- **Observable:** Every step is logged with trigger, result, time, duration.

---

## 10. Background Update System

### The Three-Layer Defense

#### Layer 1: WorkManager (Primary)

**File:** `lib/services/background_service.dart`

```
Frequency: Every 24 hours
Initial delay: Calculated to next midnight
Policy: ExistingPeriodicWorkPolicy.update
```

- Uses Android's WorkManager API
- Runs in a separate Dart isolate (no UI)
- Survives app kill
- Re-initializes StorageService in the isolate
- Calls `WallpaperUpdateEngine.performUpdate(trigger: "workmanager")`

**Why `.update` policy?** If the user changes settings or the schedule needs realignment, `.update` ensures the new config replaces the old task. `.keep` would keep the stale config forever.

**Why 24 hours instead of 15 minutes?** The 15-minute approach wasted battery running 96 checks/day when only 1 was needed. The midnight-aligned 24-hour task runs once and hits the day boundary.

#### Layer 2: AlarmManager (Backup)

**File:** `lib/services/alarm_service.dart`

```
Type: One-shot exact alarm
Time: Next midnight + 30 seconds buffer
Self-rescheduling: After each fire, schedules next midnight
```

- Uses `android_alarm_manager_plus` package
- Exact alarms (not approximate) for precise timing
- Acts as backup when WorkManager is delayed by OEM battery optimization
- Requires `SCHEDULE_EXACT_ALARM` permission (Android 12+)
- All methods wrapped in try-catch (graceful degradation)

#### Layer 3: App Launch (Fallback)

**File:** `lib/services/wallpaper_auto_updater.dart`

```
Trigger: Every time user opens the app
Logic: Same as background — calls performUpdate("app_launch")
```

- Catches missed updates (OEM killed WorkManager + AlarmManager)
- Handles the "installed at 11:59 PM" edge case
- Idempotent — no-op if already updated today

### Startup Sequence

```
main() {
  StorageService.init()              // Load SharedPreferences
  BackgroundService.init()           // Initialize WorkManager
  AlarmService.init()                // Initialize AlarmManager
  BackgroundService.ensureScheduled()// Schedule 24hr periodic task
  AlarmService.ensureScheduled()     // Schedule midnight exact alarm
  WallpaperAutoUpdater.checkAndUpdate() // Immediate fallback check
  _requestBatteryOptimization()      // Ask for battery exemption
}
```

### Reboot Handling

When the phone reboots:

1. **BootReceiver.kt** fires (registered for `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, `QUICKBOOT_POWERON`)
2. Sets two flags in SharedPreferences:
   - `flutter.needs_reschedule = true` (for WorkManager)
   - `flutter.needs_alarm_reschedule = true` (for AlarmManager)
3. Next time user opens app → `ensureScheduled()` reads flags → cancels stale tasks → re-schedules fresh

### Structured Logging

Every update produces a log like:

```
[WallpaperUpdate] Trigger: workmanager | Result: SUCCESS | Time: 2026-04-25 00:01:30 | Wallpaper applied for 2026-04-25 (120ms)
```

Triggers: `workmanager`, `alarm`, `app_launch`, `manual`
Results: `STARTING`, `SUCCESS`, `FAILED`, `SKIPPED`

---

## 11. OEM Survival Strategy

Android OEMs (Xiaomi, Samsung, Oppo, etc.) aggressively kill background tasks. DotDays handles this with multiple strategies:

### Battery Optimization Exemption

**File:** `lib/services/battery_optimization_service.dart`

- Uses a method channel to native Android
- Calls `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`
- Shows system dialog asking user to exempt DotDays
- Requested automatically after onboarding

### OEM-Specific Instructions

**File:** `lib/features/settings/settings_screen.dart` → `_buildOemGuide()`

When battery optimization is NOT exempted, the Settings screen shows manufacturer-specific instructions:

| OEM | Instructions |
|-----|-------------|
| **Xiaomi/Redmi/POCO** | Settings → Apps → DotDays → Auto-start: Enable. Battery → App Battery Saver → No restrictions |
| **Samsung** | Settings → Battery → Background usage limits → Remove from "Sleeping apps". Apps → DotDays → Battery → Unrestricted |
| **Oppo/Realme** | Settings → App Management → DotDays → Auto-start + Background activity. Battery → High power consumption → Add DotDays |
| **Vivo** | Settings → Battery → Background Power Consumption → Don't restrict. i Manager → Autostart → Enable |
| **Huawei/Honor** | Settings → Battery → App Launch → DotDays → Manage manually → Enable all |
| **OnePlus** | Settings → Battery → Battery optimization → DotDays → Don't optimize |

### How OEM Is Detected

```
MainActivity.kt → getManufacturer() → returns Build.MANUFACTURER.lowercase()
```

Called via method channel `com.example.dotdays/device`.

---

## 12. Settings & Configuration

### User-Facing Settings

| Setting | Default | Storage Key | Description |
|---------|---------|-------------|-------------|
| Calendar Type | Life | `calendar_type` | life / year / goal |
| Date of Birth | null | `date_of_birth` | Stored as milliseconds |
| Lifespan | 80 | `lifespan` | Expected age (50–120) |
| Goal Name | null | `goal_name` | Custom goal label |
| Goal Start | null | `goal_start` | Stored as milliseconds |
| Goal End | null | `goal_end` | Stored as milliseconds |
| Auto Update | true | `auto_update` | Enable background updates |
| Lock Screen | true | `lock_screen` | Show on lock screen |
| Day Counter | false | `show_day_counter` | Show day count overlay |
| Dot Color | White | `lived_dot_color` | ARGB integer (3 options) |
| Wallpaper Location | Both (3) | `wallpaper_location` | 1=Home, 2=Lock, 3=Both |

### Internal Tracking Keys

| Key | Type | Purpose |
|-----|------|---------|
| `wallpaper_last_update_day` | String | "2026-04-25" — prevents redundant renders |
| `wallpaper_last_update_ts` | int | Unix ms timestamp of last update |
| `wallpaper_last_update_success` | bool | Did last attempt succeed? |
| `wallpaper_last_update_trigger` | String | "workmanager" / "alarm" / "app_launch" / "manual" |
| `wallpaper_consecutive_failures` | int | Failure counter (reset on success) |
| `wallpaper_last_timezone` | String | "IST" — detect timezone changes |
| `needs_reschedule` | bool | Flag for BootReceiver → WorkManager |
| `needs_alarm_reschedule` | bool | Flag for BootReceiver → AlarmManager |
| `onboarding_complete` | bool | Is setup done? |

### Settings Screen Sections

1. **Update Status** — "Updated 2h ago" / "Missed yesterday — tap refresh" / "Failed 3 times"
2. **Refresh Button** — Manual force-update with spinner + result snackbar
3. **User Settings** — Lifespan, dot color, auto-update toggle, etc.
4. **OEM Guide** — Manufacturer-specific battery instructions (if not exempted)
5. **Debug Info** — Expandable panel: last run, trigger, failures, timezone, manufacturer

---

## 13. Design System

### Color Palette

| Name | Hex | Usage |
|------|-----|-------|
| Background | `#000000` | App background |
| Surface | `#111317` | Cards, dialogs |
| Border | `#232831` | Dividers, outlines |
| Accent | `#FF6600` | Buttons, highlights, today dot |
| Text Primary | `#FFFFFF` | Main text |
| Text Secondary | `#9AA3AD` | Subtitles |
| Text Muted | `#7A8491` | Hints, labels |
| Dot Lived | `#FFFFFF` | Past dots (customizable) |
| Dot Today | `#FF6600` | Today's dot |
| Dot Future | `#1E1E1E` | Remaining dots |

### Typography

Uses Flutter's default Material font with custom weights:
- **Headers:** 22px, w700
- **Body:** 14-15px, w500
- **Labels:** 11-13px, w400-w600

### Wallpaper Rendering Sizes

| Property | Value |
|----------|-------|
| Canvas width | 1080px |
| Canvas height | 2340px |
| Top safe area | 28% of height |
| Side padding | 13.6% each side |
| Dot spacing | 20% of step size |

---

## 14. Android Native Layer

### AndroidManifest.xml Permissions

```xml
RECEIVE_BOOT_COMPLETED    — Reboot detection
WAKE_LOCK                 — Keep device awake during update
SET_WALLPAPER             — Apply wallpaper
REQUEST_IGNORE_BATTERY_OPTIMIZATIONS — Battery exemption dialog
SCHEDULE_EXACT_ALARM      — Exact midnight alarms (Android 12+)
USE_EXACT_ALARM           — Alternative exact alarm permission
```

### MainActivity.kt

Two method channels:

**Battery Channel** (`com.example.dotdays/battery`):
- `requestIgnoreBatteryOptimization` — Opens system battery exemption dialog
- `isIgnoringBatteryOptimization` — Returns bool

**Device Channel** (`com.example.dotdays/device`):
- `getManufacturer` — Returns OEM name (e.g., "xiaomi", "samsung")
- `canScheduleExactAlarms` — Check if exact alarm permission is granted (Android 12+)
- `openExactAlarmSettings` — Opens system settings for exact alarm permission

### BootReceiver.kt

- Registered for: `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, `QUICKBOOT_POWERON`
- Sets flags in `FlutterSharedPreferences`:
  - `flutter.needs_reschedule = true`
  - `flutter.needs_alarm_reschedule = true`
- On next app launch, `ensureScheduled()` reads these flags and re-schedules all tasks

---

## 15. Data Storage

### Technology: SharedPreferences

All data is stored locally on the device using Flutter's `shared_preferences` package. No server, no cloud, no internet required.

**File:** `lib/services/storage_service.dart`

### StorageService API

```dart
// User settings
StorageService.getCalendarType()    → String?
StorageService.setCalendarType(type) → Future<void>
StorageService.getDateOfBirth()     → DateTime?
StorageService.setDateOfBirth(dob)  → Future<void>
StorageService.getLifespan()        → int (default: 80)
StorageService.getAutoUpdate()      → bool (default: true)
// ... etc

// Update tracking
StorageService.getLastUpdateDay()        → String? ("2026-04-25")
StorageService.getLastUpdateTimestamp()   → int? (Unix ms)
StorageService.getLastUpdateSuccess()     → bool (default: true)
StorageService.getLastUpdateTrigger()     → String? ("workmanager")
StorageService.getConsecutiveFailures()   → int (default: 0)
StorageService.getLastTimezone()          → String? ("IST")
```

### Privacy

- **Zero network calls** — Everything works offline
- **Zero analytics** — No tracking, no telemetry
- **Zero cloud storage** — All data on device only
- **User controls everything** — Can change/delete settings anytime

---

## 16. Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | ^2.5.1 | State management |
| `go_router` | ^14.2.7 | Navigation/routing |
| `shared_preferences` | ^2.3.1 | Local key-value storage |
| `workmanager` | ^0.9.0 | Background periodic tasks |
| `android_alarm_manager_plus` | ^4.0.4 | Exact midnight alarms |
| `wallpaper_manager_flutter` | ^1.0.1 | Set system wallpaper |
| `path_provider` | ^2.1.3 | App file paths |
| `intl` | ^0.19.0 | Date/number formatting |
| `device_info_plus` | ^11.2.0 | OEM manufacturer detection |

---

## 17. Build & Release

### Debug Build

```bash
flutter run
```

### Release APK (Split by ABI)

```bash
flutter build apk --split-per-abi
```

Output:
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (~18MB)
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (~18MB)
- `build/app/outputs/flutter-apk/app-x86_64-release.apk` (~18MB)

### App Bundle (Play Store)

```bash
flutter build appbundle
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Version

Current: `2.0.0+20` (defined in `pubspec.yaml`)

---

## 18. Troubleshooting

### "Wallpaper stopped updating"

**Cause:** OEM battery optimization killed background tasks.

**Fix:**
1. Open DotDays → Settings → check the OEM guide section
2. Follow manufacturer-specific instructions to enable auto-start + disable battery restrictions
3. Tap "Refresh Wallpaper Now" to force an immediate update

### "Wallpaper looks different from preview"

**Cause:** Rendering proportions mismatch between WallpaperCanvas widget and HeadlessWallpaperRenderer.

**Fix:** Both use the same safe-area percentages (`wallpaperTopSafePercent = 0.28`, side padding = 13.6%). If they diverge, update the headless renderer to match.

### "Back button goes to wrong screen"

**Cause:** Missing `from` query parameter in navigation call.

**Fix:** When navigating to any screen, pass the current path as `?from=`:
```dart
context.go('/wallpaper-preview?from=${Uri.encodeComponent(currentPath)}');
```

### "App crashes on startup"

**Cause:** SharedPreferences not initialized before use.

**Fix:** `StorageService.init()` must be called in `main()` before any other service.

### "Debug info shows failures"

**Check:**
1. `consecutive_failures > 0` → Something is blocking wallpaper apply
2. `trigger = "alarm" but success = false` → AlarmManager might lack exact alarm permission
3. `last_timezone changed` → User traveled, force update should trigger

### Log Interpretation

```
[WallpaperUpdate] Trigger: workmanager | Result: SKIPPED | Already updated today
→ Normal — day hasn't changed, no work needed

[WallpaperUpdate] Trigger: alarm | Result: SUCCESS | Wallpaper applied for 2026-04-26 (150ms)
→ Perfect — midnight alarm fired and updated wallpaper

[WallpaperUpdate] Trigger: app_launch | Result: FAILED | WallpaperManager apply returned false (failures=2)
→ Problem — wallpaper couldn't be set. Likely OEM blocking lock screen changes.
```

---

## Appendix: Quick Reference Card

```
┌──────────────────────────────────────────────────────────┐
│                    DotDays v2.0.0                         │
│                                                           │
│  3 Calendar Types:  Life (weeks) · Year (days) · Goal    │
│  3 Update Layers:   WorkManager · AlarmManager · AppLaunch│
│  1 Central Engine:  WallpaperUpdateEngine.performUpdate() │
│                                                           │
│  State:     Riverpod (AppSettingsProvider)                 │
│  Storage:   SharedPreferences (100% offline)               │
│  Navigation: GoRouter + ?from= parameter chain            │
│  Rendering: Canvas → PNG → WallpaperManager               │
│                                                           │
│  Key Files:                                                │
│    wallpaper_update_engine.dart  — The Brain               │
│    headless_wallpaper_renderer.dart — The Renderer         │
│    background_service.dart — WorkManager scheduling        │
│    alarm_service.dart — Midnight exact alarm               │
│    storage_service.dart — All data access                  │
│    app_settings_provider.dart — UI state management        │
└──────────────────────────────────────────────────────────┘
```
