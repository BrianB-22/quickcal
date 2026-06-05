# QuickCal — Product Spec

## Overview
QuickCal is a macOS menu bar app that puts a calendar, world clock, and natural-language time assistant one click away. It is designed for professionals working across time zones and global teams — making it easy to know what day it is in London, whether Monday is a holiday in India, and how many business days are left in the month. No internet connection or API keys required.

## Core Requirements
- Calendar icon in the menu bar; click to open/close popover
- Optional pinned timezone displays flag + time next to the menu bar icon
- No Dock icon (`LSUIElement = YES`)
- Fully offline — all logic is local Swift

## Window / Layout
- Popover size: 620 × 560 pt
- Popover behavior: `.transient` (closes on click outside)
- Left panel (360 pt): Calendar + Stats
- Right panel (240 pt): World Clock
- Bottom bar: Q&A input + answer display
- Settings sheet: 380 × 620 pt

---

## Feature List

### Header Bar
- App icon + "QuickCal" title
- **Today** button — jumps to current month, selects today
- **12h / 24h** toggle — switches time format across all clock panels
- **Gear** icon — opens Settings sheet

---

### Calendar

#### Month Grid
- Current month on launch; ◀ ▶ navigate one month at a time
- Day-of-week header: Su Mo Tu We Th Fr Sa (or Mo … Su when Monday start is on)
- Today: accent-color background + bold
- Selected date: solid accent fill, white text
- Days outside month: dimmed

#### Week Numbers
- Optional ISO week number gutter on the left side of each row
- Toggleable in Settings

#### Week Start Day
- Configurable: Sunday (default) or Monday
- Affects column headers and grid offset

#### Holiday Indicators
- **Orange filled dot** = National / Federal holiday
- **Teal filled dot** = Regional / Observance varies
- **Hollow ring** (in either color) = Observed date — holiday shifted from a weekend (Sat → Fri, Sun → Mon)
- Hovering a holiday day shows a label below the grid:
  `🇺🇸  Christmas Day  (Observed)  ·  Federal Holiday`
  Multiple countries on the same day stack line by line
- Controlled by "Show Holidays" setting (default on)

#### Supported Countries (16 total)
| Country | Flag | Notes |
|---|---|---|
| United States | 🇺🇸 | 11 federal holidays; Columbus Day marked Observance Varies |
| India | 🇮🇳 | 3 fixed national + Holi, Diwali, Eid ×2, Dussehra hardcoded 2023–2030 |
| United Kingdom | 🇬🇧 | England & Wales bank holidays; Easter-based |
| Canada | 🇨🇦 | National + provincial (Civic Holiday marked Regional) |
| Australia | 🇦🇺 | National holidays; state holidays marked Regional |
| France | 🇫🇷 | All 11 jours fériés nationaux |
| Germany | 🇩🇪 | National holidays; state-only holidays marked Regional |
| Italy | 🇮🇹 | All 12 festività nazionali including Liberation Day and Republic Day |
| Japan | 🇯🇵 | 16 national holidays; equinox dates hardcoded 2023–2030 |
| Brazil | 🇧🇷 | 12 holidays; Carnival computed (Easter−47), Corpus Christi marked Regional |
| Mexico | 🇲🇽 | 8 holidays; Constitution/Juárez/Revolution on floating Mondays |
| Netherlands | 🇳🇱 | 11 holidays; King's Day shifts Apr 26 when Apr 27 is Sunday |
| Poland | 🇵🇱 | All 13 dni wolne od pracy |
| Singapore | 🇸🇬 | 5 fixed + CNY, Vesak, Hari Raya ×2, Deepavali hardcoded 2023–2030 |
| South Korea | 🇰🇷 | 8 fixed + Seollal ×3, Buddha's Birthday, Chuseok ×3 hardcoded 2023–2030 |
| Spain | 🇪🇸 | 10 national holidays including Epiphany and Constitution Day |

Multiple countries can be enabled simultaneously. Default enabled: US, UK, France, Poland, India, Australia — matching the default world clock zones. Lunar and Islamic holiday dates are hardcoded through 2030; all other holidays computed algorithmically for any year.

---

### Calendar Stats Panel
Fills the space below the calendar grid. Updates when a date is clicked; shows today's stats when nothing is selected.

| Element | Detail |
|---|---|
| Moon phase | SF Symbol icon + phase name, computed locally |
| Season | Emoji + name + day within season (meteorological) |
| Year progress bar | Accent-color fill + percentage |
| Day stats strip | Day #, week #, days left in year, business days left in month |
| Selected date chip | Shows "Oct 15, 2026" when viewing a date other than today |

