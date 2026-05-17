# Jog — Product Document

> Slow jogging app for iPhone. One tap to start, no friction, no clutter.

---

## Table of Contents

1. [Vision](#vision)
2. [Target Users](#target-users)
3. [Core Features](#core-features)
4. [Screen Overview](#screen-overview)
5. [Timer Screen](#timer-screen)
6. [Report Screen](#report-screen)
7. [Summary Screen](#summary-screen)
8. [Settings](#settings)
9. [Widget System](#widget-system)
10. [Dynamic Island & Lock Screen](#dynamic-island--lock-screen)
11. [Characters & Animation](#characters--animation)
12. [Themes](#themes)
13. [Localization](#localization)
14. [Monetization](#monetization)

---

## Vision

Slow jogging (超慢跑) is a low-intensity aerobic exercise popular in Japan and Taiwan. Most existing apps are either too complicated or too plain. Jog sits in the middle: beautifully minimal, deeply functional.

**Design references:**
- Nike Run Club — dark immersive timer, large numerals
- Run Cat — silhouette character synced to activity
- Streaks — habit tracking with satisfying widgets
- GitHub contribution graph — heatmap as motivation

**Core promise:** Open the app → tap play → run. Everything else is optional.

---

## Target Users

| Segment | Description |
|---------|-------------|
| Beginners | Need guidance on pace (BPM metronome) without complexity |
| Regulars | Want streak tracking and detailed stats to stay motivated |
| Health-conscious | Want Apple Health integration and heart rate visibility |
| Aesthetic users | Choose apps partly based on how they look on their home screen |

---

## Core Features

### Must-have (v1.0)
- Countdown timer with drum-roll time picker (plain minutes or HH:MM format)
- Stopwatch mode
- Metronome beat at configurable BPM (140–220), multiple sound options
- Character silhouette animation synced to BPM
- Heart rate display (Apple Watch or BLE monitor)
- Live metrics during run: distance, calories, steps (opt-in per metric)
- Session auto-save on stop
- Report with Day / Week / Month / Year views
- 4 widget types with heatmap
- Dynamic Island + Lock Screen Live Activity
- 14 themes, all elements adapt
- English + Traditional Chinese

### Nice-to-have (v1.x)
- Apple Music / Spotify BPM overlay
- Guided programs (e.g., 30-day beginner plan)
- Share card image generator
- Watch app

---

## Screen Overview

```
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│   Timer     │   │   Report    │   │  Settings   │
│  (Tab 1)    │   │  (Tab 2)    │   │  (Tab 3)    │
└─────────────┘   └─────────────┘   └─────────────┘
       │
       ├── Character Picker (slide-in)
       └── BPM Panel (popover)

Report
  └── Session Detail (push)

Settings
  ├── Appearance (theme + language)
  ├── Display (format, HR, ring, haptic)
  ├── Defaults (duration, goal, BPM, sound)
  ├── Widget
  ├── Notifications
  └── Data & Sync
```

---

## Timer Screen

### Layout

```
┌──────────────────────────┐
│                          │  ← status bar
│    [character animation] │  ← tap to change character
│                          │
│         14:32            │  ← large weight-200 numeral
│                          │
│  ♥ 124                   │  ← live metrics (vertical list)
│  ⊙ 2.1 km                │
│  △ 148 cal               │
│                          │
│  ♩ 180    ♪ ────── ♫    │  ← BPM tap · volume slider
│                          │
│          [ ■ ]           │  ← action button
└──────────────────────────┘
```

### Time Selection (Countdown)

The time numeral is a drum-roll picker when not running:

- Scroll up = increase time, scroll down = decrease
- **Plain minutes mode:** single drum, 1 min steps, range 1–999
  - During run: large number = minutes remaining, small text below = seconds (`: 47`)
- **HH:MM mode:** two drums separated by colon
  - Hours drum: 0–16, Minutes drum: 00–59
  - During run: same HH:MM format

Ghost numerals above and below show adjacent values for orientation. No unit label displayed — format is self-evident.

### Mode Switching

Countdown vs Stopwatch is set in **Settings → Defaults**, not toggled on the timer screen. This keeps the screen uncluttered.

### Action Button

| State | Button | Interaction |
|-------|--------|-------------|
| Idle | ▶ | Tap to start |
| Running | ■ | Long-press 2 s to stop · circular arc fills as feedback |
| Running | Screen | Double-tap to pause / resume |

Releasing the long-press before 2 s cancels — arc resets. Accidental stops prevented.

### BPM Panel

Tapping the `♩ 180` indicator reveals a small floating panel:

```
 BPM
 180
[−5] [−] [+] [+5]
```

Closes automatically when tapping elsewhere.

### Live Metrics

Displayed vertically below the time numeral. Each metric that is toggled ON in Settings appears as one line:

```
♥ 124
⊙ 2.1 km
△ 148 cal
⊞ 3,780
```

No labels needed — icons are sufficient. Configurable in **Settings → Display**.

---

## Report Screen

### Structure

```
[Day] [Week] [Month] [Year]   ← sticky period tabs

‹  2026/05/12 ~ 05/18  ›     ← date range with navigation

21                            ← hero: duration (always primary)
min
DURATION

[Dist] [Cal ] [Steps]         ← 3-col metric cards, row 1
[AvgHR][MaxHR][Cad  ]         ← row 2 (Day only; hidden for Week/Month/Year)

[bar chart]                   ← updates when a card is tapped

Daily Log
  Today   21 min   2.1 km · 148 cal · HR 124/131
  Yest.   15 min   1.8 km · 134 cal · HR 120/129
  ...
```

### Period Cards

| Period | Card row 1 | Card row 2 |
|--------|-----------|-----------|
| Day | Distance · Calories · Steps | Avg HR · Max HR · Avg Cadence |
| Week / Month / Year | Distance · Calories · Steps | — |

Heart rate and cadence are only meaningful for a single session; they are hidden at aggregate views to avoid confusion.

### Bar Chart

- Tapping any metric card switches the chart to that metric's trend
- Color ramp: 5 stops (empty → low → mid → high → today/peak), all from active theme
- Day: 24 hourly bars · Week: 7 bars labeled Mon–Sun · Month: 30/31 bars · Year: 12 monthly bars

### Log List

Each row:
- Colored dot (dim = missed goal, mid = partial, bright = achieved)
- Date
- Duration (primary, always shown)
- Secondary value matching whichever card is selected

Tap row → Session Detail (push navigation):
- Full metric breakdown
- Mini heart rate distribution bar chart (bucketed by 10 bpm)

---

## Summary Screen

Shown automatically after a run ends (long-press complete). Full-screen overlay.

```
[character — celebrating animation]

21
min
DURATION

[ Avg HR: 122 ]  [ BPM: 180 ]
[ Goal:  100% ]  [ Total: 48.4h ]

🔥 13 day streak
[ ● ● ● ● ● ● ● ]   ← this week dots

[    Done    ]

         Share
```

- Character plays at increased speed (celebratory)
- "Done" returns to idle timer
- "Share" generates a minimal share card image (theme-colored, no branding clutter)

---

## Settings

Six sub-pages, each accessed via a push transition with `‹` back button.

### Appearance
- **Theme** — 14 options (see Themes section)
- **Language** — English / 繁體中文

### Display
| Option | Values |
|--------|--------|
| Timer mode | Countdown / Stopwatch |
| Time format | Plain minutes / HH:MM |
| Heart rate display | On / Off |
| Progress ring | On / Off |
| Haptic feedback | On / Off |

### Defaults
| Option | Range / Values |
|--------|---------------|
| Default duration | 5–999 min, step 5 |
| Daily goal | 5–999 min, step 5 |
| Default BPM | 140–220, step 1 |
| Sound | 叩 / 鈴 / 鼓 / 木 |
| Volume lock | On / Off |

### Widget
- Threshold sliders (T1 / T2 / T3 — single track, 3 thumbs, enforced min gap)
- Cell info: Duration / HR / Completion %
- Day numbers: On / Off
- Show streak: On / Off
- Show total time: On / Off

> Note: Each widget instance can override these defaults via long-press → Edit Widget on the home screen.

### Notifications
- Daily reminder: On / Off
- Reminder time (visible only when On)

### Data & Sync
- Apple Health: On / Off (writes workout, calories, heart rate)
- iCloud sync: On / Off
- Export CSV
- Clear all data (destructive, confirmation required)

---

## Widget System

### Four Widget Types

| Widget | Size | Content |
|--------|------|---------|
| Streak | Small | Day count + "day streak" label |
| Total Time | Small | Cumulative hours + label |
| Year Heatmap | Medium | 18×7 GitHub-style grid + optional stats |
| Month Calendar | Large | Full month grid with day numbers and per-cell metric value |

### Heatmap Color Scale

5 stops, all from active theme. Default thresholds configurable per widget:

| Level | Condition | Default |
|-------|-----------|---------|
| 0 | No record | — |
| 1 | Any activity | 1% → T1 |
| 2 | Light | T1 → T2 (default: 10%→50%) |
| 3 | Good | T2 → T3 (default: 50%→90%) |
| 4 | Complete | ≥ T3 |

### Per-widget Configuration

Long-press widget on home screen → "Edit Widget" opens iOS native configuration sheet. Each option maps to an `@Parameter` in a `WidgetConfigurationIntent`. Changes apply instantly to that widget instance only.

---

## Dynamic Island & Lock Screen

### Dynamic Island

**Compact (default during run):**
```
╔══════════════════════════╗
║  [cat anim]      14:32  ║
╚══════════════════════════╝
```

**Expanded (long-press):**
```
╔══════════════════════════════════╗
║  Jog                [cat anim]  ║
║  14:32              180 bpm     ║
╚══════════════════════════════════╝
```

No heart rate shown in Dynamic Island — keeps it uncluttered.

### Lock Screen Live Activity

Card pinned above notifications:

```
┌────────────────────────────────┐
│ JOG                            │
│ 14:32              [cat anim]  │
│ ♩ 180                          │
└────────────────────────────────┘
```

No progress bar. Time and character only.

---

## Characters & Animation

### Style
- Silhouette — filled solid shape, no outlines
- Color: `accentMid` from active theme (adapts automatically)
- 2–4 frame loop
- Speed = `60000 ms ÷ BPM ÷ 2` per frame (exactly synced to metronome)

### Roster

| ID | Name | Unlock |
|----|------|--------|
| cat_a | Cat α | Free |
| cat_b | Cat β | Free |
| human | Human | Free |
| pushup | Push-Up | Free |
| situp | Sit-Up | 7-day streak |
| jumprope | Jump Rope | 14-day streak |
| parrot | Parrot | 30-day streak |

### Placement
- **Timer screen:** between top (absent — mode set in Settings) and time numeral. Tap to open picker.
- **Dynamic Island compact:** left side, ~22×22 pt
- **Lock Screen Live Activity:** right side of card, ~48×36 pt
- **Summary screen:** top, larger, faster playback

---

## Themes

14 themes in 4 families. Every color in the app — backgrounds, text, cards, bars, heatmap cells, buttons, widgets, Dynamic Island — derives from the active theme.

### Default
| ID | Name | Description |
|----|------|-------------|
| obsidian | Obsidian 黑曜 | Pure black `#0a0a0a`, warm white text |
| paper | Paper 白紙 | Pure white `#ffffff`, deep black text |

### Minimal
| ID | Name | Description |
|----|------|-------------|
| limestone | Limestone 石灰岩 | Warm off-white, charcoal text |
| zinc | Zinc 鋅 | GitHub dark `#0d1117`, blue accent `#58a6ff`, green heatmap |

### Nature
| ID | Name | Description |
|----|------|-------------|
| grove | Grove 林間 | Sand bg, sage green accent, amber peak |
| moss | Moss & Amber 苔蘚琥珀 | Light grey bg, olive green, burnt orange accent |
| mocha | Mocha Mousse 摩卡慕斯 | Espresso dark, warm caramel accent |
| seafloor | Seafloor 海床 | Denim blue bg, warm amber accent |

### Colour
| ID | Name | Description |
|----|------|-------------|
| skyline | Skyline 天際 | Warm white, ice blue accent |
| navy | Deep Navy 深海藍 | Midnight `#0F1C2E`, periwinkle accent |
| lavender | Lavender Fog 薰衣草霧 | Pale purple bg, deep violet accent |
| midnight | Midnight Mauve 午夜藕色 | Deep indigo bg, dusty mauve accent |
| teal | Teal & Coral 青與珊瑚 | Off-white, teal primary, coral peak color |
| blush | Blush Garden 胭脂花園 | Blush pink bg, teal accent, pink heatmap |

---

## Localization

| Item | Detail |
|------|--------|
| Default | English |
| Supported | English · Traditional Chinese (繁體中文) |
| Switch | Settings → Appearance → Language |
| Scope | All UI labels, tab names, metric names, widget strings |
| Style | Full translation — "Duration" not abbreviated |
| Numbers / Dates | Device locale regardless of language setting |

---

## Monetization

v1.0 launches as a **free app** with all core features available.

Future options (not in v1.0 scope):
- One-time unlock for additional character packs
- Optional Pro tier for advanced analytics or programs
- No subscription for core functionality — philosophy is that tracking your runs should never be paywalled
