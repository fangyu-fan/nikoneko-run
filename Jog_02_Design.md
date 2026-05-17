# Jog — Design Specification

> Visual language, component patterns, interaction rules, and theme system.

---

## Table of Contents

1. [Design Language](#design-language)
2. [Typography](#typography)
3. [Spacing & Layout](#spacing--layout)
4. [Color System](#color-system)
5. [Theme Definitions](#theme-definitions)
6. [Components](#components)
7. [Screen Specs](#screen-specs)
8. [Animation](#animation)
9. [Icons](#icons)
10. [Widget Design](#widget-design)
11. [Dynamic Island & Lock Screen](#dynamic-island--lock-screen)

---

## Design Language

### Principles

**Minimal surface, maximum breathing room.**
Every element earns its place. If something can be removed without losing function, remove it.

**Text over buttons where possible.**
Labels communicate more than icons alone. Use icons only where space makes text impractical.

**No decorative color.**
Color encodes meaning (completion, urgency, theme identity) — never decoration.

**Dark by default, light by choice.**
The timer screen is designed for use in motion. Dark backgrounds reduce eye strain and make large numerals pop.

**Everything adapts to theme.**
Zero hardcoded colors in components. All colors reference theme tokens.

---

## Typography

| Role | Weight | Size (pt) | Usage |
|------|--------|-----------|-------|
| Timer numeral | 200 (ultralight) | 68–72 | Main countdown/stopwatch display |
| Hero numeral | 200 | 46 | Report screen primary metric |
| Large numeral | 200 | 28–36 | Lock Screen time, Summary |
| Section title | 500 | 14 | Tab labels, nav titles |
| Body | 400 | 12–13 | Card values, list items |
| Caption | 400 | 9–10 | Labels, units, date strings |
| Micro | 400 | 7–8.5 | Widget cell values, chart axis |

**Rules:**
- System font (SF Pro) throughout — no custom fonts
- Numeric displays use tabular figures (`font-variant-numeric: tabular-nums`)
- Letter spacing: +0.04em on uppercase labels, -0.03em on large numerals
- No bold below 11 pt

---

## Spacing & Layout

### Base Grid

- Base unit: **4 pt**
- Content padding: **16 pt** horizontal
- Card internal padding: **10–12 pt** vertical, **11–14 pt** horizontal
- Card gap: **4–6 pt**
- Section gap: **16–20 pt**

### Safe Areas

All content respects iOS safe areas. Timer numeral is vertically centered in the available space between character strip and metrics row.

### Border Radius

| Element | Radius |
|---------|--------|
| Phone frame | 44 pt |
| Screen inner | 28–32 pt |
| Cards | 8–10 pt |
| Chips / pills | 20 pt (fully rounded) |
| Buttons (circular) | 50% |
| Bar chart bars | 2 pt top corners only |
| Widget cells | 2–4 pt |

---

## Color System

### Token Structure

Each theme defines these tokens:

```
bg          Background (deepest layer)
surface     Card surfaces, secondary backgrounds
card        Tertiary surfaces, inner cards

text        Primary text
textDim     Muted text, labels, units
textMid     Accent text, metric values

accent      Primary accent (buttons, streak number, active states)
accentMid   Character color, secondary accent
accentDim   Subtle tint backgrounds, borders

bar[0..4]   5-stop ramp for bar charts and heatmap cells
            bar[0] = empty/no data
            bar[1] = low activity
            bar[2] = moderate
            bar[3] = high
            bar[4] = peak / today / 100%
```

### Usage Rules

- **Never hardcode a hex value in a component.** Always reference a token.
- `accent` is used sparingly — primary CTA button, streak count, selected card indicator dot.
- `accentMid` is the character silhouette fill.
- `bar[4]` is used for "today" in charts and "100% complete" in widgets.
- `textDim` for all secondary information — units, dates, sub-labels.

---

## Theme Definitions

### Token table

| ID | bg | surface | card | text | textDim | textMid | accent | accentMid | accentDim |
|----|----|---------|------|------|---------|---------|--------|-----------|-----------|
| obsidian | #0a0a0a | #141414 | #111111 | #f0ede8 | #2e2e2e | #666666 | #f0ede8 | #888888 | #1e1e1e |
| paper | #ffffff | #f5f5f5 | #ebebeb | #111111 | #aaaaaa | #555555 | #111111 | #555555 | #dddddd |
| limestone | #f4f0ea | #ece8e0 | #e4dfd6 | #1c1a16 | #b8b0a0 | #888070 | #3c3830 | #908070 | #d0c8b8 |
| zinc | #0d1117 | #161b22 | #21262d | #e6edf3 | #30363d | #8b949e | #58a6ff | #79c0ff | #0d2a4a |
| grove | #F5ECD7 | #ebe2cd | #ddd4bc | #353535 | #5f5f5f | #68a67d | #8FBF9F | #24613b | #c8ddd0 |
| moss | #DDDDDD | #EEEEEE | #e4e4e4 | #292524 | #78716c | #658864 | #658864 | #4a6848 | #B7B78A |
| mocha | #1a1210 | #241a14 | #1e1510 | #e8d5c0 | #4a3020 | #b08060 | #c8956a | #a07048 | #301e10 |
| seafloor | #567189 | #7B8FA1 | #6a8098 | #F9F9F9 | #DCDCDC | #CFB997 | #f7bf7a | #e8a050 | #3E5975 |
| skyline | #fffefb | #f5f4f1 | #e8e6e2 | #1d1c1c | #313d44 | #3b3c3d | #71c4ef | #00668c | #d4eaf7 |
| navy | #0F1C2E | #1f2b3e | #2a3650 | #FFFFFF | #e0e0e0 | #4d648d | #acc2ef | #3D5A80 | #1F3A5F |
| lavender | #F5F3F7 | #E9E4ED | #ddd6e4 | #4A4A4A | #878787 | #9A73B5 | #8B5FBF | #61398F | #D6C6E1 |
| midnight | #151931 | #252841 | #2e3150 | #E7D1BB | #847a86 | #A096A5 | #A096A5 | #c8b4c0 | #463e4b |
| teal | #F2EFE9 | #e8e5df | #dddad4 | #333333 | #5c5c5c | #008b7a | #00A896 | #006b60 | #a0d8d0 |
| blush | #FCEEF5 | #ffffff | #FAD9E6 | #292524 | #78716c | #61C0BF | #61C0BF | #3a9898 | #BBDED6 |

### Bar / Heatmap Ramps

| ID | bar[0] | bar[1] | bar[2] | bar[3] | bar[4] |
|----|--------|--------|--------|--------|--------|
| obsidian | #1a1a1a | #2e2e2e | #4a4a4a | #888888 | #f0ede8 |
| paper | #e8e8e8 | #cccccc | #aaaaaa | #555555 | #111111 |
| limestone | #e4dfd6 | #ccc4b4 | #a89880 | #806850 | #3c3830 |
| zinc | #161b22 | #0a2a1a | #006d32 | #26a641 | #39d353 |
| grove | #c8ddd0 | #98c8a8 | #68a67d | #24613b | #F18F01 |
| moss | #B7B78A | #9aaa70 | #658864 | #4a6848 | #bc6c25 |
| mocha | #241a14 | #4a2c18 | #7a4828 | #b07040 | #c8956a |
| seafloor | #3E5975 | #5a7898 | #7B8FA1 | #f7bf7a | #CFB997 |
| skyline | #d4eaf7 | #b6ccd8 | #71c4ef | #00668c | #1d1c1c |
| navy | #1F3A5F | #2e5080 | #4d648d | #acc2ef | #cee8ff |
| lavender | #D6C6E1 | #c4a8d8 | #9A73B5 | #8B5FBF | #61398F |
| midnight | #2e3150 | #463e4b | #706070 | #A096A2 | #E7D1BB |
| teal | #a0d8d0 | #50c0b0 | #00A896 | #006b60 | #FF6B6B |
| blush | #FAD9E6 | #FFB6B9 | #e89090 | #61C0BF | #3a9898 |

---

## Components

### Timer Numeral

```
Font:    SF Pro Display, weight 200
Size:    68–72 pt (adapts to digit count)
Color:   text
Align:   center
Spacing: letter-spacing -3 pt
```

In plain-minutes mode during a run, a secondary seconds label sits below:
```
Font:    SF Pro, weight 300
Size:    13 pt
Color:   textDim
Format:  ": 47"  (colon + seconds, no padding)
```

### Drum-roll Picker

Three visible slots. Center slot = selected value (full opacity `text`). Adjacent slots = 48 pt, dimmed (`textDim` at ~15% opacity). Drag interaction: 1 step per ~28 pt of movement.

```
Ghost above:   48 pt, opacity 0.15  →  0.28 on active drag
Selected:      68–72 pt, opacity 1.0
Ghost below:   48 pt, opacity 0.15  →  0.28 on active drag
```

No unit label visible during selection.

### Metric Row Item

```
Icon:   10–11 pt, color: textDim
Value:  13 pt, weight 300, color: textMid
Gap:    5 pt
```

### Metric Card (Report)

```
Background:  card
Border:      0.5 pt, accentDim (or border token)
Radius:      8–9 pt
Padding:     7–10 pt
Icon:        10 pt, textDim
Value:       13–16 pt, weight 200, textMid (active: accent, brighter)
Unit:        7–8 pt, textDim, appended inline
Label:       6.5–7 pt, textDim, below value
Active:      border-color: accentMid · value-color: accent
```

### Bar Chart Bar

```
Width:    flex 1 (equal width, 2–3 pt gap)
Radius:   2 pt top-left, 2 pt top-right only
Color:    bar[n] based on value percentile
Min-H:    2–4 pt (so zero-value bars are still visible as a thin line)
Axis labels: 6 pt, textDim, below chart
```

### Action Button (Circular)

```
Size:     62–68 pt diameter
Border:   1 pt, accentDim
Bg:       bg (transparent inner)
Icon:     ▶ at 20–22 pt (idle) · ■ at 14–16 pt (running)
Color:    text (idle) · textMid (running)
```

Long-press stop — progress arc:
```
Position: inset -3 pt from button edge
Stroke:   1.2–1.5 pt
Color:    accentMid
Duration: 2 000 ms from 0 → full circumference
```

### Toggle

```
Width:    38–44 pt
Height:   22–26 pt
Radius:   50%
Off bg:   surface or accentDim
On bg:    accent (dimmed variant) or theme green
Thumb:    white circle, 18–22 pt, 2 pt inset
```

### Log Row

```
Left dot:  5×5 pt, radius 1.5 pt
           dim    = no goal
           bar[2] = partial
           bar[4] = achieved
Date:      10 pt, textMid, min-width 32 pt
Main val:  11 pt, text
Sub val:   9 pt, textDim
Chevron:   10 pt, textDim
Divider:   0.5 pt, accentDim
```

### Streak Chip (Summary screen)

```
Bg:        surface (slightly tinted with accentDim)
Number:    28 pt, weight 200, accent
Label:     9 pt, textDim
Week dots: 8×8 pt squares, radius 2 pt
           done: bar[3]  ·  today: bar[4]  ·  future: bar[0]
```

---

## Screen Specs

### Timer Screen

```
Top padding:      22 pt (below safe area)
Character strip:  36 pt height, center-aligned
Gap after strip:  8 pt (implicit via justify spacing)
Time numeral:     center
Gap after time:   8–10 pt
Metrics block:    left-aligned with 16 pt leading indent
Bottom block:     BPM row + volume row + button, 12–14 pt gap
Bottom padding:   24 pt (above home indicator)
```

### Report Screen

```
Period tabs:      9–10 pt text, 9 pt top/bottom padding, full-width
Date row:         9 pt vertical padding, 14 pt horizontal
Hero block:       2 pt top, 8 pt bottom, 14 pt horizontal
Card grid:        12 pt horizontal, 4 pt gap, 6 pt bottom
Chart:            2 pt top, 8 pt bottom, 12 pt horizontal, 68 pt height
Log list:         12 pt horizontal, 7 pt row vertical padding
```

### Settings Sub-page

```
Nav bar:          14 pt top, 8 pt bottom, 16 pt horizontal
Card group:       14 pt horizontal margin
Row height:       min 46 pt
Row padding:      12 pt vertical, 14 pt horizontal
Row divider:      0.5 pt, surface
Section label:    10 pt uppercase, 10–12 pt top, 5 pt bottom, textDim
```

---

## Animation

### Character Silhouette

- Library: **Lottie** (JSON animation files)
- Frame count: 2–4 frames per character
- Speed: `playbackSpeed = BPM / 180.0` (normalized to 180 BPM baseline)
- Color: overridden at runtime via `LottieValueProvider` to `accentMid`
- Placement: centered in 36 pt tall container on timer screen

### Long-press Arc

- SwiftUI `Circle` with `strokeBorder` + `trim(from:to:)`
- `to` value animated with `withAnimation(.linear(duration: 2.0))`
- Released early: `withAnimation(.easeOut(duration: 0.2))` back to 0

### Mode Transition (Settings sub-pages)

- Standard iOS push: 0.35 s ease-in-out
- Sheet presentation for character picker on timer screen
- No custom transitions — stay native for accessibility

### Report Bars

- On period/metric change: `withAnimation(.easeInOut(duration: 0.25))`
- Height animated from 0 on first appear

### Theme Change

- Immediate — no cross-fade. SwiftUI's `@Environment` propagation is fast enough.

---

## Icons

All icons use **SF Symbols** (outline style, no fill variants) unless listed as text/emoji substitute.

| Element | SF Symbol | Notes |
|---------|-----------|-------|
| Timer tab | `figure.run` | |
| Report tab | `chart.bar` | |
| Settings tab | `gearshape` | |
| Heart rate | `heart` | or text ♥ in tight spaces |
| Distance | `location` | or text ⊙ |
| Calories | `flame` | or text △ |
| Steps | `figure.walk` | or text ⊞ |
| BPM / cadence | `metronome` | or text ♩ |
| Volume low | `speaker.wave.1` | or text ♪ |
| Volume high | `speaker.wave.3` | or text ♫ |
| Back | `chevron.left` | |
| Chevron row | `chevron.right` | |
| Lock / unlock | `lock` / `lock.open` | character unlock state |

In widget extensions and Live Activity, SF Symbols are available natively.

---

## Widget Design

### Small Widgets (Streak / Total Time)

```
Bg:         bg token
Padding:    12–14 pt all sides
Label:      8 pt, uppercase, textDim, top
Number:     32 pt, weight 200, accent
Sub-label:  9 pt, textDim, below number
```

### Medium Widget (Year Heatmap)

```
Bg:         bg
Padding:    12 pt
Label row:  8 pt, textDim, between label and legend
Grid:       18 columns × 7 rows
Cell:       aspect-ratio 1:1, radius 1.5 pt, 2 pt gap
Stats row:  optional 3 chips below grid
  Chip bg:  surface
  Value:    13 pt, weight 200, text
  Label:    6 pt, textDim
```

### Large Widget (Month Calendar)

```
Bg:         bg
Padding:    10–12 pt
Month label:  11 pt, weight 500, text
Streak label: 9 pt, textDim (right-aligned)
Day headers:  7 pt, textDim, 7 columns
Grid:       7 columns × 5–6 rows
  Cell bg:  bar[n] based on completion
  Day num:  6–7 pt, text, opacity 0.4–0.8 (0.4 if no record)
  Metric:   6 pt, text, opacity 0.7 (duration in min, HR, or %)
  Today:    1 pt ring in text color
```

### Cell Info Display

One value per cell, no unit label:
- **Duration** → minutes as integer (`21`)
- **HR** → avg BPM as integer (`124`)
- **Completion %** → integer percentage (`100`)

No unit needed — context from widget label is sufficient.

---

## Dynamic Island & Lock Screen

### Dynamic Island Compact

```
Total width:  ~120 pt (device-dependent)
Height:       34 pt
Left zone:    character animation, ~22×22 pt
Right zone:   time numeral, 14 pt weight 300, text color
Gap:          auto flex
Bg:           always #000000 (DI hardware)
```

### Dynamic Island Expanded

```
Width:        ~210 pt
Height:       68 pt
Left:         app label (8 pt, uppercase, textDim) + time (26 pt, weight 200)
Right:        character animation (~44×32 pt) + BPM (9 pt, textDim)
Padding:      0 14 pt horizontal
```

No heart rate displayed in either DI state.

### Lock Screen Live Activity

```
Card bg:          rgba(bg, 0.88) with backdrop blur
Border:           0.5 pt, accentDim
Radius:           18 pt
Padding:          14 pt vertical, 16 pt horizontal
App label:        8 pt, uppercase, textDim
Time numeral:     36 pt, weight 200, text
BPM label:        10 pt, textDim (♩ 180)
Character:        right-aligned, ~52×40 pt
No progress bar.
```
