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
- **12h / 24h** toggle — switches time format across all clock panels and menu bar pin
- **Local / UTC** toggle — switches offset display between `+6h` (from local) and `+2` (UTC)
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
- Hovering a holiday day shows a label below the grid with flag, name, observed note, and type
- Multiple countries on the same day stack line by line
- Controlled by "Show Holidays" setting (default on, US only on first launch)

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
| Italy | 🇮🇹 | All 12 festività nazionali |
| Japan | 🇯🇵 | 16 national holidays; equinox dates hardcoded 2023–2030 |
| Brazil | 🇧🇷 | 12 holidays; Carnival computed (Easter−47) |
| Mexico | 🇲🇽 | 8 holidays; Constitution/Juárez/Revolution on floating Mondays |
| Netherlands | 🇳🇱 | 11 holidays; King's Day shifts Apr 26 when Apr 27 is Sunday |
| Poland | 🇵🇱 | All 13 dni wolne od pracy |
| Singapore | 🇸🇬 | 5 fixed + CNY, Vesak, Hari Raya ×2, Deepavali hardcoded 2023–2030 |
| South Korea | 🇰🇷 | 8 fixed + Seollal ×3, Buddha's Birthday, Chuseok ×3 hardcoded 2023–2030 |
| Spain | 🇪🇸 | 10 national holidays |

Lunar/Islamic dates hardcoded through 2030; all other holidays computed algorithmically for any year.

---

### Calendar Stats Panel
Fills the space below the calendar grid. Updates when a date is clicked; shows today when nothing is selected.

| Element | Detail |
|---|---|
| Moon phase | SF Symbol icon + phase name, computed locally from reference new moon |
| Season | Emoji + name + day within season (meteorological: Mar/Jun/Sep/Dec) |
| Year progress bar | Accent-color fill + percentage |
| Day stats strip | Day #, week #, days left in year, business days left in month |
| Selected date chip | Shows "Oct 15, 2026" when viewing a date other than today |

---

### World Clock

#### Local Time Panel (always first)
- Country flag + large monospaced time with seconds
- Timezone name + "(Local)" label
- Updates every second

#### Added Timezone Panels
- Country flag (skipped for generic/unknown identifiers) + time
- City label on its own line; date + offset on the line below
- Offset format: `+5:30` / `−4` (no UTC prefix) or `+9:30h` / `−6h` from local depending on toggle
- **ⓘ button** — always visible, brightens on hover; opens edit popover to rename or delete; shows IANA identifier read-only
- **Pin button** — pins zone to menu bar; filled accent when active; only one zone pinned at a time
- Drag to reorder panels
- First launch pre-populates: New York, London, Paris, Singapore, Mumbai, Tokyo, Sydney

#### Pin to Menu Bar
- Two separate `NSStatusItem` instances — icon always `squareLength` so popover arrow always aligns
- Clock item appears alongside when pinned: `🇬🇧 9:41 PM`
- Respects 12/24h setting; refreshes every 30 seconds
- Clicking either item opens the popover

#### Add Time Zone Sheet (340 × 440 pt)
- 30+ popular city suggestions shown by default
- Typing searches all ~600 IANA identifiers as fallback; split into "Suggested" / "All Time Zones"
- Each row: city label, IANA identifier, current local time
- Already-added zones highlighted with accent background

---

### Q&A Bar
All answers are computed locally — no network calls, no AI API.

Input normalizes contractions (`what's` → `what is`) before parsing.

#### Supported Query Patterns
| Category | Examples |
|---|---|
| Time in place | "time in Tokyo", "london time", "what time in SF" |
| Local time | "what time is it", "current time" |
| Today's date | "what day is today", "what is the date" |
| Day of week | "what day is next Friday", "what day is June 1 2027" |
| Relative dates | "next Monday", "last Friday", "in 3 days", "in 2 weeks" |
| Business day math | "+20 business days from today", "15 biz days from March 5" |
| Date arithmetic | "today + 45 days", "June 1 minus 3 weeks", "add 2 months to today" |
| Age | "how old is someone born June 5 1990" |
| Duration | "how long between Jan 1 and Oct 15" |
| Days until/since | "days until Christmas", "days since Labor Day" |
| Weeks until | "how many weeks until Thanksgiving" |
| Days between | "days between July 4 and Thanksgiving" |
| Days in month | "how many days in February 2028" |
| Days left | "days left in June", "days left in the year", "days left in Q3" |
| Business days in period | "business days in July", "business days in Q3 2026" |
| Business days between | "business days between March 1 and April 15" |
| Business days left | "business days left in month" |
| Month anchors | "what day does August start on", "last day of November" |
| Nth weekday | "first Monday in October 2027", "last Friday of November" |
| Quarter | "what quarter is it", "when does Q3 start", "when does Q4 end" |
| Leap year | "is 2028 a leap year" |
| Week of year | "what week of the year is today" |
| Holiday lookup | "when is Thanksgiving 2027", "when is Bastille Day 2028" |
| Holiday check | "is November 11 a holiday" |

80+ city/country timezone aliases (SF, DC, HK, NYC, etc.)

---

### Settings

| Setting | Default | Section |
|---|---|---|
| Launch at Login | off | General |
| Global Hotkey (⌥Space) | on | General |
| Show Holidays | on | Calendar |
| → Country checkboxes (16 countries) | US only | Calendar |
| → Dot color legend | — | Calendar |
| → Accuracy note | — | Calendar |
| Week Starts on Monday | off | Calendar |
| Show Week Numbers | off | Calendar |
| 24-Hour Time | off | Clock |
| Show Offset from Local Time | on | Clock |

Footer: QuickCal v1.0 · dejatechsolutions.com · © Dejatech Solutions

---

### Menu Bar Right-Click
- About QuickCal — standard panel with dejatechsolutions.com and github.com/BrianB-22/quickcal links
- Quit QuickCal

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
| `WorldClockView.swift` | Local panel, zone panels, edit popover, Add Zone sheet |
| `QueryView.swift` | Input field, answer banner |
| `SettingsView.swift` | Settings sheet — toggles, country checkboxes, dot legend, footer |
| `SettingsStore.swift` | `ObservableObject` — UserDefaults-backed settings |
| `TimeZoneStore.swift` | `ObservableObject` — zones list, pinned zone, flag lookup, first-launch defaults |
| `HolidayData.swift` | Holiday calculations for 16 countries |
| `QueryEngine.swift` | Rule-based NL parser — normalization, 20+ query types, 80+ timezone aliases |
| `HotkeyManager.swift` | Carbon hotkey wrapper |