---

### World Clock

#### Local Time Panel (always first)
- Country flag + large monospaced time with seconds: `HH:MM:SS` or `H:MM:SS AM/PM`
- Timezone name + "(Local)" label
- Updates every second

#### Added Timezone Panels
- Country flag + time: `HH:MM` or `H:MM AM/PM`
- City label + date + UTC offset (or local offset) on the label row
- **ⓘ button** (always visible, brightens on hover) → edit popover to rename or remove; shows IANA identifier read-only
- **Pin button** — pins that zone to the menu bar; filled accent when pinned
- Only one zone pinned at a time; persists across restarts
- Drag to reorder panels
- First launch pre-populates: New York, London, Paris, Warsaw, Mumbai, Sydney

#### Pin to Menu Bar
- Two separate `NSStatusItem` instances — icon always `squareLength` (popover arrow always aligned), clock item appears alongside it when pinned
- Format: `🇬🇧 9:41 PM`
- Respects 12/24h setting; refreshes every 30 seconds
- Clicking either item opens the popover

#### Add Time Zone Sheet (340 × 440 pt)
- 30+ popular city suggestions shown by default
- Typing searches all ~600 IANA timezone identifiers as fallback
- Results split into "Suggested" and "All Time Zones" sections
- Each row shows city label, IANA identifier, and current local time
- Already-added zones highlighted with accent background

---

### Q&A Bar

#### Input
- Text field: "Ask about time or dates…"
- Submit on Return or ↑ button
- Answer displayed above with a `calendar.badge.clock` icon; ✕ to dismiss

#### Supported Query Patterns
| Pattern | Example |
|---|---|
| Time in a place | "what time is it in Tokyo" |
| Current local time | "what time is it now" |
| Today's date | "what day is today" |
| Day of week | "what day of the week is June 1 2027" |
| Business day math | "+20 business days from today" |
| Business day from date | "15 business days from March 5" |
| Days until | "how many days until Christmas" |
| Days since | "how many days since New Year" |
| Days between | "how many days between July 4th and Thanksgiving" |
| Week of year | "what week of the year is today" |
| Holiday lookup | "when is Thanksgiving 2027" |
| Holiday check | "is November 11 a holiday" |

40+ city/country timezone aliases built in (india, tokyo, eastern, pacific, etc.)

---

### Settings

| Setting | Default | Section |
|---|---|---|
| Launch at Login | off | General |
| Global Hotkey (⌥Space) | on | General |
| Show Holidays | on | Calendar |
| → Country checkboxes (16 countries) | US, UK, France, Poland, India, Australia | Calendar |
| → Dot color legend | — | Calendar |
| → Accuracy note | — | Calendar |
| Week Starts on Monday | off | Calendar |
| Show Week Numbers | off | Calendar |
| 24-Hour Time | off | Clock |
| Show Offset from Local Time | off | Clock |

Footer: QuickCal v1.0 · dejatechsolutions.com · Quit QuickCal
© Dejatech Solutions

---

### Global Hotkey
- **⌥Space** — open/close from any app (toggleable in Settings)
- Carbon `RegisterEventHotKey` + `InstallEventHandler`

---

## Architecture

| File | Role |
|---|---|
| `QuickCalApp.swift` | `@main` entry, `@NSApplicationDelegateAdaptor` |
| `AppDelegate.swift` | `NSStatusItem` ×2 (icon + clock), `NSPopover`, hotkey, pinned zone timer |
| `ContentView.swift` | Root layout — header, left/right split, Q&A |
| `CalendarView.swift` | Month grid, navigation, holiday dots, hover label |
| `CalendarStatsView.swift` | Moon phase, season, year progress, day stats |
| `WorldClockView.swift` | Local panel, zone panels, Add Zone sheet |
| `QueryView.swift` | Input field, answer banner |
| `SettingsView.swift` | Settings sheet — toggles, country checkboxes, dot legend, footer |
| `SettingsStore.swift` | `ObservableObject` — UserDefaults-backed settings |
| `TimeZoneStore.swift` | `ObservableObject` — zones list, pinned zone, flag lookup, first-launch defaults |
| `HolidayData.swift` | Holiday calculations for 16 countries |
| `QueryEngine.swift` | Rule-based NL parser — no network |
| `HotkeyManager.swift` | Carbon hotkey wrapper |
