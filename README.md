# QuickCal

A macOS menu bar app for professionals working with global teams. One click gives you a full calendar, a world clock for every timezone your colleagues are in, and a natural-language assistant that answers time and date questions instantly — all without leaving what you're doing.

Built with SwiftUI. No internet connection required. No subscriptions.

---

## Why QuickCal

When your team spans multiple continents, a simple clock isn't enough. You need to know it's already Friday in Singapore while it's still Thursday in New York. You need to know that next Monday is a bank holiday in the UK before scheduling that all-hands. You need to know how many business days are left in the quarter. QuickCal puts all of that in your menu bar.

---

## Features

### Calendar
- Full month calendar with prev/next navigation
- **Today** shortcut button in the header jumps back to the current month and selects today
- Click any date to see its stats in the panel below
- Optional **ISO week numbers** in the left gutter
- Configurable **week start** — Sunday or Monday

### International Holidays
Holidays from 16 countries displayed as colored dots directly on the calendar grid. Enable any combination in Settings — perfect if you work with teams across multiple regions.

| | | | |
|---|---|---|---|
| 🇺🇸 United States | 🇫🇷 France | 🇯🇵 Japan | 🇰🇷 South Korea |
| 🇬🇧 United Kingdom | 🇩🇪 Germany | 🇧🇷 Brazil | 🇸🇬 Singapore |
| 🇨🇦 Canada | 🇮🇹 Italy | 🇲🇽 Mexico | 🇵🇱 Poland |
| 🇦🇺 Australia | 🇪🇸 Spain | 🇳🇱 Netherlands | 🇮🇳 India |

**Dot colors:**
- **Orange** — National / Federal holiday (universally observed)
- **Teal** — Regional or observance varies
- **Hollow ring** — Observed date (holiday shifted from a weekend to the nearest weekday)

Hover any holiday dot to see the name, country, and type. A dot legend is shown in Settings.

### Calendar Stats Panel
Always-visible panel below the calendar grid:
- **Moon phase** — current phase with SF Symbol icon and name, computed locally
- **Season** — current meteorological season with day count within it
- **Year progress** — accent-color progress bar with percentage
- **Day stats** — day of year, week number, days left in year, business days left in the month

Clicking any date on the calendar updates all stats to reflect that date. A "selected date" chip appears when viewing a date other than today.

### World Clock
Built for teams spread across time zones:
- **Local time** always shown at the top with live seconds and country flag
- Country flag shown next to each timezone's time for instant recognition
- First launch pre-populates with New York, London, Paris, Warsaw, Mumbai, Sydney
- Add any timezone — 30 popular city suggestions shown by default; search falls through to all 600+ IANA timezone identifiers
- Each panel shows time, city label, local date, and UTC offset (or offset from your local time — configurable in Settings)
- **Drag to reorder** panels to match your workflow
- **Rename** any zone via the ⓘ button — call it "Office" or "Client" instead of "London"; IANA identifier shown read-only for reference
- **Pin** any timezone to the menu bar — shows `🇬🇧 9:41 PM` next to the app icon at a glance, without opening the popover; persists across restarts
- **Show offset from local time** — toggle between `UTC+2` and `+6h` display

### Natural Language Q&A
Type a plain-English question in the bar at the bottom. Everything is answered locally — no AI API, no network call.

**Time & timezones:**
- `what time in Tokyo` / `london time` / `time in SF`
- `what's the time in Mumbai`

**Day & date:**
- `what day is next Friday`
- `what day of the week is June 1 2027`
- `what day does August start on`
- `last Friday of November`
- `first Monday in October 2027`

**Countdowns & elapsed:**
- `how many days until Christmas`
- `days until Thanksgiving`
- `how many weeks until New Year`
- `how many days since Labor Day`

**Business days:**
- `+20 business days from today`
- `15 business days from March 5`
- `business days between March 1 and April 15`
- `how many business days in July`
- `business days left in month`

**Date math:**
- `90 days from today`
- `today + 45 days`
- `June 1 minus 3 weeks`
- `add 2 months to March 15`
- `how long between Jan 1 and Oct 15`

**Days in periods:**
- `how many days in February 2028`
- `days left in the year`
- `days left in Q3`
- `days left in June`

**Quarter & year:**
- `what quarter is it`
- `when does Q4 start`
- `when does Q2 end`
- `is 2028 a leap year`

**Holidays:**
- `when is Thanksgiving 2027`
- `when is Bastille Day 2028`
- `is November 11 a holiday`

**Age:**
- `how old is someone born June 5 1990`

### Settings
- **Show Holidays** — checkboxes for all 16 countries with a dot-color legend and accuracy note
- **Week Starts on Monday** — for ISO-standard calendar layout
- **Show Week Numbers** — ISO week number gutter
- **24-Hour Time** — applies to all clock panels and the menu bar pin
- **Show Offset from Local Time** — show ±Nh instead of UTC±N on clock panels
- **Global Hotkey (⌥Space)** — open QuickCal from any app
- **Launch at Login**
- **Quit QuickCal** — in the Settings footer alongside the version and website

---

## Holiday Accuracy

Fixed-date holidays (Christmas, Independence Day, etc.) and Easter-based holidays (Good Friday, Whit Monday, etc.) are computed algorithmically and are accurate for any year. Floating weekday holidays (3rd Monday in January, etc.) are also fully computed.

Lunar and Islamic holidays for India, Singapore, South Korea, and Japan are hardcoded through 2030. Outside that range those specific dates will not appear, but all other holidays continue to work. A routine update extending the tables is planned before 2031.

Regional, state-level, and proclaimed holidays (e.g. individual US state holidays, Italian patron saint days, Japanese substitute holidays) are not included. Dates are best-effort and should be verified for business-critical planning.

---

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon or Intel Mac

---

## Building

1. Open `QuickCal.xcodeproj` in Xcode
2. Select the **QuickCal** scheme
3. Build and run (⌘R)

No external dependencies. No Swift packages to resolve.

---

## About

Made by [Dejatech Solutions](https://dejatechsolutions.com)

QuickCal v1.0
